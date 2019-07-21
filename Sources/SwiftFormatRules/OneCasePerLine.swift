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

/// Each enum case with associated values should appear on its own line.
///
/// Lint: If a single `case` declaration declares multiple cases, and any of them have associated
///       values, a lint error is raised.
///
/// Format: All case declarations with associated values will be moved to a new line.
///
/// - SeeAlso: https://google.github.io/swift#enum-cases
public final class OneCasePerLine: SyntaxFormatRule {

  public override func visit(_ node: EnumDeclSyntax) -> DeclSyntax {
    let enumMembers = node.members.members
    var newMembers: [MemberDeclListItemSyntax] = []
    var newIndx = 0

    for member in enumMembers {
      var numNewMembers = 0
      if let caseMember = member.decl as? EnumCaseDeclSyntax {
        var otherDecl: EnumCaseDeclSyntax? = caseMember
        // Add and skip single element case declarations
        guard caseMember.elements.count > 1 else {
          newMembers.append(member.withDecl(caseMember))
          newIndx += 1
          continue
        }
        // Move all cases with associated/raw values to new declarations
        for element in caseMember.elements {
          if element.associatedValue != nil || element.rawValue != nil {
            diagnose(.moveAssociatedOrRawValueCase(name: element.identifier.text), on: element)
            let newRemovedDecl = createAssociateOrRawCaseDecl(
              fullDecl: caseMember,
              removedElement: element)
            newMembers.append(member.withDecl(newRemovedDecl))
            numNewMembers += 1
            otherDecl = removeAssociateOrRawCaseDecl(element, from: otherDecl)
          } else if isIncrementalRawValueCompatibleEnumType(for: node),
            let previousMember = newMembers.last,
            let previousCaseDecl = previousMember.decl as? EnumCaseDeclSyntax,
            isIncrementalRawCase(element, with: previousCaseDecl) {
            // Move all eligible cases to have incremental raw values to previous case declaration
            let newDecl = createIncrementalRawCaseDecl(element, with: previousCaseDecl)
            let lastIndex = newMembers.count - 1
            newMembers[lastIndex] = previousMember.withDecl(newDecl)
            otherDecl = removeAssociateOrRawCaseDecl(element, from: otherDecl)
          }
        }
        // Add case declaration of remaining elements without associated/raw values, if any
        if let otherDecl = otherDecl {
          newMembers.insert(member.withDecl(otherDecl), at: newIndx)
          newIndx += 1
        }
        // Add any member that isn't an enum case declaration
      } else {
        newMembers.append(member)
        newIndx += 1
      }
      newIndx += numNewMembers
    }

    let newMemberBlock = SyntaxFactory.makeMemberDeclBlock(
      leftBrace: node.members.leftBrace,
      members: SyntaxFactory.makeMemberDeclList(newMembers),
      rightBrace: node.members.rightBrace)
    return node.withMembers(newMemberBlock)
  }

  func createAssociateOrRawCaseDecl(
    fullDecl: EnumCaseDeclSyntax,
    removedElement: EnumCaseElementSyntax
  ) -> EnumCaseDeclSyntax {
    let formattedElement = removedElement.withTrailingComma(nil)
    let newElementList = SyntaxFactory.makeEnumCaseElementList([formattedElement])
    let newDecl = SyntaxFactory.makeEnumCaseDecl(
      attributes: fullDecl.attributes,
      modifiers: fullDecl.modifiers,
      caseKeyword: fullDecl.caseKeyword,
      elements: newElementList)
    return newDecl
  }

  // Returns formatted declaration of cases without associated/raw values, or nil if all cases had
  // a raw or associate value
  func removeAssociateOrRawCaseDecl(
    _ element: EnumCaseElementSyntax,
    from fullDecl: EnumCaseDeclSyntax?
  ) -> EnumCaseDeclSyntax? {
    guard let fullDecl = fullDecl,
      let index = fullDecl.elements.first(where: { $0.identifier.text == element.identifier.text})?.indexInParent else { return nil }

    var newList = fullDecl.elements.removing(childAt: index)
    guard newList.count > 0 else { return nil }
    if let lastElement = newList.last, lastElement.trailingComma != nil {
      newList = newList.replacing(
        childAt: lastElement.indexInParent,
        with: lastElement.withTrailingComma(nil)
      )
    }
    return fullDecl.withElements(newList)
  }

  // `Int` or `Float` are the only types that can have cases with incremental raw value
  func isIncrementalRawValueCompatibleEnumType(for enumDecl: EnumDeclSyntax) -> Bool {
    guard let inheritedType = enumDecl.inheritanceClause?.inheritedTypeCollection.firstAndOnly,
      let type = inheritedType.typeName.firstToken else { return false }
    // Other types can have raw values, but not incremental values
    let incrementableRawValueTypes = ["Int", "Float"]
    return incrementableRawValueTypes.contains(type.text)
  }

  //
  func isIncrementalRawCase(
    _ element: EnumCaseElementSyntax,
    with previousCaseDecl: EnumCaseDeclSyntax
  ) -> Bool {
    // Consider if element can have incremental raw value
    // when first case of previous declaration has raw value, but the element doesn't
    guard element.rawValue == nil,
      previousCaseDecl.elements.first?.rawValue != nil else { return false }
    return true
  }

  // Returns formatted declaration of cases with incremental raw values,
  // or nil if previous case didn't have a raw value
  func createIncrementalRawCaseDecl(
    _ element: EnumCaseElementSyntax,
    with previousCaseDecl: EnumCaseDeclSyntax?
  ) -> EnumCaseDeclSyntax? {
    guard let previousElement = previousCaseDecl?.elements.last else { return nil }
    let trailingComma = SyntaxFactory.makeCommaToken(trailingTrivia: .spaces(1))
    let previousElementWithComma = previousElement.withTrailingComma(trailingComma)
    let newElements = previousCaseDecl?.elements
      .replacing(childAt: previousElement.indexInParent, with: previousElementWithComma)
      .appending(element.withTrailingComma(nil))
    return previousCaseDecl?.withElements(newElements)
  }
}

extension Diagnostic.Message {
  static func moveAssociatedOrRawValueCase(name: String) -> Diagnostic.Message {
    return .init(.warning, "move \(name) case to a new line")
  }
}
