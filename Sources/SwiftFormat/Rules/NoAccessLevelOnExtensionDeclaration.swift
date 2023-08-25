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
    guard !node.modifiers.isEmpty else { return DeclSyntax(node) }
    guard let accessKeyword = node.modifiers.accessLevelModifier else { return DeclSyntax(node) }

    let keywordKind = accessKeyword.name.tokenKind
    switch keywordKind {
    // Public, private, or fileprivate keywords need to be moved to members
    case .keyword(.public), .keyword(.private), .keyword(.fileprivate):
      // The effective access level of the members of a `private` extension is `fileprivate`, so
      // we have to update the keyword to ensure that the result is correct.
      let accessKeywordToAdd: DeclModifierSyntax
      let message: Finding.Message
      if keywordKind == .keyword(.private) {
        accessKeywordToAdd
          = accessKeyword.with(\.name, accessKeyword.name.with(\.tokenKind, .keyword(.fileprivate)))
        message = .moveAccessKeywordAndMakeFileprivate(keyword: accessKeyword.name.text)
      } else {
        accessKeywordToAdd = accessKeyword
        message = .moveAccessKeyword(keyword: accessKeyword.name.text)
      }

      let (newMemberBlock, notes) = addMemberAccessKeywords(
        memDeclBlock: node.memberBlock, keyword: accessKeywordToAdd)
      diagnose(message, on: accessKeyword, notes: notes)

      let newMembers = MemberBlockSyntax(
        leftBrace: node.memberBlock.leftBrace,
        members: newMemberBlock,
        rightBrace: node.memberBlock.rightBrace)
      var newKeyword = node.extensionKeyword
      newKeyword.leadingTrivia = accessKeyword.leadingTrivia
      let result = node.with(\.memberBlock, newMembers)
        .with(\.modifiers, node.modifiers.remove(name: accessKeyword.name.text))
        .with(\.extensionKeyword, newKeyword)
      return DeclSyntax(result)

    // Internal keyword redundant, delete
    case .keyword(.internal):
      diagnose(.removeRedundantAccessKeyword, on: accessKeyword)
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
  ) -> (MemberBlockItemListSyntax, [Finding.Note]) {
    var newMembers: [MemberBlockItemSyntax] = []
    var notes: [Finding.Note] = []

    var formattedKeyword = keyword
    formattedKeyword.leadingTrivia = []

    for memberItem in memDeclBlock.members {
      let member = memberItem.decl
      guard
        let modifiers = member.asProtocol(WithModifiersSyntax.self)?.modifiers,
        // addModifier relocates trivia for any token(s) displaced by the new modifier.
        let newDecl = addModifier(declaration: member, modifierKeyword: formattedKeyword)
          .as(DeclSyntax.self)
      else {
        newMembers.append(memberItem)
        continue
      }

      newMembers.append(memberItem.with(\.decl, newDecl))

      // If it already had an explicit access modifier, don't leave a note.
      if modifiers.accessLevelModifier == nil {
        notes.append(Finding.Note(
          message: .addModifierToExtensionMember(keyword: formattedKeyword.name.text),
          location: Finding.Location(member.startLocation(converter: context.sourceLocationConverter))
        ))
      }
    }
    return (MemberBlockItemListSyntax(newMembers), notes)
  }
}

extension Finding.Message {
  @_spi(Rules)
  public static let removeRedundantAccessKeyword: Finding.Message =
    "remove this redundant 'internal' access modifier from this extension"

  @_spi(Rules)
  public static func moveAccessKeyword(keyword: String) -> Finding.Message {
    "move this '\(keyword)' access modifier to precede each member inside this extension"
  }

  @_spi(Rules)
  public static func moveAccessKeywordAndMakeFileprivate(keyword: String) -> Finding.Message {
    "remove this '\(keyword)' access modifier and declare each member inside this extension as 'fileprivate'"
  }

  @_spi(Rules)
  public static func addModifierToExtensionMember(keyword: String) -> Finding.Message {
    "add '\(keyword)' access modifier to this declaration"
  }
}
