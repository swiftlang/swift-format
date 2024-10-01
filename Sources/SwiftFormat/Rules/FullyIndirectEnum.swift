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
    guard !node.modifiers.contains(anyOf: [.indirect]),
      case let indirectModifiers = indirectModifiersIfAllCasesIndirect(in: enumMembers),
      !indirectModifiers.isEmpty
    else {
      return DeclSyntax(node)
    }

    let notes = indirectModifiers.map { modifier in
      Finding.Note(
        message: .removeIndirect,
        location: Finding.Location(
          modifier.startLocation(converter: self.context.sourceLocationConverter)
        )
      )
    }
    diagnose(
      .moveIndirectKeywordToEnumDecl(name: node.name.text),
      on: node.enumKeyword,
      notes: notes
    )

    // Removes 'indirect' keyword from cases, reformats
    let newMembers = enumMembers.map {
      (member: MemberBlockItemSyntax) -> MemberBlockItemSyntax in
      guard let caseMember = member.decl.as(EnumCaseDeclSyntax.self),
        caseMember.modifiers.contains(anyOf: [.indirect]),
        let firstModifier = caseMember.modifiers.first
      else {
        return member
      }

      var newCase = caseMember
      newCase.modifiers.remove(anyOf: [.indirect])

      var newMember = member
      newMember.decl = DeclSyntax(rearrangeLeadingTrivia(firstModifier.leadingTrivia, on: newCase))
      return newMember
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
        "indirect",
        leadingTrivia: leadingTrivia,
        trailingTrivia: .spaces(1)
      ),
      detail: nil
    )

    newEnumDecl.modifiers = newEnumDecl.modifiers + [newModifier]
    newEnumDecl.memberBlock.members = MemberBlockItemListSyntax(newMembers)
    return DeclSyntax(newEnumDecl)
  }

  /// Returns a value indicating whether all enum cases in the given list are indirect.
  ///
  /// Note that if the enum has no cases, this returns false.
  private func indirectModifiersIfAllCasesIndirect(
    in members: MemberBlockItemListSyntax
  ) -> [DeclModifierSyntax] {
    var indirectModifiers = [DeclModifierSyntax]()
    for member in members {
      if let caseMember = member.decl.as(EnumCaseDeclSyntax.self) {
        guard
          let indirectModifier = caseMember.modifiers.first(
            where: { $0.name.text == "indirect" }
          )
        else {
          return []
        }
        indirectModifiers.append(indirectModifier)
      }
    }
    return indirectModifiers
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
  fileprivate static func moveIndirectKeywordToEnumDecl(name: String) -> Finding.Message {
    "declare enum '\(name)' itself as indirect when all cases are indirect"
  }

  fileprivate static let removeIndirect: Finding.Message = "remove 'indirect' here"
}
