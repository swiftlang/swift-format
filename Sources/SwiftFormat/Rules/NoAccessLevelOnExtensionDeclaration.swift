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
///
/// TODO: Find a better way to access modifiers and keyword tokens besides casting each declaration
@_spi(Rules)
public final class NoAccessLevelOnExtensionDeclaration: SyntaxFormatRule {

  public override func visit(_ node: ExtensionDeclSyntax) -> DeclSyntax {
    guard !node.modifiers.isEmpty else { return DeclSyntax(node) }
    guard let accessKeyword = node.modifiers.accessLevelModifier else { return DeclSyntax(node) }

    let keywordKind = accessKeyword.name.tokenKind
    switch keywordKind {
    // Public, private, or fileprivate keywords need to be moved to members
    case .keyword(.public), .keyword(.private), .keyword(.fileprivate):
      diagnose(.moveAccessKeyword(keyword: accessKeyword.name.text), on: accessKeyword)

      // The effective access level of the members of a `private` extension is `fileprivate`, so
      // we have to update the keyword to ensure that the result is correct.
      let accessKeywordToAdd: DeclModifierSyntax
      if keywordKind == .keyword(.private) {
        accessKeywordToAdd
          = accessKeyword.with(\.name, accessKeyword.name.with(\.tokenKind, .keyword(.fileprivate)))
      } else {
        accessKeywordToAdd = accessKeyword
      }

      let newMembers = MemberBlockSyntax(
        leftBrace: node.memberBlock.leftBrace,
        members: addMemberAccessKeywords(memDeclBlock: node.memberBlock, keyword: accessKeywordToAdd),
        rightBrace: node.memberBlock.rightBrace)
      var newKeyword = node.extensionKeyword
      newKeyword.leadingTrivia = accessKeyword.leadingTrivia
      let result = node.with(\.memberBlock, newMembers)
        .with(\.modifiers, node.modifiers.remove(name: accessKeyword.name.text))
        .with(\.extensionKeyword, newKeyword)
      return DeclSyntax(result)

    // Internal keyword redundant, delete
    case .keyword(.internal):
      diagnose(
        .removeRedundantAccessKeyword(name: node.extendedType.description),
        on: accessKeyword)
      var newKeyword = node.extensionKeyword
      newKeyword.leadingTrivia = accessKeyword.leadingTrivia
      let result = node.with(\.modifiers, node.modifiers.remove(name: accessKeyword.name.text))
        .with(\.extensionKeyword, newKeyword)
      return DeclSyntax(result)

    default:
      break
    }
    return DeclSyntax(node)
  }

  // Adds given keyword to all members in declaration block
  private func addMemberAccessKeywords(
    memDeclBlock: MemberBlockSyntax,
    keyword: DeclModifierSyntax
  ) -> MemberBlockItemListSyntax {
    var newMembers: [MemberBlockItemSyntax] = []

    var formattedKeyword = keyword
    formattedKeyword.leadingTrivia = []

    for memberItem in memDeclBlock.members {
      let member = memberItem.decl
      guard
        // addModifier relocates trivia for any token(s) displaced by the new modifier.
        let newDecl = addModifier(declaration: member, modifierKeyword: formattedKeyword)
          .as(DeclSyntax.self)
      else { continue }
      newMembers.append(memberItem.with(\.decl, newDecl))
    }
    return MemberBlockItemListSyntax(newMembers)
  }
}

extension Finding.Message {
  @_spi(Rules)
  public static func removeRedundantAccessKeyword(name: String) -> Finding.Message {
    "remove redundant 'internal' access keyword from '\(name)'"
  }

  @_spi(Rules)
  public static func moveAccessKeyword(keyword: String) -> Finding.Message {
    "move the '\(keyword)' access keyword to precede each member inside the extension"
  }
}
