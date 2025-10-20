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
/// Note: If the conditional binding carries an explicit type annotation (e.g. `if let _: S? = expr`),
/// we skip the transformation. Such annotations can be necessary to drive generic type inference
/// when a function mentions a type only in its return position.
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
        isDiscardedAssignmentPattern(optionalBindingCondition.pattern),
        optionalBindingCondition.typeAnnotation == nil
      else {
        return node
      }

      diagnose(.useExplicitNilComparison, on: optionalBindingCondition)

      // Since we're moving the initializer value from the RHS to the LHS of an expression/pattern,
      // preserve the relative position of the trailing trivia. Similarly, preserve the leading
      // trivia of the original node, since that token is being removed entirely.
      var value = initializerClause.value
      let trailingTrivia = value.trailingTrivia
      value.trailingTrivia = [.spaces(1)]

      var operatorExpr = BinaryOperatorExprSyntax(text: "!=")
      operatorExpr.trailingTrivia = [.spaces(1)]

      var inequalExpr = InfixOperatorExprSyntax(
        leftOperand: addingParenthesesIfNecessary(to: value),
        operator: operatorExpr,
        rightOperand: NilLiteralExprSyntax()
      )
      inequalExpr.leadingTrivia = node.leadingTrivia
      inequalExpr.trailingTrivia = trailingTrivia

      var result = node
      result.condition = .expression(ExprSyntax(inequalExpr))
      return result
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

  /// Adds parentheses around the given expression if necessary to ensure that it will be parsed
  /// correctly when followed by `!= nil`.
  ///
  /// Specifically, if `expr` is a `try` expression, ternary expression, or an infix operator with
  /// the same or lower precedence, we wrap it.
  private func addingParenthesesIfNecessary(to expr: ExprSyntax) -> ExprSyntax {
    func addingParentheses(to expr: ExprSyntax) -> ExprSyntax {
      var expr = expr
      let leadingTrivia = expr.leadingTrivia
      let trailingTrivia = expr.trailingTrivia
      expr.leadingTrivia = []
      expr.trailingTrivia = []

      var tupleExpr = TupleExprSyntax(elements: [LabeledExprSyntax(expression: expr)])
      tupleExpr.leadingTrivia = leadingTrivia
      tupleExpr.trailingTrivia = trailingTrivia
      return ExprSyntax(tupleExpr)
    }

    switch Syntax(expr).as(SyntaxEnum.self) {
    case .tryExpr, .ternaryExpr:
      return addingParentheses(to: expr)

    case .infixOperatorExpr:
      // There's no public API in SwiftSyntax to get the relationship between two precedence groups.
      // Until that exists, here's a workaround I'm only mildly ashamed of: we reparse
      // "\(expr) != nil" and then fold it. If the top-level node is anything but an
      // `InfixOperatorExpr` whose operator is `!=` and whose RHS is `nil`, then it parsed
      // incorrectly and we need to add parentheses around `expr`.
      //
      // Note that we could also cover the `tryExpr` and `ternaryExpr` cases above with this, but
      // this reparsing trick is going to be slower so we should avoid it whenever we can.
      let reparsedExpr = "\(expr) != nil" as ExprSyntax
      if let infixExpr = reparsedExpr.as(InfixOperatorExprSyntax.self),
        let binOp = infixExpr.operator.as(BinaryOperatorExprSyntax.self),
        binOp.operator.text == "!=",
        infixExpr.rightOperand.is(NilLiteralExprSyntax.self)
      {
        return expr
      }
      return addingParentheses(to: expr)

    default:
      return expr
    }
  }
}

extension Finding.Message {
  fileprivate static let useExplicitNilComparison: Finding.Message =
    "compare this value using `!= nil` instead of binding and discarding it"
}
