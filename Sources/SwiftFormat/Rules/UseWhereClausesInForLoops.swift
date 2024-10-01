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

/// `for` loops that consist of a single `if` statement must use `where` clauses instead.
///
/// Lint: `for` loops that consist of a single `if` statement yield a lint error.
///
/// Format: `for` loops that consist of a single `if` statement have the conditional of that
///         statement factored out to a `where` clause.
@_spi(Rules)
public final class UseWhereClausesInForLoops: SyntaxFormatRule {

  /// Identifies this rule as being opt-in. This rule is experimental and not yet stable enough to
  /// be enabled by default.
  public override class var isOptIn: Bool { return true }

  public override func visit(_ node: ForStmtSyntax) -> StmtSyntax {
    // Extract IfStmt node if it's the only node in the function's body.
    guard !node.body.statements.isEmpty else { return StmtSyntax(node) }
    let firstStatement = node.body.statements.first!

    // Ignore for-loops with a `where` clause already.
    // TODO: Create an `&&` expression with both conditions?
    guard node.whereClause == nil else { return StmtSyntax(node) }

    // Match:
    //  - If the for loop has 1 statement, and it is an IfStmt, with a single
    //    condition.
    //  - If the for loop has 1 or more statement, and the first is a GuardStmt
    //    with a single condition whose body is just `continue`.
    switch firstStatement.item {
    case .stmt(let statement):
      return StmtSyntax(diagnoseAndUpdateForInStatement(firstStmt: statement, forInStmt: node))
    default:
      return StmtSyntax(node)
    }
  }

  private func diagnoseAndUpdateForInStatement(
    firstStmt: StmtSyntax,
    forInStmt: ForStmtSyntax
  ) -> ForStmtSyntax {
    switch Syntax(firstStmt).as(SyntaxEnum.self) {
    case .expressionStmt(let exprStmt):
      switch Syntax(exprStmt.expression).as(SyntaxEnum.self) {
      case .ifExpr(let ifExpr)
      where ifExpr.conditions.count == 1
        && ifExpr.elseKeyword == nil
        && forInStmt.body.statements.count == 1:
        // Extract the condition of the IfExpr.
        let conditionElement = ifExpr.conditions.first!
        guard let condition = conditionElement.condition.as(ExprSyntax.self) else {
          return forInStmt
        }
        diagnose(.useWhereInsteadOfIf, on: ifExpr)
        return updateWithWhereCondition(
          node: forInStmt,
          condition: condition,
          statements: ifExpr.body.statements
        )
      default:
        return forInStmt
      }
    case .guardStmt(let guardStmt)
    where guardStmt.conditions.count == 1
      && guardStmt.body.statements.count == 1
      && guardStmt.body.statements.first!.item.is(ContinueStmtSyntax.self):
      // Extract the condition of the GuardStmt.
      let conditionElement = guardStmt.conditions.first!
      guard let condition = conditionElement.condition.as(ExprSyntax.self) else {
        return forInStmt
      }
      diagnose(.useWhereInsteadOfGuard, on: guardStmt)
      return updateWithWhereCondition(
        node: forInStmt,
        condition: condition,
        statements: CodeBlockItemListSyntax(forInStmt.body.statements.dropFirst())
      )

    default:
      return forInStmt
    }
  }
}

fileprivate func updateWithWhereCondition(
  node: ForStmtSyntax,
  condition: ExprSyntax,
  statements: CodeBlockItemListSyntax
) -> ForStmtSyntax {
  // Construct a new `where` clause with the condition.
  let lastToken = node.sequence.lastToken(viewMode: .sourceAccurate)
  var whereLeadingTrivia = Trivia()
  if lastToken?.trailingTrivia.containsSpaces == false {
    whereLeadingTrivia = .spaces(1)
  }
  let whereKeyword = TokenSyntax.keyword(
    .where,
    leadingTrivia: whereLeadingTrivia,
    trailingTrivia: .spaces(1)
  )
  let whereClause = WhereClauseSyntax(
    whereKeyword: whereKeyword,
    condition: condition
  )

  // Replace the where clause and extract the body from the IfStmt.
  var result = node
  result.whereClause = whereClause
  result.body.statements = statements
  return result
}

extension Finding.Message {
  fileprivate static let useWhereInsteadOfIf: Finding.Message =
    "replace this 'if' statement with a 'where' clause"

  fileprivate static let useWhereInsteadOfGuard: Finding.Message =
    "replace this 'guard' statement with a 'where' clause"
}
