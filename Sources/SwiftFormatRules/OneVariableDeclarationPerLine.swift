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

import Foundation
import SwiftFormatCore
import SwiftSyntax

/// Each variable declaration, with the exception of tuple destructuring, should declare 1 variable.
///
/// Lint: If a variable declaration declares multiple variables, a lint error is raised.
///
/// Format: If a variable declaration declares multiple variables, it will be split into multiple
///         declarations, each declaring one of the variables.
///
/// - SeeAlso: https://google.github.io/swift#properties
public final class OneVariableDeclarationPerLine: SyntaxFormatRule {
  func splitVariableDecls(
    _ items: CodeBlockItemListSyntax
  ) -> CodeBlockItemListSyntax? {

    // If we're here, then there's at least one VariableDeclSyntax that
    // needs to be split.

    var needsWork = false
    for codeBlockItem in items {
      if let varDecl = codeBlockItem.item as? VariableDeclSyntax, varDecl.bindings.count > 1 {
        needsWork = true
      }
    }
    if !needsWork { return nil }

    var newItems = [CodeBlockItemSyntax]()
    for codeBlockItem in items {
      // If we're not looking at a VariableDecl with more than 1 binding, visit the item and
      // skip it.
      guard let varDecl = codeBlockItem.item as? VariableDeclSyntax,
        varDecl.bindings.count > 1
      else {
        newItems.append(codeBlockItem)
        continue
      }

      diagnose(.onlyOneVariableDeclaration, on: varDecl)

      // The first binding corresponds to the original `var`/`let`
      // declaration, so it should not have its trivia replaced.
      var isFirst = true
      for binding in varDecl.bindings {
        let newBinding = binding.withTrailingComma(nil)
        let newDecl = varDecl.withBindings(
          SyntaxFactory.makePatternBindingList([newBinding]))
        var finalDecl: Syntax = newDecl
        // Only add a newline if this is a brand new binding.
        if !isFirst {
          let firstTok = newDecl.firstToken
          let origLeading = firstTok?.leadingTrivia.withoutNewlines() ?? []
          finalDecl = replaceTrivia(
            on: finalDecl,
            token: newDecl.firstToken,
            leadingTrivia: .newlines(1) + origLeading
          )
        }
        let newCodeBlockItem = codeBlockItem.withItem(finalDecl)
        newItems.append(newCodeBlockItem)
        isFirst = false
      }
    }
    return SyntaxFactory.makeCodeBlockItemList(newItems)
  }

  public override func visit(_ node: CodeBlockSyntax) -> Syntax {
    guard let newStmts = splitVariableDecls(node.statements) else {
      return super.visit(node)
    }
    return node.withStatements(newStmts)
  }

  public override func visit(_ node: ClosureExprSyntax) -> ExprSyntax {
    guard let newStmts = splitVariableDecls(node.statements) else {
      return super.visit(node)
    }
    return node.withStatements(newStmts)
  }

  public override func visit(_ node: SourceFileSyntax) -> Syntax {
    guard let newStmts = splitVariableDecls(node.statements) else {
      return super.visit(node)
    }
    return node.withStatements(newStmts)
  }
}

extension Diagnostic.Message {
  static let onlyOneVariableDeclaration = Diagnostic.Message(
    .warning,
    "split variable binding into multiple declarations"
  )
}
