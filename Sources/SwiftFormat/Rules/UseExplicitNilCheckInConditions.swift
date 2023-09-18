//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2023 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import SwiftSyntax
import SwiftSyntaxBuilder

/// When checking an optional value for `nil`-ness, prefer writing an explicit `nil` check rather
/// than binding and immediately discarding the value.
///
/// For example, `if let _ = someValue { ... }` is forbidden. Use `if someValue != nil { ... }`
/// instead.
///
/// Lint: `let _ = expr` inside a condition list will yield a lint error.
///
/// Format: `let _ = expr` inside a condition list will be replaced by `expr != nil`.
@_spi(Rules)
public final class UseExplicitNilCheckInConditions: SyntaxFormatRule {
  public override func visit(_ node: ConditionElementSyntax) -> ConditionElementSyntax {
    switch node.condition {
    case .optionalBinding(let optionalBindingCondition):
      guard
        let initializerClause = optionalBindingCondition.initializer,
        isDiscardedAssignmentPattern(optionalBindingCondition.pattern)
      else {
        return node
      }

      diagnose(.useExplicitNilComparison, on: optionalBindingCondition)

      // Since we're moving the initializer value from the RHS to the LHS of an expression/pattern,
      // preserve the relative position of the trailing trivia. Similarly, preserve the leading
      // trivia of the original node, since that token is being removed entirely.
      var value = initializerClause.value
      let trailingTrivia = value.trailingTrivia
      value.trailingTrivia = []

      return ConditionElementSyntax(
        condition: .expression("\(node.leadingTrivia)\(value) != nil\(trailingTrivia)"))
    default:
      return node
    }
  }

  /// Returns true if the given pattern is a discarding assignment expression (for example, the `_`
  /// in `let _ = x`).
  private func isDiscardedAssignmentPattern(_ pattern: PatternSyntax) -> Bool {
    guard let exprPattern = pattern.as(ExpressionPatternSyntax.self) else {
      return false
    }
    return exprPattern.expression.is(DiscardAssignmentExprSyntax.self)
  }
}

extension Finding.Message {
  @_spi(Rules)
  public static let useExplicitNilComparison: Finding.Message =
    "compare this value using `!= nil` instead of binding and discarding it"
}
