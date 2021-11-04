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

/// Function calls with no arguments and a trailing closure should not have empty parentheses.
///
/// Lint: If a function call with a trailing closure has an empty argument list with parentheses,
///       a lint error is raised.
///
/// Format: Empty parentheses in function calls with trailing closures will be removed.
public final class NoEmptyTrailingClosureParentheses: SyntaxFormatRule {

  public override func visit(_ node: FunctionCallExprSyntax) -> ExprSyntax {
    guard node.argumentList.count == 0 else { return super.visit(node) }

    guard let trailingClosure = node.trailingClosure,
      node.argumentList.isEmpty && node.leftParen != nil else
    {
      return super.visit(node)
    }
    guard let name = node.calledExpression.lastToken?.withoutTrivia() else {
      return super.visit(node)
    }

    diagnose(.removeEmptyTrailingParentheses(name: "\(name)"), on: node)

    // Need to visit `calledExpression` before creating a new node so that the location data (column
    // and line numbers) is available.
    guard let rewrittenCalledExpr = ExprSyntax(visit(Syntax(node.calledExpression))) else {
      return super.visit(node)
    }
    let formattedExp = replaceTrivia(
      on: rewrittenCalledExpr,
      token: rewrittenCalledExpr.lastToken,
      trailingTrivia: .spaces(1))
    let formattedClosure = visit(trailingClosure).as(ClosureExprSyntax.self)
    let result = node.withLeftParen(nil).withRightParen(nil).withCalledExpression(formattedExp)
      .withTrailingClosure(formattedClosure)
    return ExprSyntax(result)
  }
}

extension Finding.Message {
  public static func removeEmptyTrailingParentheses(name: String) -> Finding.Message {
    "remove '()' after \(name)"
  }
}
