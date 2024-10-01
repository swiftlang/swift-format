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
  public override func visit(_ node: ExtensionDeclSyntax) -> DeclSyntax {
    guard
      let accessKeyword = node.modifiers.accessLevelModifier,
      case .keyword(let keyword) = accessKeyword.name.tokenKind
    else {
      return DeclSyntax(node)
    }

    var result = node

    switch keyword {
    // Public, private, fileprivate, or package keywords need to be moved to members
    case .public, .private, .fileprivate, .package:
      // The effective access level of the members of a `private` extension is `fileprivate`, so
      // we have to update the keyword to ensure that the result is correct.
      var accessKeywordToAdd = accessKeyword
      let message: Finding.Message
      if keyword == .private {
        accessKeywordToAdd.name.tokenKind = .keyword(.fileprivate)
        message = .moveAccessKeywordAndMakeFileprivate(keyword: accessKeyword.name.text)
      } else {
        message = .moveAccessKeyword(keyword: accessKeyword.name.text)
      }

      let (newMembers, notes) =
        addMemberAccessKeyword(accessKeywordToAdd, toMembersIn: node.memberBlock)
      diagnose(message, on: accessKeyword, notes: notes)

      result.modifiers.remove(anyOf: [keyword])
      result.extensionKeyword.leadingTrivia = accessKeyword.leadingTrivia
      result.memberBlock.members = newMembers
      return DeclSyntax(result)

    // Internal keyword redundant, delete
    case .internal:
      diagnose(.removeRedundantAccessKeyword, on: accessKeyword)

      result.modifiers.remove(anyOf: [keyword])
      result.extensionKeyword.leadingTrivia = accessKeyword.leadingTrivia
      return DeclSyntax(result)

    default:
      break
    }

    return DeclSyntax(result)
  }

  // Adds given keyword to all members in declaration block
  private func addMemberAccessKeyword(
    _ modifier: DeclModifierSyntax,
    toMembersIn memberBlock: MemberBlockSyntax
  ) -> (MemberBlockItemListSyntax, [Finding.Note]) {
    var newMembers: [MemberBlockItemSyntax] = []
    var notes: [Finding.Note] = []

    for memberItem in memberBlock.members {
      let decl = memberItem.decl
      guard
        let modifiers = decl.asProtocol(WithModifiersSyntax.self)?.modifiers,
        modifiers.accessLevelModifier == nil
      else {
        newMembers.append(memberItem)
        continue
      }

      // Create a note associated with each declaration that needs to have an access level modifier
      // added to it.
      notes.append(
        Finding.Note(
          message: .addModifierToExtensionMember(keyword: modifier.name.text),
          location:
            Finding.Location(decl.startLocation(converter: context.sourceLocationConverter))
        )
      )

      var newItem = memberItem
      newItem.decl = applyingAccessModifierIfNone(modifier, to: decl)
      newMembers.append(newItem)
    }

    return (MemberBlockItemListSyntax(newMembers), notes)
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

/// Adds `modifier` to `decl` if it doesn't already have an explicit access level modifier and
/// returns the new declaration.
///
/// If `decl` already has an access level modifier, it is returned unchanged.
private func applyingAccessModifierIfNone(
  _ modifier: DeclModifierSyntax,
  to decl: DeclSyntax
) -> DeclSyntax {
  switch Syntax(decl).as(SyntaxEnum.self) {
  case .actorDecl(let actorDecl):
    return applyingAccessModifierIfNone(modifier, to: actorDecl, declKeywordKeyPath: \.actorKeyword)
  case .classDecl(let classDecl):
    return applyingAccessModifierIfNone(modifier, to: classDecl, declKeywordKeyPath: \.classKeyword)
  case .enumDecl(let enumDecl):
    return applyingAccessModifierIfNone(modifier, to: enumDecl, declKeywordKeyPath: \.enumKeyword)
  case .initializerDecl(let initDecl):
    return applyingAccessModifierIfNone(modifier, to: initDecl, declKeywordKeyPath: \.initKeyword)
  case .functionDecl(let funcDecl):
    return applyingAccessModifierIfNone(modifier, to: funcDecl, declKeywordKeyPath: \.funcKeyword)
  case .structDecl(let structDecl):
    return applyingAccessModifierIfNone(
      modifier,
      to: structDecl,
      declKeywordKeyPath: \.structKeyword
    )
  case .subscriptDecl(let subscriptDecl):
    return applyingAccessModifierIfNone(
      modifier,
      to: subscriptDecl,
      declKeywordKeyPath: \.subscriptKeyword
    )
  case .typeAliasDecl(let typeAliasDecl):
    return applyingAccessModifierIfNone(
      modifier,
      to: typeAliasDecl,
      declKeywordKeyPath: \.typealiasKeyword
    )
  case .variableDecl(let varDecl):
    return applyingAccessModifierIfNone(
      modifier,
      to: varDecl,
      declKeywordKeyPath: \.bindingSpecifier
    )
  default:
    return decl
  }
}

private func applyingAccessModifierIfNone<Decl: DeclSyntaxProtocol & WithModifiersSyntax>(
  _ modifier: DeclModifierSyntax,
  to decl: Decl,
  declKeywordKeyPath: WritableKeyPath<Decl, TokenSyntax>
) -> DeclSyntax {
  // If there's already an access modifier among the modifier list, bail out.
  guard decl.modifiers.accessLevelModifier == nil else { return DeclSyntax(decl) }

  var result = decl
  var modifier = modifier
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
