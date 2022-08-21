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

/// `for` loops that consist of a single `if` statement must use `where` clauses instead.
///
/// Lint: `for` loops that consist of a single `if` statement yield a lint error.
///
/// Format: `for` loops that consist of a single `if` statement have the conditional of that
///         statement factored out to a `where` clause.
public final class UseWhereClausesInForLoops: SyntaxFormatRule {

  /// Identifies this rule as being opt-in. This rule is experimental and not yet stable enough to
  /// be enabled by default.
  public override class var isOptIn: Bool { return true }

  public override func visit(_ node: ForInStmtSyntax) -> StmtSyntax {
    // Extract IfStmt node if it's the only node in the function's body.
    guard !node.body.statements.isEmpty else { return StmtSyntax(node) }
    let stmt = node.body.statements.first!

    // Ignore for-loops with a `where` clause already.
    // FIXME: Create an `&&` expression with both conditions?
    guard node.whereClause == nil else { return StmtSyntax(node) }

    // Match:
    //  - If the for loop has 1 statement, and it is an IfStmt, with a single
    //    condition.
    //  - If the for loop has 1 or more statement, and the first is a GuardStmt
    //    with a single condition whose body is just `continue`.
    switch stmt.item.as(SyntaxEnum.self) {
    case .ifStmt(let ifStmt)
    where ifStmt.conditions.count == 1 && ifStmt.elseKeyword == nil
      && node.body.statements.count == 1:
      // Extract the condition of the IfStmt.
      let conditionElement = ifStmt.conditions.first!
      guard let condition = conditionElement.condition.as(ExprSyntax.self) else {
        return StmtSyntax(node)
      }
      diagnose(.useWhereInsteadOfIf, on: ifStmt)
      let result = updateWithWhereCondition(
        node: node,
        condition: condition,
        statements: ifStmt.body.statements
      )
      return StmtSyntax(result)
    case .guardStmt(let guardStmt)
    where guardStmt.conditions.count == 1 && guardStmt.body.statements.count == 1 && guardStmt.body
      .statements.first!.item.is(ContinueStmtSyntax.self):
      // Extract the condition of the GuardStmt.
      let conditionElement = guardStmt.conditions.first!
      guard let condition = conditionElement.condition.as(ExprSyntax.self) else {
        return StmtSyntax(node)
      }
      diagnose(.useWhereInsteadOfGuard, on: guardStmt)
      let result = updateWithWhereCondition(
        node: node,
        condition: condition,
        statements: node.body.statements.removingFirst()
      )
      return StmtSyntax(result)
    default:
      return StmtSyntax(node)
    }
  }
}

fileprivate func updateWithWhereCondition(
  node: ForInStmtSyntax,
  condition: ExprSyntax,
  statements: CodeBlockItemListSyntax
) -> ForInStmtSyntax {
  // Construct a new `where` clause with the condition.
  let lastToken = node.sequenceExpr.lastToken
  var whereLeadingTrivia = Trivia()
  if lastToken?.trailingTrivia.containsSpaces == false {
    whereLeadingTrivia = .spaces(1)
  }
  let whereKeyword = TokenSyntax.whereKeyword(
    leadingTrivia: whereLeadingTrivia,
    trailingTrivia: .spaces(1)
  )
  let whereClause = WhereClauseSyntax(
    whereKeyword: whereKeyword,
    guardResult: condition
  )

  // Replace the where clause and extract the body from the IfStmt.
  let newBody = node.body.withStatements(statements)
  return node.withWhereClause(whereClause).withBody(newBody)
}

extension Finding.Message {
  public static let useWhereInsteadOfIf: Finding.Message =
    "replace this 'if' statement with a 'where' clause"

  public static let useWhereInsteadOfGuard: Finding.Message =
    "replace this 'guard' statement with a 'where' clause"
}
