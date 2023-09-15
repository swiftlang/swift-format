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

/// Every variable bound in a `case` pattern must have its own `let/var`.
///
/// For example, `case let .identifier(x, y)` is forbidden. Use
/// `case .identifier(let x, let y)` instead.
///
/// Lint: `case let .identifier(...)` will yield a lint error.
public final class UseLetInEveryBoundCaseVariable: SyntaxLintRule {

  public override func visit(_ node: ValueBindingPatternSyntax) -> SyntaxVisitorContinueKind {
    // Diagnose a pattern binding if it is a function call and the callee is a member access
    // expression (e.g., `case let .x(y)` or `case let T.x(y)`).
    if canDistributeLetVarThroughPattern(node.valuePattern) {
      diagnose(.useLetInBoundCaseVariables, on: node)
    }
    return .visitChildren
  }

  /// Returns true if the given pattern is one that allows a `let/var` to be distributed
  /// through to subpatterns.
  private func canDistributeLetVarThroughPattern(_ pattern: PatternSyntax) -> Bool {
    guard let exprPattern = pattern.as(ExpressionPatternSyntax.self) else { return false }

    // Drill down into any optional patterns that we encounter (e.g., `case let .foo(x)?`).
    var expression = exprPattern.expression
    while true {
      if let optionalExpr = expression.as(OptionalChainingExprSyntax.self) {
        expression = optionalExpr.expression
      } else if let forcedExpr = expression.as(ForcedValueExprSyntax.self) {
        expression = forcedExpr.expression
      } else {
        break
      }
    }

    // Enum cases are written as function calls on member access expressions. The arguments
    // are the associated values, so the `let/var` can be distributed into those.
    if let functionCall = expression.as(FunctionCallExprSyntax.self),
      functionCall.calledExpression.is(MemberAccessExprSyntax.self)
    {
      return true
    }

    // A tuple expression can have the `let/var` distributed into the elements.
    if expression.is(TupleExprSyntax.self) {
      return true
    }

    // Otherwise, we're not sure this is a pattern we can distribute through.
    return false
  }
}

extension Finding.Message {
  public static let useLetInBoundCaseVariables: Finding.Message =
    "move 'let' keyword to precede each variable bound in the `case` pattern"
}
