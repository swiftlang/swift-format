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

/// Assignment expressions must be their own statements.
///
/// Assignment should not be used in an expression context that expects a `Void` value. For example,
/// assigning a variable within a `return` statement existing a `Void` function is prohibited.
///
/// Lint: If an assignment expression is found in a position other than a standalone statement, a
///       lint finding is emitted.
///
/// Format: A `return` statement containing an assignment expression is expanded into two separate
///         statements.
public final class NoAssignmentInExpressions: SyntaxFormatRule {
  public override func visit(_ node: InfixOperatorExprSyntax) -> ExprSyntax {
    // Diagnose any assignment that isn't directly a child of a `CodeBlockItem` (which would be the
    // case if it was its own statement).
    if isAssignmentExpression(node) && node.parent?.is(CodeBlockItemSyntax.self) == false {
      diagnose(.moveAssignmentToOwnStatement, on: node)
    }
    return ExprSyntax(node)
  }

  public override func visit(_ node: CodeBlockItemListSyntax) -> CodeBlockItemListSyntax {
    var newItems = [CodeBlockItemSyntax]()
    newItems.reserveCapacity(node.count)

    for item in node {
      // Make sure to visit recursively so that any nested decls get processed first.
      let newItem = visit(item)

      // Rewrite any `return <assignment>` expressions as `<assignment><newline>return`.
      switch newItem.item {
      case .stmt(let stmt):
        guard
          let returnStmt = stmt.as(ReturnStmtSyntax.self),
          let assignmentExpr = assignmentExpression(from: returnStmt)
        else {
          // Head to the default case where we just keep the original item.
          fallthrough
        }

        // Move the leading trivia from the `return` statement to the new assignment statement,
        // since that's a more sensible place than between the two.
        newItems.append(
          CodeBlockItemSyntax(
            item: .expr(ExprSyntax(assignmentExpr)),
            semicolon: nil
          )
          .with(\.leadingTrivia, 
            (returnStmt.leadingTrivia ?? []) + (assignmentExpr.leadingTrivia ?? []))
          .with(\.trailingTrivia, []))
        newItems.append(
          CodeBlockItemSyntax(
            item: .stmt(StmtSyntax(returnStmt.with(\.expression, nil))),
            semicolon: nil
          )
          .with(\.leadingTrivia, [.newlines(1)])
          .with(\.trailingTrivia, returnStmt.trailingTrivia?.withoutLeadingSpaces() ?? []))

      default:
        newItems.append(newItem)
      }
    }

    return CodeBlockItemListSyntax(newItems)
  }

  /// Extracts and returns the assignment expression in the given `return` statement, if there was
  /// one.
  ///
  /// If the `return` statement did not have an expression or if its expression was not an
  /// assignment expression, nil is returned.
  private func assignmentExpression(from returnStmt: ReturnStmtSyntax) -> InfixOperatorExprSyntax? {
    guard
      let returnExpr = returnStmt.expression,
      let infixOperatorExpr = returnExpr.as(InfixOperatorExprSyntax.self)
    else {
      return nil
    }
    return isAssignmentExpression(infixOperatorExpr) ? infixOperatorExpr : nil
  }

  /// Returns a value indicating whether the given infix operator expression is an assignment
  /// expression (either simple assignment with `=` or compound assignment with an operator like
  /// `+=`).
  private func isAssignmentExpression(_ expr: InfixOperatorExprSyntax) -> Bool {
    if expr.operatorOperand.is(AssignmentExprSyntax.self) {
      return true
    }
    guard let binaryOp = expr.operatorOperand.as(BinaryOperatorExprSyntax.self) else {
      return false
    }
    return context.operatorTable.infixOperator(named: binaryOp.operatorToken.text)?.precedenceGroup
      == "AssignmentPrecedence"
  }
}

extension Finding.Message {
  public static let moveAssignmentToOwnStatement: Finding.Message =
    "move assignment expression into its own statement"
}
