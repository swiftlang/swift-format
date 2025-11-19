//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2025 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

public import SwiftSyntax

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
  public override func visit(_ node: IfExprSyntax) -> ExprSyntax {
    var result = node
    fixKeywordTrailingTrivia(&result.ifKeyword.trailingTrivia)
    result.conditions = visit(node.conditions)
    result.body = visit(node.body)
    if let elseBody = node.elseBody {
      result.elseBody = visit(elseBody)
    }
    return ExprSyntax(result)
  }

  public override func visit(_ node: ConditionElementSyntax) -> ConditionElementSyntax {
    guard
      case .expression(let condition) = node.condition,
      let newExpr = minimalSingleExpression(condition)
    else {
      return super.visit(node)
    }

    var result = node
    result.condition = .expression(newExpr)
    return result
  }

  public override func visit(_ node: GuardStmtSyntax) -> StmtSyntax {
    var result = node
    fixKeywordTrailingTrivia(&result.guardKeyword.trailingTrivia)
    result.conditions = visit(node.conditions)
    result.body = visit(node.body)
    return StmtSyntax(result)
  }

  public override func visit(_ node: SwitchExprSyntax) -> ExprSyntax {
    guard let newSubject = minimalSingleExpression(node.subject) else {
      return super.visit(node)
    }

    var result = node
    fixKeywordTrailingTrivia(&result.switchKeyword.trailingTrivia)
    result.subject = newSubject
    result.cases = visit(node.cases)
    return ExprSyntax(result)
  }

  public override func visit(_ node: RepeatStmtSyntax) -> StmtSyntax {
    guard let newCondition = minimalSingleExpression(node.condition) else {
      return super.visit(node)
    }

    var result = node
    fixKeywordTrailingTrivia(&result.whileKeyword.trailingTrivia)
    result.condition = newCondition
    result.body = visit(node.body)
    return StmtSyntax(result)
  }

  public override func visit(_ node: WhileStmtSyntax) -> StmtSyntax {
    var result = node
    fixKeywordTrailingTrivia(&result.whileKeyword.trailingTrivia)
    result.conditions = visit(node.conditions)
    result.body = visit(node.body)
    return StmtSyntax(result)
  }

  private func fixKeywordTrailingTrivia(_ trivia: inout Trivia) {
    guard trivia.isEmpty else { return }
    trivia = [.spaces(1)]
  }

  private func minimalSingleExpression(_ original: ExprSyntax) -> ExprSyntax? {
    guard
      let tuple = original.as(TupleExprSyntax.self),
      tuple.elements.count == 1,
      let expr = tuple.elements.first?.expression
    else {
      return nil
    }

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

    diagnose(.removeParensAroundExpression, on: tuple.leftParen)

    var visitedExpr = visit(expr)
    visitedExpr.leadingTrivia = tuple.leftParen.leadingTrivia
    visitedExpr.trailingTrivia = tuple.rightParen.trailingTrivia
    return visitedExpr
  }
}

extension Finding.Message {
  fileprivate static let removeParensAroundExpression: Finding.Message =
    "remove the parentheses around this expression"
}
