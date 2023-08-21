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
public final class OmitReturns: SyntaxFormatRule {
  public override class var isOptIn: Bool { return true }

  public override func visit(_ node: FunctionDeclSyntax) -> DeclSyntax {
    let decl = super.visit(node)

    // func <name>() -> <Type> { return ... }
    if var funcDecl = decl.as(FunctionDeclSyntax.self),
       let body = funcDecl.body,
       let `return` = containsSingleReturn(body.statements) {
      funcDecl.body?.statements = unwrapReturnStmt(`return`)
      diagnose(.omitReturnStatement, on: `return`, severity: .refactoring)
      return DeclSyntax(funcDecl)
    }

    return decl
  }

  public override func visit(_ node: SubscriptDeclSyntax) -> DeclSyntax {
    let decl = super.visit(node)

    guard var `subscript` = decl.as(SubscriptDeclSyntax.self) else {
      return decl
    }

    if let accessorBlock = `subscript`.accessorBlock {
      // We are assuming valid Swift code here where only
      // one `get { ... }` is allowed.
      switch accessorBlock.accessors {
      case .accessors(let accessors):
        guard var getter = accessors.filter({
          $0.accessorSpecifier.tokenKind == .keyword(.get)
        }).first else {
          return decl
        }

        guard let body = getter.body,
              let `return` = containsSingleReturn(body.statements) else {
          return decl
        }

        guard let getterAt = accessors.firstIndex(where: {
          $0.accessorSpecifier.tokenKind == .keyword(.get)
        }) else {
          return decl
        }

        getter.body?.statements = unwrapReturnStmt(`return`)

        `subscript`.accessorBlock = .init(
            leadingTrivia: accessorBlock.leadingTrivia,
            leftBrace: accessorBlock.leftBrace,
            accessors: .accessors(accessors.with(\.[getterAt], getter)),
            rightBrace: accessorBlock.rightBrace,
            trailingTrivia: accessorBlock.trailingTrivia)

        diagnose(.omitReturnStatement, on: `return`, severity: .refactoring)

        return DeclSyntax(`subscript`)

      case .getter(let getter):
        guard let `return` = containsSingleReturn(getter) else {
          return decl
        }
        
        `subscript`.accessorBlock = .init(
            leadingTrivia: accessorBlock.leadingTrivia,
            leftBrace: accessorBlock.leftBrace,
            accessors: .getter(unwrapReturnStmt(`return`)),
            rightBrace: accessorBlock.rightBrace,
            trailingTrivia: accessorBlock.trailingTrivia)

        diagnose(.omitReturnStatement, on: `return`, severity: .refactoring)

        return DeclSyntax(`subscript`)
      }
    }

    return decl
  }

  public override func visit(_ node: ClosureExprSyntax) -> ExprSyntax {
    let expr = super.visit(node)

    // test { return ... }
    if var closure = expr.as(ClosureExprSyntax.self),
       let `return` = containsSingleReturn(closure.statements) {
       closure.statements = unwrapReturnStmt(`return`)
       diagnose(.omitReturnStatement, on: `return`, severity: .refactoring)
       return ExprSyntax(closure)
    }

    return expr
  }

  private func containsSingleReturn(_ body: CodeBlockItemListSyntax) -> ReturnStmtSyntax? {
    if let element = body.firstAndOnly?.as(CodeBlockItemSyntax.self),
       let ret = element.item.as(ReturnStmtSyntax.self),
       !ret.children(viewMode: .all).isEmpty, ret.expression != nil {
      return ret
    }

    return nil
  }

  private func unwrapReturnStmt(_ `return`: ReturnStmtSyntax) -> CodeBlockItemListSyntax {
    CodeBlockItemListSyntax([
      CodeBlockItemSyntax(
        leadingTrivia: `return`.leadingTrivia,
        item: .expr(`return`.expression!),
        semicolon: nil,
        trailingTrivia: `return`.trailingTrivia)
    ])
  }
}

extension Finding.Message {
  public static let omitReturnStatement: Finding.Message =
    "`return` can be omitted because body consists of a single expression"
}
