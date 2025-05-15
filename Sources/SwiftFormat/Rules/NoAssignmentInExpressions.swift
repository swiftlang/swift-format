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

/// Assignment expressions must be their own statements.
///
/// Assignment should not be used in an expression context that expects a `Void` value. For example,
/// assigning a variable within a `return` statement exiting a `Void` function is prohibited.
///
/// Lint: If an assignment expression is found in a position other than a standalone statement, a
///       lint finding is emitted.
///
/// Format: A `return` statement containing an assignment expression is expanded into two separate
///         statements.
@_spi(Rules)
public final class NoAssignmentInExpressions: SyntaxFormatRule {
  public override func visit(_ node: InfixOperatorExprSyntax) -> ExprSyntax {
    // Diagnose any assignment that isn't directly a child of a `CodeBlockItem` (which would be the
    // case if it was its own statement).
    if isAssignmentExpression(node)
      && !isStandaloneAssignmentStatement(node)
      && !isInAllowedFunction(node)
    {
      diagnose(.moveAssignmentToOwnStatement, on: node)
    }
    return ExprSyntax(node)
  }

  public override func visit(_ node: CodeBlockItemListSyntax) -> CodeBlockItemListSyntax {
    var newItems = [CodeBlockItemSyntax]()
    newItems.reserveCapacity(node.count)

    for item in node {
      // Make sure to visit recursively so that any nested decls get processed first.
      let visitedItem = visit(item)

      // Rewrite any `return <assignment>` expressions as `<assignment><newline>return`.
      switch visitedItem.item {
      case .stmt(let stmt):
        guard
          var returnStmt = stmt.as(ReturnStmtSyntax.self),
          let assignmentExpr = assignmentExpression(from: returnStmt)
        else {
          // Head to the default case where we just keep the original item.
          fallthrough
        }

        // Move the leading trivia from the `return` statement to the new assignment statement,
        // since that's a more sensible place than between the two.
        var assignmentItem = CodeBlockItemSyntax(item: .expr(ExprSyntax(assignmentExpr)))
        assignmentItem.leadingTrivia =
          returnStmt.leadingTrivia
          + returnStmt.returnKeyword.trailingTrivia.withoutLeadingSpaces()
          + assignmentExpr.leadingTrivia
        assignmentItem.trailingTrivia = []

        let trailingTrivia = returnStmt.trailingTrivia
        returnStmt.expression = nil
        returnStmt.returnKeyword.trailingTrivia = []
        var returnItem = CodeBlockItemSyntax(item: .stmt(StmtSyntax(returnStmt)))
        returnItem.leadingTrivia = [.newlines(1)]
        returnItem.trailingTrivia = trailingTrivia

        newItems.append(assignmentItem)
        newItems.append(returnItem)

      default:
        newItems.append(visitedItem)
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
    if expr.operator.is(AssignmentExprSyntax.self) {
      return true
    }
    guard let binaryOp = expr.operator.as(BinaryOperatorExprSyntax.self) else {
      return false
    }
    return context.operatorTable.infixOperator(named: binaryOp.operator.text)?.precedenceGroup
      == "AssignmentPrecedence"
  }

  /// Returns a value indicating whether the given node is a standalone assignment statement.
  ///
  /// This function considers try/await/unsafe expressions and automatically walks up through them
  /// as needed. This is because `try f().x = y` should still be a standalone assignment for our
  /// purposes, even though a `TryExpr` will wrap the `InfixOperatorExpr` and thus would not be
  /// considered a standalone assignment if we only checked the infix expression for a
  /// `CodeBlockItem` parent.
  private func isStandaloneAssignmentStatement(_ node: InfixOperatorExprSyntax) -> Bool {
    var node = Syntax(node)
    while let parent = node.parent,
      parent.is(TryExprSyntax.self) || parent.is(AwaitExprSyntax.self) || parent.is(UnsafeExprSyntax.self)
    {
      node = parent
    }

    guard let parent = node.parent else {
      // This shouldn't happen under normal circumstances (i.e., unless the expression is detached
      // from the rest of a tree). In that case, we may as well consider it to be "standalone".
      return true
    }
    return parent.is(CodeBlockItemSyntax.self)
  }

  /// Returns true if the infix operator expression is in the (non-closure) parameters of an allowed
  /// function call.
  private func isInAllowedFunction(_ node: InfixOperatorExprSyntax) -> Bool {
    let allowedFunctions = context.configuration.noAssignmentInExpressions.allowedFunctions
    // Walk up the tree until we find a FunctionCallExprSyntax, and if the name matches, return
    // true. However, stop early if we hit a CodeBlockItemSyntax first; this would represent a
    // closure context where we *don't* want the exception to apply (for example, in
    // `someAllowedFunction(a, b) { return c = d }`, the `c = d` is a descendent of a function call
    // but we want it to be evaluated in its own context.
    var node = Syntax(node)
    while let parent = node.parent {
      node = parent
      if node.is(CodeBlockItemSyntax.self) {
        break
      }
      if let functionCallExpr = node.as(FunctionCallExprSyntax.self),
        allowedFunctions.contains(functionCallExpr.calledExpression.trimmedDescription)
      {
        return true
      }
    }
    return false
  }
}

extension Finding.Message {
  fileprivate static let moveAssignmentToOwnStatement: Finding.Message =
    "move this assignment expression into its own statement"
}
