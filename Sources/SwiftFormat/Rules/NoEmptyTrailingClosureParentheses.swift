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

/// Function calls with no arguments and a trailing closure should not have empty parentheses.
///
/// Lint: If a function call with a trailing closure has an empty argument list with parentheses,
///       a lint error is raised.
///
/// Format: Empty parentheses in function calls with trailing closures will be removed.
@_spi(Rules)
public final class NoEmptyTrailingClosureParentheses: SyntaxFormatRule {

  public override func visit(_ node: FunctionCallExprSyntax) -> ExprSyntax {
    guard node.arguments.count == 0 else { return super.visit(node) }

    guard let trailingClosure = node.trailingClosure,
      node.arguments.isEmpty && node.leftParen != nil else
    {
      return super.visit(node)
    }
    guard let name = node.calledExpression.lastToken(viewMode: .sourceAccurate) else {
      return super.visit(node)
    }

    diagnose(.removeEmptyTrailingParentheses(name: "\(name.trimmedDescription)"), on: node)

    // Need to visit `calledExpression` before creating a new node so that the location data (column
    // and line numbers) is available.
    guard var rewrittenCalledExpr = ExprSyntax(rewrite(Syntax(node.calledExpression))) else {
      return super.visit(node)
    }
    rewrittenCalledExpr.trailingTrivia = [.spaces(1)]

    var result = node
    result.leftParen = nil
    result.rightParen = nil
    result.calledExpression = rewrittenCalledExpr
    result.trailingClosure = rewrite(trailingClosure).as(ClosureExprSyntax.self)
    return ExprSyntax(result)
  }
}

extension Finding.Message {
  @_spi(Rules)
  public static func removeEmptyTrailingParentheses(name: String) -> Finding.Message {
    "remove the empty parentheses following '\(name)'"
  }
}
