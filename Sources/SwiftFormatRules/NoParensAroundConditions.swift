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
public final class NoParensAroundConditions: SyntaxFormatRule {
  private func extractExpr(_ tuple: TupleExprSyntax) -> ExprSyntax {
    assert(tuple.elementList.count == 1)
    let expr = tuple.elementList.first!.expression

    // If the condition is a function with a trailing closure, removing the
    // outer set of parentheses introduces a parse ambiguity.
    if let fnCall = expr.as(FunctionCallExprSyntax.self), fnCall.trailingClosure != nil {
      return ExprSyntax(tuple)
    }

    diagnose(.removeParensAroundExpression, on: expr)

    guard
      let visitedTuple = visit(tuple).as(TupleExprSyntax.self),
      let visitedExpr = visitedTuple.elementList.first?.expression
    else {
      return expr
    }
    return replaceTrivia(
      on: visitedExpr,
      token: visitedExpr.lastToken,
      leadingTrivia: visitedTuple.leftParen.leadingTrivia,
      trailingTrivia: visitedTuple.rightParen.trailingTrivia
    )
  }

  public override func visit(_ node: IfStmtSyntax) -> StmtSyntax {
    let conditions = visit(node.conditions).as(ConditionElementListSyntax.self)!
    var result = node.withIfKeyword(node.ifKeyword.withOneTrailingSpace())
      .withConditions(conditions)
      .withBody(CodeBlockSyntax(visit(node.body)))
    if let elseBody = node.elseBody {
      result = result.withElseBody(visit(elseBody))
    }
    return StmtSyntax(result)
  }

  public override func visit(_ node: ConditionElementSyntax) -> Syntax {
    guard let tup = node.condition.as(TupleExprSyntax.self),
      tup.elementList.firstAndOnly != nil
    else {
      return super.visit(node)
    }
    return Syntax(node.withCondition(Syntax(extractExpr(tup))))
  }

  /// FIXME(hbh): Parsing for SwitchStmtSyntax is not implemented.
  public override func visit(_ node: SwitchStmtSyntax) -> StmtSyntax {
    guard let tup = node.expression.as(TupleExprSyntax.self),
      tup.elementList.firstAndOnly != nil
    else {
      return super.visit(node)
    }
    return StmtSyntax(
      node.withExpression(extractExpr(tup)).withCases(SwitchCaseListSyntax(visit(node.cases))))
  }

  public override func visit(_ node: RepeatWhileStmtSyntax) -> StmtSyntax {
    guard let tup = node.condition.as(TupleExprSyntax.self),
      tup.elementList.firstAndOnly != nil
    else {
      return super.visit(node)
    }
    let newNode = node.withCondition(extractExpr(tup))
      .withWhileKeyword(node.whileKeyword.withOneTrailingSpace())
      .withBody(CodeBlockSyntax(visit(node.body)))
    return StmtSyntax(newNode)
  }
}

extension Finding.Message {
  public static let removeParensAroundExpression: Finding.Message =
    "remove parentheses around this expression"
}
