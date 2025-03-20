//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2019 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import SwiftSyntax

/// Specifying an access level for an extension declaration is forbidden.
///
/// Lint: Specifying an access level for an extension declaration yields a lint error.
///
/// Format: The access level is removed from the extension declaration and is added to each
///         declaration in the extension; declarations with redundant access levels (e.g.
///         `internal`, as that is the default access level) have the explicit access level removed.
@_spi(Rules)
public final class NoAccessLevelOnExtensionDeclaration: SyntaxFormatRule {
  private enum State {
    /// The rule is currently visiting top-level declarations.
    case topLevel

    /// The rule is currently inside an extension that has the given access level keyword.
    case insideExtension(accessKeyword: Keyword)
  }

  /// Tracks the state of the rule to determine which action should be taken on visited
  /// declarations.
  private var state: State = .topLevel

  /// Findings propagated up to the extension visitor from any members that were rewritten.
  private var notesFromRewrittenMembers: [Finding.Note] = []

  public override func visit(_ node: ExtensionDeclSyntax) -> DeclSyntax {
    guard
      // Skip nested extensions; these are semantic errors but they still parse successfully.
      case .topLevel = state,
      // Skip extensions that don't have an access level modifier.
      let accessKeyword = node.modifiers.accessLevelModifier,
      case .keyword(let keyword) = accessKeyword.name.tokenKind
    else {
      return DeclSyntax(node)
    }

    self.notesFromRewrittenMembers = []

    let keywordToAdd: Keyword?
    let message: Finding.Message

    switch keyword {
    case .public, .private, .fileprivate, .package:
      // These access level modifiers need to be moved to members. Additionally, `private` is a
      // special case, because the *effective* access level for a top-level private extension is
      // `fileprivate`, so we need to preserve that when we apply it to the members.
      if keyword == .private {
        keywordToAdd = .fileprivate
        message = .moveAccessKeywordAndMakeFileprivate(keyword: accessKeyword.name.text)
      } else {
        keywordToAdd = keyword
        message = .moveAccessKeyword(keyword: accessKeyword.name.text)
      }

    case .internal:
      // If the access level keyword was `internal`, then it's redundant and we can just remove it.
      // We don't need to modify the members at all in this case.
      message = .removeRedundantAccessKeyword
      keywordToAdd = nil

    default:
      // For anything else, just return the extension and its members unchanged.
      return DeclSyntax(node)
    }

    // We don't have to worry about maintaining a stack here; even though extensions can nest from
    // a valid parse point of view, we ignore nested extensions because they're obviously wrong
    // semantically (and would be an error later during compilation).
    var result: ExtensionDeclSyntax
    if let keywordToAdd {
      // Visit the children in the new state to add the keyword to the extension members.
      self.state = .insideExtension(accessKeyword: keywordToAdd)
      defer { self.state = .topLevel }

      result = super.visit(node).as(ExtensionDeclSyntax.self)!
    } else {
      // We don't need to visit the children in this case, and we don't need to update the state.
      result = node
    }

    // Finally, emit the finding (which includes notes from any rewritten members) and remove the
    // access level keyword from the extension itself.
    diagnose(message, on: accessKeyword, notes: self.notesFromRewrittenMembers)
    result.modifiers.remove(anyOf: [keyword])
    result.extensionKeyword.leadingTrivia = accessKeyword.leadingTrivia
    return DeclSyntax(result)
  }

  public override func visit(_ node: ActorDeclSyntax) -> DeclSyntax {
    return applyingAccessModifierIfNone(to: node)
  }

  public override func visit(_ node: ClassDeclSyntax) -> DeclSyntax {
    return applyingAccessModifierIfNone(to: node)
  }

  public override func visit(_ node: EnumDeclSyntax) -> DeclSyntax {
    return applyingAccessModifierIfNone(to: node)
  }

  public override func visit(_ node: FunctionDeclSyntax) -> DeclSyntax {
    return applyingAccessModifierIfNone(to: node)
  }

  public override func visit(_ node: InitializerDeclSyntax) -> DeclSyntax {
    return applyingAccessModifierIfNone(to: node)
  }

  public override func visit(_ node: StructDeclSyntax) -> DeclSyntax {
    return applyingAccessModifierIfNone(to: node)
  }

  public override func visit(_ node: SubscriptDeclSyntax) -> DeclSyntax {
    return applyingAccessModifierIfNone(to: node)
  }

  public override func visit(_ node: TypeAliasDeclSyntax) -> DeclSyntax {
    return applyingAccessModifierIfNone(to: node)
  }

  public override func visit(_ node: VariableDeclSyntax) -> DeclSyntax {
    return applyingAccessModifierIfNone(to: node)
  }

