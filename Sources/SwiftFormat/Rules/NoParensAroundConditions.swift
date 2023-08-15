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

/// Enforces rules around parentheses in conditions or matched expressions.
///
/// Parentheses are not used around any condition of an `if`, `guard`, or `while` statement, or
/// around the matched expression in a `switch` statement.
///
/// Lint: If a top-most expression in a `switch`, `if`, `guard`, or `while` statement is surrounded
///       by parentheses, and it does not include a function call with a trailing closure, a lint
///       error is raised.
///
/// Format: Parentheses around such expressions are removed, if they do not cause a parse ambiguity.
///         Specifically, parentheses are allowed if and only if the expression contains a function
///         call with a trailing closure.
@_spi(Rules)
public final class NoParensAroundConditions: SyntaxFormatRule {
  private func extractExpr(_ tuple: TupleExprSyntax) -> ExprSyntax {
    assert(tuple.elements.count == 1)
    let expr = tuple.elements.first!.expression

    // If the condition is a function with a trailing closure or if it's an immediately called
    // closure, removing the outer set of parentheses introduces a parse ambiguity.
    if let fnCall = expr.as(FunctionCallExprSyntax.self) {
      if fnCall.trailingClosure != nil {
        // Leave parentheses around call with trailing closure.
        return ExprSyntax(tuple)
      } else if fnCall.calledExpression.as(ClosureExprSyntax.self) != nil {
        // Leave parentheses around immediately called closure.
        return ExprSyntax(tuple)
      }
    }

    diagnose(.removeParensAroundExpression, on: expr)

    guard
      let visitedTuple = visit(tuple).as(TupleExprSyntax.self),
      var visitedExpr = visitedTuple.elements.first?.expression
    else {
      return expr
    }
    visitedExpr.leadingTrivia = visitedTuple.leftParen.leadingTrivia
    visitedExpr.trailingTrivia = visitedTuple.rightParen.trailingTrivia
    return visitedExpr
  }

  public override func visit(_ node: IfExprSyntax) -> ExprSyntax {
    let conditions = visit(node.conditions)
    var result = node.with(\.ifKeyword, node.ifKeyword.withOneTrailingSpace())
      .with(\.conditions, conditions)
      .with(\.body, visit(node.body))
    if let elseBody = node.elseBody {
      result = result.with(\.elseBody, visit(elseBody))
    }
    return ExprSyntax(result)
  }

  public override func visit(_ node: ConditionElementSyntax) -> ConditionElementSyntax {
    guard let tup = node.condition.as(TupleExprSyntax.self),
      tup.elements.firstAndOnly != nil
    else {
      return super.visit(node)
    }
    return node.with(\.condition, .expression(extractExpr(tup)))
  }

  /// FIXME(hbh): Parsing for SwitchExprSyntax is not implemented.
  public override func visit(_ node: SwitchExprSyntax) -> ExprSyntax {
    guard let tup = node.subject.as(TupleExprSyntax.self),
      tup.elements.firstAndOnly != nil
    else {
      return super.visit(node)
    }
    return ExprSyntax(
      node.with(\.subject, extractExpr(tup)).with(\.cases, visit(node.cases)))
  }

  public override func visit(_ node: RepeatStmtSyntax) -> StmtSyntax {
    guard let tup = node.condition.as(TupleExprSyntax.self),
      tup.elements.firstAndOnly != nil
    else {
      return super.visit(node)
    }
    let newNode = node.with(\.condition, extractExpr(tup))
      .with(\.whileKeyword, node.whileKeyword.withOneTrailingSpace())
      .with(\.body, visit(node.body))
    return StmtSyntax(newNode)
  }
}

extension Finding.Message {
  @_spi(Rules)
  public static let removeParensAroundExpression: Finding.Message =
    "remove the parentheses around this expression"
}
