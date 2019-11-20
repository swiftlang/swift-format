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

import Foundation
import SwiftFormatCore
import SwiftSyntax

/// At least one blank line between each member of a type.
///
/// Optionally, declarations of single-line properties can be ignored.
///
/// This rule does not check the maximum number of blank lines; the pretty printer clamps those
/// as needed.
///
/// Lint: If there are no blank lines between members, a lint error is raised.
///
/// Format: Declarations with no blank lines will have a blank line inserted.
///
/// Configuration: blankLineBetweenMembers.ignoreSingleLineProperties
///
/// - SeeAlso: https://google.github.io/swift#vertical-whitespace
public final class BlankLineBetweenMembers: SyntaxFormatRule {
  public override func visit(_ node: MemberDeclBlockSyntax) -> Syntax {
    // This rule is implemented by ensuring that all multiline member decls include a blank line
    // before the member's leading trivia and a blank line after any members that have a preceding
    // comment. Any comments that are separated from a member with blank lines are ignored, because
    // those comments aren't considered to be related to a specific member.

    guard let firstMember = node.members.first else { return super.visit(node) }
    let ignoreSingleLine = context.configuration.blankLineBetweenMembers.ignoreSingleLineProperties

    // The first member can just be added as-is; we don't force any newline before it.
    var membersList = [visitNestedDecls(of: firstMember)]

    // The first comment may not be "attached" to the first member. Ignore any comments that are
    // separated from the member by a newline.
    let shouldIncludeLeadingComment = !isLeadingTriviaSeparate(from: firstMember)
    var previousMemberWasSingleLine = firstMember.isSingleLine(
      includingLeadingComment: shouldIncludeLeadingComment,
      sourceLocationConverter: context.sourceLocationConverter
    )

    // Iterates through all the declaration of the member, to ensure that the declarations have
    // at least one blank line between them when necessary.
    for member in node.members.dropFirst() {
      var memberToAdd = visitNestedDecls(of: member)

      // Include the comment here to ensure all comments have a preceding blank line.
      let isMemberSingleLine = memberToAdd.isSingleLine(
        includingLeadingComment: true,
        sourceLocationConverter: context.sourceLocationConverter)

      let ignoreMember = ignoreSingleLine && isMemberSingleLine
      if (!previousMemberWasSingleLine || !ignoreMember) && !isLeadingBlankLinePresent(on: member) {
        memberToAdd = replaceTrivia(
          on: memberToAdd,
          token: memberToAdd.firstToken,
          leadingTrivia: blankLinePrefixedTrivia(member.leadingTrivia)
        ) as! MemberDeclListItemSyntax
        diagnose(.addBlankLine, on: member)
      }

      membersList.append(memberToAdd)

      // Consider the member single line if the trivia was separate so that non-member-specific
      // comments won't cause blank lines between members that are otherwise single line.
      previousMemberWasSingleLine = isMemberSingleLine || isLeadingTriviaSeparate(from: memberToAdd)
    }

    return node.withMembers(SyntaxFactory.makeMemberDeclList(membersList))
  }

  /// Returns new trivia with a blank line inserted at the "beginning" of the given trivia, but
  /// respecting any end-of-line comments associated with the previous line that may be present.
  private func blankLinePrefixedTrivia(_ trivia: Trivia?) -> Trivia {
    guard let trivia = trivia else { return .newlines(1) }

    guard let firstNewlineIndex = trivia.firstIndex(where: {
      switch $0 {
      case .newlines, .carriageReturns, .carriageReturnLineFeeds:
        return true
      default:
        return false
      }
    }) else {
      return .newlines(1) + trivia
    }

    let newPieces = trivia[..<firstNewlineIndex] + [.newlines(1)] + trivia[firstNewlineIndex...]
    return Trivia(pieces: newPieces).condensed()
  }

  /// Returns whether any comments in the leading trivia of the given node are separated from the
  /// non-trivia tokens by at least 1 blank line.
  private func isLeadingTriviaSeparate(from node: Syntax) -> Bool {
    guard let leadingTrivia = node.leadingTrivia else {
      return false
    }
    if case let .newlines(count)? = leadingTrivia.withoutSpaces().suffix(1).first {
      return count > 1
    }
    return false
  }

  /// Returns whether there is at least 1 blank line in the leading trivia of the given node.
  private func isLeadingBlankLinePresent(on node: Syntax) -> Bool {
    guard let leadingTrivia = node.leadingTrivia else {
      return false
    }
    return leadingTrivia.numberOfLeadingNewlines > 1
  }

  /// Recursively ensures all nested member types follows the BlankLineBetweenMembers rule.
  func visitNestedDecls(of member: MemberDeclListItemSyntax) -> MemberDeclListItemSyntax {
    switch member.decl {
    case let nestedEnum as EnumDeclSyntax:
      let nestedMembers = visit(nestedEnum.members)
      let newDecl = nestedEnum.withMembers(nestedMembers as? MemberDeclBlockSyntax)
      return member.withDecl(newDecl)
    case let nestedStruct as StructDeclSyntax:
      let nestedMembers = visit(nestedStruct.members)
      let newDecl = nestedStruct.withMembers(nestedMembers as? MemberDeclBlockSyntax)
      return member.withDecl(newDecl)
    case let nestedClass as ClassDeclSyntax:
      let nestedMembers = visit(nestedClass.members)
      let newDecl = nestedClass.withMembers(nestedMembers as? MemberDeclBlockSyntax)
      return member.withDecl(newDecl)
    case let nestedExtension as ExtensionDeclSyntax:
      let nestedMembers = visit(nestedExtension.members)
      let newDecl = nestedExtension.withMembers(nestedMembers as? MemberDeclBlockSyntax)
      return member.withDecl(newDecl)
    default:
      return member
    }
  }
}

extension Diagnostic.Message {
  static let addBlankLine = Diagnostic.Message(.warning, "add one blank line between declarations")
}
