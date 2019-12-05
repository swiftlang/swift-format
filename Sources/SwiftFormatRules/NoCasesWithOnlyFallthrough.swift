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

/// Cases that contain only the `fallthrough` statement are forbidden.
///
/// Lint: Cases containing only the `fallthrough` statement yield a lint error.
///
/// Format: The fallthrough `case` is added as a prefix to the next case unless the next case is
///         `default`; in that case, the fallthrough `case` is deleted.
///
/// - SeeAlso: https://google.github.io/swift#fallthrough-in-switch-statements
public final class NoCasesWithOnlyFallthrough: SyntaxFormatRule {

  public override func visit(_ node: SwitchCaseListSyntax) -> Syntax {
    var newChildren: [Syntax] = []
    var fallthroughOnlyCases: [SwitchCaseSyntax] = []

    /// Flushes any un-collapsed violations to the new cases list.
    func flushViolations() {
      fallthroughOnlyCases.forEach {
        newChildren.append(super.visit($0))
      }
      fallthroughOnlyCases.removeAll()
    }

    for element in node {
      guard let switchCase = element as? SwitchCaseSyntax else {
        // If the element isn't a `SwitchCaseSyntax`, it might be an `#if` block surrounding some
        // conditional cases. Just add it to the list of new cases and then reset our current list
        // of violations because this partitions the cases into sets that we can't merge between.
        flushViolations()
        newChildren.append(visit(element))
        continue
      }

      if isFallthroughOnly(switchCase), let label = switchCase.label as? SwitchCaseLabelSyntax {
        // If the case is fallthrough-only, store it as a violation that we will merge later.
        diagnose(.collapseCase(name: "\(label)"), on: switchCase)
        fallthroughOnlyCases.append(switchCase)
      } else {
        guard !fallthroughOnlyCases.isEmpty else {
          // If there are no violations recorded, just append the case. There's nothing we can try
          // to merge into it.
          newChildren.append(visit(switchCase))
          continue
        }

        // If the case is not a `case ...`, then it must be a `default`. Under *most* circumstances,
        // we could simply remove the immediately preceding `fallthrough`-only cases because they
        // would end up falling through to the `default`, which would match them anyway. However,
        // if any of the patterns in those cases have side effects, removing those cases would
        // change the program's behavior. Nobody should ever write code like this, but we don't want
        // to risk changing behavior just by reformatting.
        guard switchCase.label is SwitchCaseLabelSyntax else {
          flushViolations()
          newChildren.append(visit(switchCase))
          continue
        }

        // We have a case that's not fallthrough-only, and a list of fallthrough-only cases before
        // it. Merge them and add the result to the new list.
        var newCase = mergedCase(violations: fallthroughOnlyCases, validCase: switchCase)

        // Only the first violation case can have displaced trivia, because any non-whitespace
        // trivia in the other violation cases would've prevented collapsing.
        if let displacedLeadingTrivia =
          fallthroughOnlyCases.first?.leadingTrivia?.withoutLastLine()
        {
          let existingLeadingTrivia = newCase.leadingTrivia ?? []
          let mergedLeadingTrivia = displacedLeadingTrivia + existingLeadingTrivia
          newCase = newCase.withLeadingTrivia(mergedLeadingTrivia)
        }

        newChildren.append(visit(newCase))
        fallthroughOnlyCases.removeAll()
      }
    }

    // Flush violations at the end of a list so we don't lose cases that won't get merged with
    // anything.
    flushViolations()

    return SyntaxFactory.makeSwitchCaseList(newChildren)
  }

  /// Returns whether the given `SwitchCaseSyntax` contains only a fallthrough statement.
  ///
  /// - Parameter switchCase: A syntax node describing a case in a switch statement.
  private func isFallthroughOnly(_ switchCase: SwitchCaseSyntax) -> Bool {
    // When there are any additional or non-fallthrough statements, it isn't only a fallthrough.
    guard let onlyStatement = switchCase.statements.firstAndOnly,
      onlyStatement.item is FallthroughStmtSyntax
    else {
      return false
    }

    // Check for any comments that are adjacent to the case or fallthrough statement.
    if let leadingTrivia = switchCase.leadingTrivia,
      leadingTrivia.drop(while: { !$0.isNewline }).contains(where: { $0.isComment })
    {
      return false
    }
    if let leadingTrivia = onlyStatement.leadingTrivia,
      leadingTrivia.drop(while: { !$0.isNewline }).contains(where: { $0.isComment })
    {
      return false
    }

    // Check for any comments that are inline on the fallthrough statement. Inline comments are
    // always stored in the next token's leading trivia.
    if let nextLeadingTrivia = onlyStatement.nextToken?.leadingTrivia,
      nextLeadingTrivia.prefix(while: { !$0.isNewline }).contains(where: { $0.isComment })
    {
      return false
    }
    return true
  }

  /// Returns a copy of the given valid case (and its statements) but with the case items from the
  /// violations merged with its own case items.
  private func mergedCase(violations: [SwitchCaseSyntax], validCase: SwitchCaseSyntax)
    -> SwitchCaseSyntax
  {
    var newCaseItems: [CaseItemSyntax] = []

    for label in violations.lazy.compactMap({ $0.label as? SwitchCaseLabelSyntax }) {
      let caseItems = Array(label.caseItems)

      // We can blindly append all but the last case item because they must already have a trailing
      // comma. Then, we need to add a trailing comma to the last one, since it will be followed by
      // more items.
      newCaseItems.append(contentsOf: caseItems.dropLast())
      newCaseItems.append(
        caseItems.last!.withTrailingComma(
          SyntaxFactory.makeCommaToken(trailingTrivia: .spaces(1))))
    }

    let validCaseLabel = validCase.label as! SwitchCaseLabelSyntax
    newCaseItems.append(contentsOf: validCaseLabel.caseItems)

    return validCase.withLabel(
      validCaseLabel.withCaseItems(
        SyntaxFactory.makeCaseItemList(newCaseItems)))
  }
}

extension TriviaPiece {
  /// Returns whether this piece is any type of comment.
  var isComment: Bool {
    switch self {
    case .lineComment, .blockComment, .docLineComment, .docBlockComment:
      return true
    default:
      return false
    }
  }

  /// Returns whether this piece is a number of newlines.
  var isNewline: Bool {
    switch self {
    case .newlines:
      return true
    default:
      return false
    }
  }
}

extension Diagnostic.Message {
  static func collapseCase(name: String) -> Diagnostic.Message {
    return .init(.warning, "combine fallthrough-only case \(name) with a following case")
  }
}
