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

/// If all cases of an enum are `indirect`, the entire enum should be marked `indirect`.
///
/// Lint: If every case of an enum is `indirect`, but the enum itself is not, a lint error is
///       raised.
///
/// Format: Enums where all cases are `indirect` will be rewritten such that the enum is marked
///         `indirect`, and each case is not.
public final class FullyIndirectEnum: SyntaxFormatRule {

  public override func visit(_ node: EnumDeclSyntax) -> DeclSyntax {
    let enumMembers = node.members.members
    guard let enumModifiers = node.modifiers,
      !enumModifiers.has(modifier: "indirect"),
      allCasesAreIndirect(in: enumMembers)
    else {
      return DeclSyntax(node)
    }

    diagnose(.moveIndirectKeywordToEnumDecl(name: node.identifier.text), on: node.identifier)

    // Removes 'indirect' keyword from cases, reformats
    let newMembers = enumMembers.map {
      (member: MemberDeclListItemSyntax) -> MemberDeclListItemSyntax in
      guard let caseMember = member.decl.as(EnumCaseDeclSyntax.self),
        let modifiers = caseMember.modifiers,
        modifiers.has(modifier: "indirect"),
        let firstModifier = modifiers.first
      else {
        return member
      }

      let newCase = caseMember.withModifiers(modifiers.remove(name: "indirect"))
      let formattedCase = formatCase(
        unformattedCase: newCase, leadingTrivia: firstModifier.leadingTrivia)
      return member.withDecl(DeclSyntax(formattedCase))
    }

    // If the `indirect` keyword being added would be the first token in the decl, we need to move
    // the leading trivia from the `enum` keyword to the new modifier to preserve the existing
    // line breaks/comments/indentation.
    let firstTok = node.firstToken!
    let leadingTrivia: Trivia
    let newEnumDecl: EnumDeclSyntax

    if firstTok.tokenKind == .enumKeyword {
      leadingTrivia = firstTok.leadingTrivia
      newEnumDecl = replaceTrivia(
        on: node, token: node.firstToken, leadingTrivia: [])
    } else {
      leadingTrivia = []
      newEnumDecl = node
    }

    let newModifier = DeclModifierSyntax(
      name: TokenSyntax.identifier(
        "indirect", leadingTrivia: leadingTrivia, trailingTrivia: .spaces(1)), detail: nil)

    let newMemberBlock = node.members.withMembers(MemberDeclListSyntax(newMembers))
    return DeclSyntax(newEnumDecl.addModifier(newModifier).withMembers(newMemberBlock))
  }

  /// Returns a value indicating whether all enum cases in the given list are indirect.
  ///
  /// Note that if the enum has no cases, this returns false.
  private func allCasesAreIndirect(in members: MemberDeclListSyntax) -> Bool {
    var hadCases = false
    for member in members {
      if let caseMember = member.decl.as(EnumCaseDeclSyntax.self) {
        hadCases = true
        guard let modifiers = caseMember.modifiers, modifiers.has(modifier: "indirect") else {
          return false
        }
      }
    }
    return hadCases
  }

  /// Transfers given leading trivia to the first token in the case declaration.
  private func formatCase(
    unformattedCase: EnumCaseDeclSyntax,
    leadingTrivia: Trivia?
  ) -> EnumCaseDeclSyntax {
    if let modifiers = unformattedCase.modifiers, let first = modifiers.first {
      return replaceTrivia(
        on: unformattedCase, token: first.firstToken, leadingTrivia: leadingTrivia
      )
    } else {
      return replaceTrivia(
        on: unformattedCase, token: unformattedCase.caseKeyword, leadingTrivia: leadingTrivia
      )
    }
  }
}

extension Finding.Message {
  public static func moveIndirectKeywordToEnumDecl(name: String) -> Finding.Message {
    "move 'indirect' to \(name) enum declaration when all cases are indirect"
  }
}
