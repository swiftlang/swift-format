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

/// Cases that contain only the `fallthrough` statement are forbidden.
///
/// Lint: Cases containing only the `fallthrough` statement yield a lint error.
///
/// Format: The fallthrough `case` is added as a prefix to the next case unless the next case is
///         `default`; in that case, the fallthrough `case` is deleted.
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
      guard let switchCase = element.as(SwitchCaseSyntax.self) else {
        // If the element isn't a `SwitchCaseSyntax`, it might be an `#if` block surrounding some
        // conditional cases. Just add it to the list of new cases and then reset our current list
        // of violations because this partitions the cases into sets that we can't merge between.
        flushViolations()
        newChildren.append(visit(element))
        continue
      }

      if isMergeableFallthroughOnly(switchCase) {
        // Keep track of `fallthrough`-only cases so we can merge and diagnose them later.
        fallthroughOnlyCases.append(switchCase)
      } else {
        guard !fallthroughOnlyCases.isEmpty else {
          // If there are no violations recorded, just append the case. There's nothing we can try
          // to merge into it.
          newChildren.append(visit(switchCase))
          continue
        }

        if canMergeWithPreviousCases(switchCase) {
          // If the current case can be merged with the ones before it, merge them all, leaving no
          // `fallthrough`-only cases behind.
          newChildren.append(visit(mergedCases(fallthroughOnlyCases + [switchCase])))
        } else {
          // If the current case can't be merged with the ones before it, merge the previous ones
          // into a single `fallthrough`-only case and then append the current one. This could
          // happen in one of two situations:
          //
          // 1.  The current case has a value binding pattern.
          // 2.  The current case is the `default`. Under most circumstances, we could simply remove
          //     the immediately preceding `fallthrough`-only cases because they would end up
          //     falling through to the `default` which would match them anyway. However, if any of
          //     the patterns in those cases have side effects, removing those cases would change
          //     the program's behavior.
          // 3.  The current case is `@unknown default`, which can't be merged notwithstanding the
          //     side-effect issues discussed above.
          newChildren.append(visit(mergedCases(fallthroughOnlyCases)))
          newChildren.append(visit(switchCase))
        }

        fallthroughOnlyCases.removeAll()
      }
    }

    // Flush violations at the end of a list so we don't lose cases that won't get merged with
    // anything.
    flushViolations()

    return Syntax(SwitchCaseListSyntax(newChildren))
  }

  /// Returns true if this case can definitely be merged with any that come before it.
  private func canMergeWithPreviousCases(_ node: SwitchCaseSyntax) -> Bool {
    return node.label.is(SwitchCaseLabelSyntax.self) && !containsValueBindingPattern(node.label)
  }

  /// Returns true if this node or one of its descendents is a `ValueBindingPatternSyntax`.
  private func containsValueBindingPattern(_ node: Syntax) -> Bool {
    if node.is(ValueBindingPatternSyntax.self) {
      return true
    }
    for child in node.children(viewMode: .sourceAccurate) {
      if containsValueBindingPattern(child) {
        return true
      }
    }
    return false
  }

  /// Returns whether the given `SwitchCaseSyntax` contains only a fallthrough statement and is
  /// able to be merged with other cases.
  ///
  /// - Parameter switchCase: A syntax node describing a case in a switch statement.
  private func isMergeableFallthroughOnly(_ switchCase: SwitchCaseSyntax) -> Bool {
    // Ignore anything that isn't a `SwitchCaseLabelSyntax`, like a `default`.
    guard switchCase.label.is(SwitchCaseLabelSyntax.self) else {
      return false
    }

    // When there are any additional or non-fallthrough statements, it isn't only a fallthrough.
    guard let onlyStatement = switchCase.statements.firstAndOnly,
      onlyStatement.item.is(FallthroughStmtSyntax.self)
    else {
      return false
    }

    // We cannot merge cases that contain a value pattern binding, even if the body is `fallthrough`
    // only. For example, `case .foo(let x)` cannot be combined with other cases unless they all
    // bind the same variables and types.
    if containsValueBindingPattern(switchCase.label) {
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

  /// Returns a merged case whose body is derived from the last case in the array, and the labels
  /// of all the cases are merged into a single comma-delimited list.
  private func mergedCases(_ cases: [SwitchCaseSyntax]) -> SwitchCaseSyntax {
    precondition(!cases.isEmpty, "Must have at least one case to merge")

    // If there's only one case, just return it.
    if cases.count == 1 {
      return cases.first!
    }

    var newCaseItems: [CaseItemSyntax] = []
    let labels = cases.lazy.compactMap({ $0.label.as(SwitchCaseLabelSyntax.self) })
    for label in labels.dropLast() {
      // We can blindly append all but the last case item because they must already have a trailing
      // comma. Then, we need to add a trailing comma to the last one, since it will be followed by
      // more items.
      newCaseItems.append(contentsOf: label.caseItems.dropLast())
      newCaseItems.append(
        label.caseItems.last!.withTrailingComma(
          TokenSyntax.commaToken(trailingTrivia: .spaces(1))))

      // Diagnose the cases being collapsed. We do this for all but the last one in the array; the
      // last one isn't diagnosed because it will contain the body that applies to all the previous
      // cases.
      diagnose(.collapseCase(name: label.caseItems.withoutTrivia().description), on: label)
    }
    newCaseItems.append(contentsOf: labels.last!.caseItems)

    let newCase = cases.last!.withLabel(
      Syntax(labels.last!.withCaseItems(CaseItemListSyntax(newCaseItems))))

    // Only the first violation case can have displaced trivia, because any non-whitespace
    // trivia in the other violation cases would've prevented collapsing.
    if let displacedLeadingTrivia = cases.first!.leadingTrivia?.withoutLastLine() {
      let existingLeadingTrivia = newCase.leadingTrivia ?? []
      let mergedLeadingTrivia = displacedLeadingTrivia + existingLeadingTrivia
      return newCase.withLeadingTrivia(mergedLeadingTrivia)
    } else {
      return newCase
    }
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

extension Finding.Message {
  public static func collapseCase(name: String) -> Finding.Message {
    "combine fallthrough-only case \(name) with a following case"
  }
}
