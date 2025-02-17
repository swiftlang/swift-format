//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2023 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import SwiftSyntax

/// Single-expression functions, closures, subscripts can omit `return` statement.
///
/// Lint: `func <name>() { return ... }` and similar single expression constructs will yield a lint error.
///
/// Format: `func <name>() { return ... }` constructs will be replaced with
///         equivalent `func <name>() { ... }` constructs.
@_spi(Rules)
public final class OmitExplicitReturns: SyntaxFormatRule {
  public override class var isOptIn: Bool { return true }

  public override func visit(_ node: FunctionDeclSyntax) -> DeclSyntax {
    let decl = super.visit(node)

    // func <name>() -> <Type> { return ... }
    guard var funcDecl = decl.as(FunctionDeclSyntax.self),
      let body = funcDecl.body,
      let returnStmt = containsSingleReturn(body.statements)
    else {
      return decl
    }

    funcDecl.body?.statements = rewrapReturnedExpression(returnStmt)
    diagnose(.omitReturnStatement, on: returnStmt, severity: .refactoring)
    return DeclSyntax(funcDecl)
  }

  public override func visit(_ node: SubscriptDeclSyntax) -> DeclSyntax {
    let decl = super.visit(node)

    guard var subscriptDecl = decl.as(SubscriptDeclSyntax.self),
      let accessorBlock = subscriptDecl.accessorBlock,
      // We are assuming valid Swift code here where only
      // one `get { ... }` is allowed.
      let transformed = transformAccessorBlock(accessorBlock)
    else {
      return decl
    }

    subscriptDecl.accessorBlock = transformed
    return DeclSyntax(subscriptDecl)
  }

  public override func visit(_ node: PatternBindingSyntax) -> PatternBindingSyntax {
    var binding = node

    guard let accessorBlock = binding.accessorBlock,
      let transformed = transformAccessorBlock(accessorBlock)
    else {
      return super.visit(node)
    }

    binding.accessorBlock = transformed
    return binding
  }

  public override func visit(_ node: ClosureExprSyntax) -> ExprSyntax {
    let expr = super.visit(node)

    // test { return ... }
    guard var closureExpr = expr.as(ClosureExprSyntax.self),
      let returnStmt = containsSingleReturn(closureExpr.statements)
    else {
      return expr
    }

    closureExpr.statements = rewrapReturnedExpression(returnStmt)
    diagnose(.omitReturnStatement, on: returnStmt, severity: .refactoring)
    return ExprSyntax(closureExpr)
  }

  private func transformAccessorBlock(_ accessorBlock: AccessorBlockSyntax) -> AccessorBlockSyntax? {
    // We are assuming valid Swift code here where only
    // one `get { ... }` is allowed.
    switch accessorBlock.accessors {
    case .accessors(var accessors):
      guard
        var getter = accessors.filter({
          $0.accessorSpecifier.tokenKind == .keyword(.get)
        }).first
      else {
        return nil
      }

      guard let body = getter.body,
        let returnStmt = containsSingleReturn(body.statements)
      else {
        return nil
      }

      guard
        let getterAt = accessors.firstIndex(where: {
          $0.accessorSpecifier.tokenKind == .keyword(.get)
        })
      else {
        return nil
      }

      getter.body?.statements = rewrapReturnedExpression(returnStmt)

      diagnose(.omitReturnStatement, on: returnStmt, severity: .refactoring)

      accessors[getterAt] = getter
      var newBlock = accessorBlock
      newBlock.accessors = .accessors(accessors)
      return newBlock

    case .getter(let getter):
      guard let returnStmt = containsSingleReturn(getter) else {
        return nil
      }

      diagnose(.omitReturnStatement, on: returnStmt, severity: .refactoring)

      var newBlock = accessorBlock
      newBlock.accessors = .getter(rewrapReturnedExpression(returnStmt))
      return newBlock
    }
  }

  private func containsSingleReturn(_ body: CodeBlockItemListSyntax) -> ReturnStmtSyntax? {
    guard let element = body.firstAndOnly,
      let returnStmt = element.item.as(ReturnStmtSyntax.self)
    else {
      return nil
    }

    return !returnStmt.children(viewMode: .all).isEmpty && returnStmt.expression != nil ? returnStmt : nil
  }

  private func rewrapReturnedExpression(_ returnStmt: ReturnStmtSyntax) -> CodeBlockItemListSyntax {
    CodeBlockItemListSyntax([
      CodeBlockItemSyntax(
        leadingTrivia: returnStmt.leadingTrivia,
        item: .expr(returnStmt.expression!.detached.with(\.trailingTrivia, [])),
        semicolon: nil,
        trailingTrivia: returnStmt.trailingTrivia
      )
    ])
  }
}

extension Finding.Message {
  fileprivate static let omitReturnStatement: Finding.Message =
    "'return' can be omitted because body consists of a single expression"
}
