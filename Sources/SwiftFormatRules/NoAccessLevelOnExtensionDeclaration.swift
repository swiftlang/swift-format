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

import SwiftFormatCore
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
public final class NoAccessLevelOnExtensionDeclaration: SyntaxFormatRule {

  public override func visit(_ node: ExtensionDeclSyntax) -> DeclSyntax {
    guard let modifiers = node.modifiers, modifiers.count != 0 else { return DeclSyntax(node) }
    guard let accessKeyword = modifiers.accessLevelModifier else { return DeclSyntax(node) }

    let keywordKind = accessKeyword.name.tokenKind
    switch keywordKind {
    // Public, private, or fileprivate keywords need to be moved to members
    case .publicKeyword, .privateKeyword, .fileprivateKeyword:
      diagnose(.moveAccessKeyword(keyword: accessKeyword.name.text), on: accessKeyword)

      // The effective access level of the members of a `private` extension is `fileprivate`, so
      // we have to update the keyword to ensure that the result is correct.
      let accessKeywordToAdd: DeclModifierSyntax
      if keywordKind == .privateKeyword {
        accessKeywordToAdd
          = accessKeyword.withName(accessKeyword.name.withKind(.fileprivateKeyword))
      } else {
        accessKeywordToAdd = accessKeyword
      }

      let newMembers = MemberDeclBlockSyntax(
        leftBrace: node.members.leftBrace,
        members: addMemberAccessKeywords(memDeclBlock: node.members, keyword: accessKeywordToAdd),
        rightBrace: node.members.rightBrace)
      let newKeyword = replaceTrivia(
        on: node.extensionKeyword,
        token: node.extensionKeyword,
        leadingTrivia: accessKeyword.leadingTrivia)
      let result = node.withMembers(newMembers)
        .withModifiers(modifiers.remove(name: accessKeyword.name.text))
        .withExtensionKeyword(newKeyword)
      return DeclSyntax(result)

    // Internal keyword redundant, delete
    case .internalKeyword:
      diagnose(
        .removeRedundantAccessKeyword(name: node.extendedType.description),
        on: accessKeyword)
      let newKeyword = replaceTrivia(
        on: node.extensionKeyword,
        token: node.extensionKeyword,
        leadingTrivia: accessKeyword.leadingTrivia)
      let result = node.withModifiers(modifiers.remove(name: accessKeyword.name.text))
        .withExtensionKeyword(newKeyword)
      return DeclSyntax(result)

    default:
      break
    }
    return DeclSyntax(node)
  }

  // Adds given keyword to all members in declaration block
  private func addMemberAccessKeywords(
    memDeclBlock: MemberDeclBlockSyntax,
    keyword: DeclModifierSyntax
  ) -> MemberDeclListSyntax {
    var newMembers: [MemberDeclListItemSyntax] = []
    let formattedKeyword = replaceTrivia(
      on: keyword,
      token: keyword.name,
      leadingTrivia: [])

    for memberItem in memDeclBlock.members {
      let member = memberItem.decl
      guard
        // addModifier relocates trivia for any token(s) displaced by the new modifier.
        let newDecl = addModifier(declaration: member, modifierKeyword: formattedKeyword)
          .as(DeclSyntax.self)
      else { continue }
      newMembers.append(memberItem.withDecl(newDecl))
    }
    return MemberDeclListSyntax(newMembers)
  }
}

extension Finding.Message {
  public static func removeRedundantAccessKeyword(name: String) -> Finding.Message {
    "remove redundant 'internal' access keyword from \(name)"
  }

  public static func moveAccessKeyword(keyword: String) -> Finding.Message {
    "specify \(keyword) access level for each member inside the extension"
  }
}