  /// Adds `modifier` to `decl` if it doesn't already have an explicit access level modifier and
  /// returns the new declaration.
  ///
  /// If `decl` already has an access level modifier, it is returned unchanged.
  private func applyingAccessModifierIfNone(to decl: some DeclSyntaxProtocol) -> DeclSyntax {
    // Only go further if we are applying an access level keyword and if the decl is one that
    // allows modifiers but doesn't already have an access level modifier.
    guard
      case .insideExtension(let accessKeyword) = state,
      let modifiers = decl.asProtocol(WithModifiersSyntax.self)?.modifiers,
      modifiers.accessLevelModifier == nil
    else {
      return DeclSyntax(decl)
    }

    // Create a note associated with each declaration that needs to have an access level modifier
    // added to it.
    self.notesFromRewrittenMembers.append(
      Finding.Note(
        message: .addModifierToExtensionMember(keyword: TokenSyntax.keyword(accessKeyword).text),
        location:
          Finding.Location(decl.startLocation(converter: context.sourceLocationConverter))
      )
    )

    switch Syntax(decl).as(SyntaxEnum.self) {
    case .actorDecl(let actorDecl):
      return applyingAccessModifierIfNone(accessKeyword, to: actorDecl, declKeywordKeyPath: \.actorKeyword)
    case .classDecl(let classDecl):
      return applyingAccessModifierIfNone(accessKeyword, to: classDecl, declKeywordKeyPath: \.classKeyword)
    case .enumDecl(let enumDecl):
      return applyingAccessModifierIfNone(accessKeyword, to: enumDecl, declKeywordKeyPath: \.enumKeyword)
    case .initializerDecl(let initDecl):
      return applyingAccessModifierIfNone(accessKeyword, to: initDecl, declKeywordKeyPath: \.initKeyword)
    case .functionDecl(let funcDecl):
      return applyingAccessModifierIfNone(accessKeyword, to: funcDecl, declKeywordKeyPath: \.funcKeyword)
    case .structDecl(let structDecl):
      return applyingAccessModifierIfNone(accessKeyword, to: structDecl, declKeywordKeyPath: \.structKeyword)
    case .subscriptDecl(let subscriptDecl):
      return applyingAccessModifierIfNone(accessKeyword, to: subscriptDecl, declKeywordKeyPath: \.subscriptKeyword)
    case .typeAliasDecl(let typeAliasDecl):
      return applyingAccessModifierIfNone(accessKeyword, to: typeAliasDecl, declKeywordKeyPath: \.typealiasKeyword)
    case .variableDecl(let varDecl):
      return applyingAccessModifierIfNone(accessKeyword, to: varDecl, declKeywordKeyPath: \.bindingSpecifier)
    default:
      return DeclSyntax(decl)
    }
  }

  private func applyingAccessModifierIfNone<Decl: DeclSyntaxProtocol & WithModifiersSyntax>(
    _ modifier: Keyword,
    to decl: Decl,
    declKeywordKeyPath: WritableKeyPath<Decl, TokenSyntax>
  ) -> DeclSyntax {
    // If there's already an access modifier among the modifier list, bail out.
    guard decl.modifiers.accessLevelModifier == nil else { return DeclSyntax(decl) }

    var result = decl
    var modifier = DeclModifierSyntax(name: .keyword(modifier))
    modifier.trailingTrivia = [.spaces(1)]

    guard var firstModifier = decl.modifiers.first else {
      // If there are no modifiers at all, add the one being requested, moving the leading trivia
      // from the decl keyword to that modifier (to preserve leading comments, newlines, etc.).
      modifier.leadingTrivia = decl[keyPath: declKeywordKeyPath].leadingTrivia
      result[keyPath: declKeywordKeyPath].leadingTrivia = []
      result.modifiers = .init([modifier])
      return DeclSyntax(result)
    }

    // Otherwise, insert the modifier at the front of the modifier list, moving the (original) first
    // modifier's leading trivia to the new one (to preserve leading comments, newlines, etc.).
    modifier.leadingTrivia = firstModifier.leadingTrivia
    firstModifier.leadingTrivia = []
    result.modifiers[result.modifiers.startIndex] = firstModifier
    result.modifiers.insert(modifier, at: result.modifiers.startIndex)
    return DeclSyntax(result)
  }
}

extension Finding.Message {
  fileprivate static let removeRedundantAccessKeyword: Finding.Message =
    "remove this redundant 'internal' access modifier from this extension"

  fileprivate static func moveAccessKeyword(keyword: String) -> Finding.Message {
    "move this '\(keyword)' access modifier to precede each member inside this extension"
  }

  fileprivate static func moveAccessKeywordAndMakeFileprivate(keyword: String) -> Finding.Message {
    "remove this '\(keyword)' access modifier and declare each member inside this extension as 'fileprivate'"
  }

  fileprivate static func addModifierToExtensionMember(keyword: String) -> Finding.Message {
    "add '\(keyword)' access modifier to this declaration"
  }
}
