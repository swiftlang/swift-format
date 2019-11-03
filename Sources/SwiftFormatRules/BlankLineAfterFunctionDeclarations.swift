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

/// At least one blank line after each function declaration.
///
/// Optionally, single-line functions and/or `super` calls on the first line can be ignored.
///
/// This rule does not check the maximum number of blank lines; the pretty printer clamps those
/// as needed.
///
/// Lint: If there are no blank lines after a function declaration, a lint error is raised.
///
/// Format: Function declarations with no initial blank line will have a blank line inserted.
///
/// Configuration:
///  - blankLineAfterFunctionDeclarations.ignoreSingleLineFunctions
///  - blankLineAfterFunctionDeclarations.ignoreSuperCallsOnFirstLine
public final class BlankLineAfterFunctionDeclarations: SyntaxFormatRule {

  public override func visit(_ node: FunctionDeclSyntax) -> DeclSyntax {
    guard var body = node.body else { return super.visit(node) }

    var leadingIndentation: Trivia = []

    // handle single line functions
    if body.isSingleLine(includingLeadingComment: true, sourceLocationConverter: context.sourceLocationConverter) {

      guard context.configuration.blankLineAfterFunctionDeclarations.ignoreSingleLineFunctions == false else {
        return super.visit(node)
      }

      let nodeIndentation: Trivia = node.leadingTrivia?.withSpacesOnly() ?? []
      leadingIndentation = nodeIndentation + context.configuration.indentation.asTrivia

      // remove the trailing whitespace after the `{`
      let leftBrace = body.leftBrace.withTrailingTrivia(body.leftBrace.trailingTrivia.withoutSpaces())

      // add newline and node indentation before the `}`
      let rightBrace = body.rightBrace.withLeadingTrivia(.newlines(1) + nodeIndentation + body.rightBrace.leadingTrivia)

      body = body.withLeftBrace(leftBrace).withRightBrace(rightBrace)

      // obtain the last token which has the last trailing trivia before the right brace
      guard let lastToken = body.statements.lastToken else { return super.visit(node) }

      // removeg any trailing whitespace from last statement
      body = replaceTrivia(
        on: body,
        token: lastToken,
        trailingTrivia: lastToken.trailingTrivia.withoutSpaces()
      ) as! CodeBlockSyntax
    }

    // obtain the first token which has the first leading trivia after the left brace (i.e. first newlines)
    guard let firstStatement = body.statements.first, let firstToken = body.statements.firstToken else {
      return super.visit(node)
    }

    // ignore super calls on first line
    if context.configuration.blankLineAfterFunctionDeclarations.ignoreSuperCallsOnFirstLine,
      firstToken.tokenKind == .superKeyword,
      firstToken.leadingTrivia.numberOfLeadingNewlines == 1,
      let functionCallExpr = body.statements.first?.item as? FunctionCallExprSyntax,
      let memberAccessExpr = functionCallExpr.calledExpression as? MemberAccessExprSyntax,
      let _ = memberAccessExpr.base as? SuperRefExprSyntax,
      memberAccessExpr.name.text == node.identifier.text
    {
      // we could compare function call arguments vs function signature parameters
      // (i.e.: `functionCallExpr.argumentList` vs `node.signature.input.parameterList`)
      // but it could introduce some edge cases with default parameter values, so we just use identifiers
      return node.withBody(visitNestedStatements(of: body, skippingFirst: firstStatement))
    }

    // ignore if newlines are already correct (2 => one after signature's `{` plus an empty one)
    guard firstToken.leadingTrivia.numberOfLeadingNewlines != 2 else {
      return node.withBody(visitNestedStatements(of: body, skippingFirst: firstStatement))
    }

    diagnose(.addBlankLineAfterFunctionDeclaration, on: firstToken)

    let newFirstStatement = replaceTrivia(
      on: firstStatement,
      token: firstToken,
      leadingTrivia: .newlines(2) + leadingIndentation + firstToken.leadingTrivia.withoutLeadingNewlines()
    ) as! CodeBlockItemSyntax

    return node.withBody(visitNestedStatements(of: body, skippingFirst: newFirstStatement))
  }

  /// Recursively ensures all nested statements follow the BlankLineBetweenMembers rule except the first, assuming it
  /// is already handled (by the main rule body).
  func visitNestedStatements(
    of body: CodeBlockSyntax,
    skippingFirst first: CodeBlockItemSyntax
  ) -> CodeBlockSyntax {
    let newStatements = [first] + body.statements.dropFirst().map { visit($0) as! CodeBlockItemSyntax }
    return body.withStatements(SyntaxFactory.makeCodeBlockItemList(newStatements))
  }
}

extension Diagnostic.Message {
  static let addBlankLineAfterFunctionDeclaration = Diagnostic.Message(
    .warning, "add one blank line after declarations"
  )
}
