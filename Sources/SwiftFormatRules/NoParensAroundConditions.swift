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

    diagnose(.removeParensAroundExpression, on: expr) {
      $0.highlight(expr.sourceRange(converter: self.context.sourceLocationConverter))
    }

    return replaceTrivia(
      on: expr,
      token: expr.lastToken,
      leadingTrivia: tuple.leftParen.leadingTrivia,
      trailingTrivia: tuple.rightParen.trailingTrivia
    )
  }

  public override func visit(_ node: IfStmtSyntax) -> StmtSyntax {
    let conditions = visit(node.conditions).as(ConditionElementListSyntax.self)!
    let result = node.withIfKeyword(node.ifKeyword.withOneTrailingSpace())
      .withConditions(conditions)
    return StmtSyntax(result)
  }

  public override func visit(_ node: ConditionElementSyntax) -> Syntax {
    guard let tup = node.condition.as(TupleExprSyntax.self),
      tup.elementList.firstAndOnly != nil
    else {
      return Syntax(node)
    }
    return Syntax(node.withCondition(Syntax(extractExpr(tup))))
  }

  /// FIXME(hbh): Parsing for SwitchStmtSyntax is not implemented.
  public override func visit(_ node: SwitchStmtSyntax) -> StmtSyntax {
    guard let tup = node.expression.as(TupleExprSyntax.self),
      tup.elementList.firstAndOnly != nil
    else {
      return StmtSyntax(node)
    }
    return StmtSyntax(node.withExpression(extractExpr(tup)))
  }

  public override func visit(_ node: RepeatWhileStmtSyntax) -> StmtSyntax {
    guard let tup = node.condition.as(TupleExprSyntax.self),
      tup.elementList.firstAndOnly != nil
    else {
      return StmtSyntax(node)
    }
    let newNode = node.withCondition(extractExpr(tup))
      .withWhileKeyword(node.whileKeyword.withOneTrailingSpace())
    return StmtSyntax(newNode)
  }
}

extension Diagnostic.Message {
  public static let removeParensAroundExpression = Diagnostic.Message(
    .warning, "remove parentheses around this expression")
}
