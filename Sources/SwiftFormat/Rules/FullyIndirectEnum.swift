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

/// If all cases of an enum are `indirect`, the entire enum should be marked `indirect`.
///
/// Lint: If every case of an enum is `indirect`, but the enum itself is not, a lint error is
///       raised.
///
/// Format: Enums where all cases are `indirect` will be rewritten such that the enum is marked
///         `indirect`, and each case is not.
@_spi(Rules)
public final class FullyIndirectEnum: SyntaxFormatRule {

  public override func visit(_ node: EnumDeclSyntax) -> DeclSyntax {
    let enumMembers = node.memberBlock.members
    guard !node.modifiers.has(modifier: "indirect"),
      allCasesAreIndirect(in: enumMembers)
    else {
      return DeclSyntax(node)
    }

    diagnose(.moveIndirectKeywordToEnumDecl(name: node.name.text), on: node.name)

    // Removes 'indirect' keyword from cases, reformats
    let newMembers = enumMembers.map {
      (member: MemberBlockItemSyntax) -> MemberBlockItemSyntax in
      guard let caseMember = member.decl.as(EnumCaseDeclSyntax.self),
        caseMember.modifiers.has(modifier: "indirect"),
        let firstModifier = caseMember.modifiers.first
      else {
        return member
      }

      let newCase = caseMember.with(\.modifiers, caseMember.modifiers.remove(name: "indirect"))
      let formattedCase = rearrangeLeadingTrivia(firstModifier.leadingTrivia, on: newCase)
      return member.with(\.decl, DeclSyntax(formattedCase))
    }

    // If the `indirect` keyword being added would be the first token in the decl, we need to move
    // the leading trivia from the `enum` keyword to the new modifier to preserve the existing
    // line breaks/comments/indentation.
    let firstTok = node.firstToken(viewMode: .sourceAccurate)!
    let leadingTrivia: Trivia
    var newEnumDecl = node

    if firstTok.tokenKind == .keyword(.enum) {
      leadingTrivia = firstTok.leadingTrivia
      newEnumDecl.leadingTrivia = []
    } else {
      leadingTrivia = []
    }

    let newModifier = DeclModifierSyntax(
      name: TokenSyntax.identifier(
        "indirect", leadingTrivia: leadingTrivia, trailingTrivia: .spaces(1)), detail: nil)

    let newMemberBlock = node.memberBlock.with(\.members, MemberBlockItemListSyntax(newMembers))
    return DeclSyntax(
      newEnumDecl
        .with(\.modifiers, newEnumDecl.modifiers + [newModifier])
        .with(\.memberBlock, newMemberBlock))
  }

  /// Returns a value indicating whether all enum cases in the given list are indirect.
  ///
  /// Note that if the enum has no cases, this returns false.
  private func allCasesAreIndirect(in members: MemberBlockItemListSyntax) -> Bool {
    var hadCases = false
    for member in members {
      if let caseMember = member.decl.as(EnumCaseDeclSyntax.self) {
        hadCases = true
        guard caseMember.modifiers.has(modifier: "indirect") else {
          return false
        }
      }
    }
    return hadCases
  }

  /// Transfers given leading trivia to the first token in the case declaration.
  private func rearrangeLeadingTrivia(
    _ leadingTrivia: Trivia,
    on enumCaseDecl: EnumCaseDeclSyntax
  ) -> EnumCaseDeclSyntax {
    var formattedCase = enumCaseDecl

    if var firstModifier = formattedCase.modifiers.first {
      // If the case has modifiers, attach the leading trivia to the first one.
      firstModifier.leadingTrivia = leadingTrivia
      formattedCase.modifiers[formattedCase.modifiers.startIndex] = firstModifier
      formattedCase.modifiers = formattedCase.modifiers
    } else {
      // Otherwise, attach the trivia to the `case` keyword itself.
      formattedCase.caseKeyword.leadingTrivia = leadingTrivia
    }

    return formattedCase
  }
}

extension Finding.Message {
  @_spi(Rules)
  public static func moveIndirectKeywordToEnumDecl(name: String) -> Finding.Message {
    "move 'indirect' before the enum declaration '\(name)' when all cases are indirect"
  }
}
