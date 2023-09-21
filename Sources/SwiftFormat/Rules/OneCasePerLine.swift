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

/// Each enum case with associated values or a raw value should appear in its own case declaration.
///
/// Lint: If a single `case` declaration declares multiple cases, and any of them have associated
///       values or raw values, a lint error is raised.
///
/// Format: All case declarations with associated values or raw values will be moved to their own
///         case declarations.
@_spi(Rules)
public final class OneCasePerLine: SyntaxFormatRule {

  /// A state machine that collects case elements encountered during visitation and allows new case
  /// declarations to be created with those elements.
  private struct CaseElementCollector {

    /// The case declaration used as the source from which additional new declarations will be
    /// created; thus, all new cases will share the same attributes and modifiers as the basis.
    public private(set) var basis: EnumCaseDeclSyntax

    /// Case elements collected so far.
    private var elements = [EnumCaseElementSyntax]()

    /// Indicates whether the full leading trivia of basis case declaration should be preserved by
    /// the next case declaration that will be created by copying the basis declaration.
    ///
    /// This is true for the first case (to preserve any leading comments on the original case
    /// declaration) and false for all subsequent cases (so that we don't repeat those comments).
    private var shouldKeepLeadingTrivia = true

    /// Creates a new case element collector based on the given case declaration.
    init(basedOn basis: EnumCaseDeclSyntax) {
      self.basis = basis
    }

    /// Adds a new case element to the collector.
    mutating func addElement(_ element: EnumCaseElementSyntax) {
      elements.append(element)
    }

    /// Creates a new case declaration with the elements collected so far, then resets the internal
    /// state to start a new empty declaration again.
    ///
    /// This will return nil if there are no elements collected since the last time this was called
    /// (or the collector was created).
    mutating func makeCaseDeclAndReset() -> EnumCaseDeclSyntax? {
      guard !elements.isEmpty else { return nil }

      // Remove the trailing comma on the final element, if there was one.
      elements[elements.count - 1].trailingComma = nil

      defer { elements.removeAll() }
      return makeCaseDeclFromBasis(elements: elements)
    }

    /// Creates and returns a new `EnumCaseDeclSyntax` with the given elements, based on the current
    /// basis declaration, and updates the comment preserving state if needed.
    mutating func makeCaseDeclFromBasis(elements: [EnumCaseElementSyntax]) -> EnumCaseDeclSyntax {
      var caseDecl = basis
      caseDecl.elements = EnumCaseElementListSyntax(elements)

      if shouldKeepLeadingTrivia {
        shouldKeepLeadingTrivia = false

        // We don't bother preserving any indentation because the pretty printer will fix that up.
        // All we need to do here is ensure that there is a newline.
        basis.leadingTrivia = Trivia.newlines(1)
      }

      return caseDecl
    }
  }

  public override func visit(_ node: EnumDeclSyntax) -> DeclSyntax {
    var newMembers: [MemberBlockItemSyntax] = []

    for member in node.memberBlock.members {
      // If it's not a case declaration, or it's a case declaration with only one element, leave it
      // alone.
      guard let caseDecl = member.decl.as(EnumCaseDeclSyntax.self), caseDecl.elements.count > 1 else {
        newMembers.append(member)
        continue
      }

      var collector = CaseElementCollector(basedOn: caseDecl)

      // Collect the elements of the case declaration until we see one that has either an associated
      // value or a raw value.
      for element in caseDecl.elements {
        if element.parameterClause != nil || element.rawValue != nil {
          // Once we reach one of these, we need to write out the ones we've collected so far, then
          // emit a separate case declaration with the associated/raw value element.
          diagnose(.moveAssociatedOrRawValueCase(name: element.name.text), on: element)

          if let caseDeclForCollectedElements = collector.makeCaseDeclAndReset() {
            var newMember = member
            newMember.decl = DeclSyntax(caseDeclForCollectedElements)
            newMembers.append(newMember)
          }

          var basisElement = element
          basisElement.trailingComma = nil
          let separatedCaseDecl = collector.makeCaseDeclFromBasis(elements: [basisElement])

          var newMember = member
          newMember.decl = DeclSyntax(separatedCaseDecl)
          newMembers.append(newMember)
        } else {
          collector.addElement(element)
        }
      }

      // Make sure to emit any trailing collected elements.
      if let caseDeclForCollectedElements = collector.makeCaseDeclAndReset() {
        var newMember = member
        newMember.decl = DeclSyntax(caseDeclForCollectedElements)
        newMembers.append(newMember)
      }
    }

    var result = node
    result.memberBlock.members = MemberBlockItemListSyntax(newMembers)
    return DeclSyntax(result)
  }
}

extension Finding.Message {
  fileprivate static func moveAssociatedOrRawValueCase(name: String) -> Finding.Message {
    "move '\(name)' to its own 'case' declaration"
  }
}
