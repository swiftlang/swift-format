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

/// Cases that contain only the `fallthrough` statement are forbidden.
///
/// Lint: Cases containing only the `fallthrough` statement yield a lint error.
///
/// Format: The fallthrough `case` is added as a prefix to the next case unless the next case is
///         `default`; in that case, the fallthrough `case` is deleted.
@_spi(Rules)
public final class NoCasesWithOnlyFallthrough: SyntaxFormatRule {

  public override func visit(_ node: SwitchCaseListSyntax) -> SwitchCaseListSyntax {
    var newChildren: [SwitchCaseListSyntax.Element] = []
    var fallthroughOnlyCases: [SwitchCaseSyntax] = []

    /// Flushes any un-collapsed violations to the new cases list.
    func flushViolations() {
      for node in fallthroughOnlyCases {
        newChildren.append(.switchCase(visit(node)))
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
          newChildren.append(.switchCase(visit(switchCase)))
          continue
        }

        if canMergeWithPreviousCases(switchCase) {
          // If the current case can be merged with the ones before it, merge them all, leaving no
          // `fallthrough`-only cases behind.
          let newSwitchCase = visit(switchCase)
          newChildren.append(.switchCase(visit(mergedCases(fallthroughOnlyCases + [newSwitchCase]))))
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
          newChildren.append(.switchCase(visit(mergedCases(fallthroughOnlyCases))))
          newChildren.append(.switchCase(visit(switchCase)))
        }

        fallthroughOnlyCases.removeAll()
      }
    }

    // Flush violations at the end of a list so we don't lose cases that won't get merged with
    // anything.
    flushViolations()

    return SwitchCaseListSyntax(newChildren)
  }

  /// Returns true if this case can definitely be merged with any that come before it.
  private func canMergeWithPreviousCases(_ node: SwitchCaseSyntax) -> Bool {
    return node.label.is(SwitchCaseLabelSyntax.self) && !containsValueBindingPattern(node.label)
  }

  /// Returns true if this node or one of its descendents is a `ValueBindingPatternSyntax`.
  private func containsValueBindingPattern(_ node: SwitchCaseSyntax.Label) -> Bool {
    switch node {
    case .case(let label):
      return containsValueBindingPattern(Syntax(label))
    case .default:
      return false
    }
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
      onlyStatement.item.is(FallThroughStmtSyntax.self)
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
    if switchCase.allPrecedingTrivia
      .drop(while: { !$0.isNewline }).contains(where: { $0.isComment })
    {
      return false
    }
    if onlyStatement.allPrecedingTrivia
      .drop(while: { !$0.isNewline }).contains(where: { $0.isComment })
    {
      return false
    }

    // Check for any comments that are inline on the fallthrough statement.
    if onlyStatement.allFollowingTrivia
      .prefix(while: { !$0.isNewline }).contains(where: { $0.isComment })
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

    var newCaseItems: [SwitchCaseItemSyntax] = []
    let labels = cases.lazy.compactMap({ $0.label.as(SwitchCaseLabelSyntax.self) })
    for label in labels.dropLast() {
      // Diagnose the cases being collapsed. We do this for all but the last one in the array; the
      // last one isn't diagnosed because it will contain the body that applies to all the previous
      // cases.
      diagnose(.collapseCase, on: label)

      // We can blindly append all but the last case item because they must already have a trailing
      // comma. Then, we need to add a trailing comma to the last one, since it will be followed by
      // more items.
      newCaseItems.append(contentsOf: label.caseItems.dropLast())

      var lastItem = label.caseItems.last!
      lastItem.trailingComma = TokenSyntax.commaToken(trailingTrivia: [.spaces(1)])
      newCaseItems.append(lastItem)
    }
    newCaseItems.append(contentsOf: labels.last!.caseItems)

    var lastLabel = labels.last!
    lastLabel.caseItems = SwitchCaseItemListSyntax(newCaseItems)

    var lastCase = cases.last!
    lastCase.label = .case(lastLabel)

    // Only the first violation case can have displaced trivia, because any non-whitespace
    // trivia in the other violation cases would've prevented collapsing.
    lastCase.leadingTrivia = cases.first!.leadingTrivia.withoutLastLine() + lastCase.leadingTrivia
    return lastCase
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
  fileprivate static var collapseCase: Finding.Message {
    "combine this fallthrough-only 'case' and the following 'case' into a single 'case'"
  }
}
