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

/// Every variable bound in a `case` pattern must have its own `let/var`.
///
/// For example, `case let .identifier(x, y)` is forbidden. Use
/// `case .identifier(let x, let y)` instead.
///
/// Lint: `case let .identifier(...)` will yield a lint error.
///
/// Format: `case let .identifier(x, y)` will be replaced by
/// `case .identifier(let x, let y)`.
@_spi(Rules)
public final class UseLetInEveryBoundCaseVariable: SyntaxFormatRule {
  public override func visit(_ node: MatchingPatternConditionSyntax) -> MatchingPatternConditionSyntax {
    if let (replacement, specifier) = distributeLetVarThroughPattern(node.pattern) {
      diagnose(.useLetInBoundCaseVariables(specifier), on: node.pattern)

      var result = node
      result.pattern = PatternSyntax(replacement)
      return result
    }

    return super.visit(node)
  }

  public override func visit(_ node: SwitchCaseItemSyntax) -> SwitchCaseItemSyntax {
    if let (replacement, specifier) = distributeLetVarThroughPattern(node.pattern) {
      diagnose(.useLetInBoundCaseVariables(specifier), on: node.pattern)

      var result = node
      result.pattern = PatternSyntax(replacement)
      result.leadingTrivia = node.leadingTrivia
      return result
    }

    return super.visit(node)
  }

  public override func visit(_ node: ForStmtSyntax) -> StmtSyntax {
    guard node.caseKeyword != nil else {
      return super.visit(node)
    }

    if let (replacement, specifier) = distributeLetVarThroughPattern(node.pattern) {
      diagnose(.useLetInBoundCaseVariables(specifier), on: node.pattern)

      var result = node
      result.pattern = PatternSyntax(replacement)
      return StmtSyntax(result)
    }

    return super.visit(node)
  }
}

extension UseLetInEveryBoundCaseVariable {
  private enum OptionalPatternKind {
    case chained
    case forced
  }

  /// Wraps the given expression in the optional chaining and/or force
  /// unwrapping expressions, as described by the specified stack.
  private func restoreOptionalChainingAndForcing(
    _ expr: ExprSyntax,
    patternStack: [(OptionalPatternKind, Trivia)]
  ) -> ExprSyntax {
    var patternStack = patternStack
    var result = expr

    // As we unwind the stack, wrap the expression in optional chaining
    // or force unwrap expressions.
    while let (kind, trivia) = patternStack.popLast() {
      if kind == .chained {
        result = ExprSyntax(
          OptionalChainingExprSyntax(
            expression: result,
            trailingTrivia: trivia
          )
        )
      } else {
        result = ExprSyntax(
          ForceUnwrapExprSyntax(
            expression: result,
            trailingTrivia: trivia
          )
        )
      }
    }

    return result
  }

  /// Returns a rewritten version of the given pattern if bindings can be moved
  /// into bound cases.
  ///
  /// - Parameter pattern: The pattern to rewrite.
  /// - Returns: An optional tuple with the rewritten pattern and the binding
  ///   specifier used in `pattern`, for use in the diagnostic. If `pattern`
  ///   doesn't qualify for distributing the binding, then the result is `nil`.
  private func distributeLetVarThroughPattern(
    _ pattern: PatternSyntax
  ) -> (ExpressionPatternSyntax, TokenSyntax)? {
    guard let bindingPattern = pattern.as(ValueBindingPatternSyntax.self),
      let exprPattern = bindingPattern.pattern.as(ExpressionPatternSyntax.self)
    else { return nil }

    // Grab the `let` or `var` used in the binding pattern.
    var specifier = bindingPattern.bindingSpecifier
    specifier.leadingTrivia = []
    let identifierBinder = BindIdentifiersRewriter(bindingSpecifier: specifier)

    // Drill down into any optional patterns that we encounter (e.g., `case let .foo(x)?`).
    var patternStack: [(OptionalPatternKind, Trivia)] = []
    var expression = exprPattern.expression
    while true {
      if let optionalExpr = expression.as(OptionalChainingExprSyntax.self) {
        expression = optionalExpr.expression
        patternStack.append((.chained, optionalExpr.questionMark.trailingTrivia))
      } else if let forcedExpr = expression.as(ForceUnwrapExprSyntax.self) {
        expression = forcedExpr.expression
        patternStack.append((.forced, forcedExpr.exclamationMark.trailingTrivia))
      } else {
        break
      }
    }

    // Enum cases are written as function calls on member access expressions. The arguments
    // are the associated values, so the `let/var` can be distributed into those.
    if var functionCall = expression.as(FunctionCallExprSyntax.self),
      functionCall.calledExpression.is(MemberAccessExprSyntax.self)
    {
      var result = exprPattern
      let newArguments = identifierBinder.rewrite(functionCall.arguments)
      functionCall.arguments = newArguments.as(LabeledExprListSyntax.self)!
      result.expression = restoreOptionalChainingAndForcing(
        ExprSyntax(functionCall),
        patternStack: patternStack
      )
      return (result, specifier)
    }

    // A tuple expression can have the `let/var` distributed into the elements.
    if var tupleExpr = expression.as(TupleExprSyntax.self) {
      var result = exprPattern
      let newElements = identifierBinder.rewrite(tupleExpr.elements)
      tupleExpr.elements = newElements.as(LabeledExprListSyntax.self)!
      result.expression = restoreOptionalChainingAndForcing(
        ExprSyntax(tupleExpr),
        patternStack: patternStack
      )
      return (result, specifier)
    }

    // Otherwise, we're not sure this is a pattern we can distribute through.
    return nil
  }
}

extension Finding.Message {
  fileprivate static func useLetInBoundCaseVariables(
    _ specifier: TokenSyntax
  ) -> Finding.Message {
    "move this '\(specifier.text)' keyword inside the 'case' pattern, before each of the bound variables"
  }
}

/// A syntax rewriter that converts identifier patterns to bindings
/// with the given specifier.
private final class BindIdentifiersRewriter: SyntaxRewriter {
  var bindingSpecifier: TokenSyntax

  init(bindingSpecifier: TokenSyntax) {
    self.bindingSpecifier = bindingSpecifier
  }

  override func visit(_ node: PatternExprSyntax) -> ExprSyntax {
    guard let identifier = node.pattern.as(IdentifierPatternSyntax.self) else {
      return super.visit(node)
    }

    let binding = ValueBindingPatternSyntax(
      bindingSpecifier: bindingSpecifier,
      pattern: identifier
    )
    var result = node
    result.pattern = PatternSyntax(binding)
    return ExprSyntax(result)
  }
}
