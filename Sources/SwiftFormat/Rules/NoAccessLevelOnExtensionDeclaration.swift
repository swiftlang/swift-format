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
    // Public, private, or fileprivate keywords need to be moved to members
    case .public, .private, .fileprivate:
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
    _ keyword: DeclModifierSyntax,
    toMembersIn memberBlock: MemberBlockSyntax
  ) -> (MemberBlockItemListSyntax, [Finding.Note]) {
    var newMembers: [MemberBlockItemSyntax] = []
    var notes: [Finding.Note] = []

    var formattedKeyword = keyword
    formattedKeyword.leadingTrivia = []

    for memberItem in memberBlock.members {
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

      var newItem = memberItem
      newItem.decl = newDecl
      newMembers.append(newItem)

      // If it already had an explicit access modifier, don't leave a note.
      if modifiers.accessLevelModifier == nil {
        notes.append(Finding.Note(
          message: .addModifierToExtensionMember(keyword: formattedKeyword.name.text),
          location:
            Finding.Location(member.startLocation(converter: context.sourceLocationConverter))
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
