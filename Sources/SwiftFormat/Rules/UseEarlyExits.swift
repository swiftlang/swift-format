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

/// Early exits should be used whenever possible.
///
/// This means that `if ... else { return/throw/break/continue }` constructs should be replaced by
/// `guard ... else { return/throw/break/continue }` constructs in order to keep indentation levels
/// low. Specifically, code of the following form:
///
/// ```swift
/// if condition {
///   trueBlock
/// } else {
///   falseBlock
///   return/throw/break/continue
/// }
/// ```
///
/// will be transformed into:
///
/// ```swift
/// guard condition else {
///   falseBlock
///   return/throw/break/continue
/// }
/// trueBlock
/// ```
///
/// Lint: `if ... else { return/throw/break/continue }` constructs will yield a lint error.
///
/// Format: `if ... else { return/throw/break/continue }` constructs will be replaced with
///         equivalent `guard ... else { return/throw/break/continue }` constructs.
@_spi(Rules)
public final class UseEarlyExits: SyntaxFormatRule {

  /// Identifies this rule as being opt-in. This rule is experimental and not yet stable enough to
  /// be enabled by default.
  public override class var isOptIn: Bool { return true }

  public override func visit(_ node: CodeBlockItemListSyntax) -> CodeBlockItemListSyntax {
    var newItems = [CodeBlockItemSyntax]()

    for codeBlockItem in node {
      // The `elseBody` of an `IfExprSyntax` will be a `CodeBlockSyntax` if it's an `else` block,
      // or another `IfExprSyntax` if it's an `else if` block. We only want to handle the former.
      guard
        let exprStmt = codeBlockItem.item.as(ExpressionStmtSyntax.self),
        let ifStatement = exprStmt.expression.as(IfExprSyntax.self),
        let elseBody = ifStatement.elseBody?.as(CodeBlockSyntax.self),
        codeBlockEndsWithEarlyExit(elseBody)
      else {
        newItems.append(visit(codeBlockItem))
        continue
      }

      diagnose(.useGuardStatement, on: ifStatement)

      let guardKeyword = TokenSyntax.keyword(
        .guard,
        leadingTrivia: ifStatement.ifKeyword.leadingTrivia,
        trailingTrivia: .spaces(1)
      )
      let guardStatement = GuardStmtSyntax(
        guardKeyword: guardKeyword,
        conditions: ifStatement.conditions,
        elseKeyword: TokenSyntax.keyword(.else, trailingTrivia: .spaces(1)),
        body: visit(elseBody)
      )

      newItems.append(CodeBlockItemSyntax(item: .stmt(StmtSyntax(guardStatement))))

      let trueBlock = visit(ifStatement.body)
      for trueStmt in trueBlock.statements {
        newItems.append(trueStmt)
      }
    }

    return CodeBlockItemListSyntax(newItems)
  }

  /// Returns true if the last statement in the given code block is one that will cause an early
  /// exit from the control flow construct or function.
  private func codeBlockEndsWithEarlyExit(_ codeBlock: CodeBlockSyntax) -> Bool {
    guard let lastStatement = codeBlock.statements.last else { return false }

    switch lastStatement.item {
    case .stmt(let stmt):
      switch Syntax(stmt).as(SyntaxEnum.self) {
      case .returnStmt, .throwStmt, .breakStmt, .continueStmt:
        return true
      default:
        return false
      }
    default:
      return false
    }
  }
}

extension Finding.Message {
  fileprivate static let useGuardStatement: Finding.Message =
    "replace this 'if/else' block with a 'guard' statement containing the early exit"
}
