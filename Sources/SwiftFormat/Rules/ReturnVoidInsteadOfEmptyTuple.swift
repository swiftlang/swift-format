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

/// Return `Void`, not `()`, in signatures.
///
/// Note that this rule does *not* apply to function declaration signatures in order to avoid
/// conflicting with `NoVoidReturnOnFunctionSignature`.
///
/// Lint: Returning `()` in a signature yields a lint error.
///
/// Format: `-> ()` is replaced with `-> Void`
@_spi(Rules)
public final class ReturnVoidInsteadOfEmptyTuple: SyntaxFormatRule {
  public override func visit(_ node: FunctionTypeSyntax) -> TypeSyntax {
    guard let returnType = node.returnClause.type.as(TupleTypeSyntax.self),
      returnType.elements.count == 0
    else {
      return super.visit(node)
    }

    diagnose(.returnVoid, on: returnType)

    // If the user has put non-whitespace trivia inside the empty tuple, like a comment, then we
    // still diagnose it as a lint error but we don't replace it because it's not obvious where the
    // comment should go.
    if hasNonWhitespaceTrivia(returnType.leftParen, at: .trailing)
      || hasNonWhitespaceTrivia(returnType.rightParen, at: .leading)
    {
      return super.visit(node)
    }

    // Make sure that function types nested in the parameter list are also rewritten (for example,
    // `(Int -> ()) -> ()` should become `(Int -> Void) -> Void`).
    let parameters = visit(node.parameters)
    let voidKeyword = makeVoidIdentifierType(toReplace: returnType)
    var rewrittenNode = node
    rewrittenNode.parameters = parameters
    rewrittenNode.returnClause.type = TypeSyntax(voidKeyword)
    return TypeSyntax(rewrittenNode)
  }

  public override func visit(_ node: ClosureSignatureSyntax) -> ClosureSignatureSyntax {
    guard
      let returnClause = node.returnClause,
      let returnType = returnClause.type.as(TupleTypeSyntax.self),
      returnType.elements.count == 0
    else {
      return super.visit(node)
    }

    diagnose(.returnVoid, on: returnType)

    // If the user has put non-whitespace trivia inside the empty tuple, like a comment, then we
    // still diagnose it as a lint error but we don't replace it because it's not obvious where the
    // comment should go.
    if hasNonWhitespaceTrivia(returnType.leftParen, at: .trailing)
      || hasNonWhitespaceTrivia(returnType.rightParen, at: .leading)
    {
      return super.visit(node)
    }

    let closureParameterClause: ClosureSignatureSyntax.ParameterClause?
    switch node.parameterClause {
    case .parameterClause(let parameterClause)?:
      // If the closure input is a complete parameter clause (variables and types), make sure that
      // nested function types are also rewritten (for example, `label: (Int -> ()) -> ()` should
      // become `label: (Int -> Void) -> Void`).
      closureParameterClause = .parameterClause(visit(parameterClause))
    default:
      // Otherwise, it's a simple signature (just variable names, no types), so there is nothing to
      // rewrite.
      closureParameterClause = node.parameterClause
    }
    let voidKeyword = makeVoidIdentifierType(toReplace: returnType)

    var newReturnClause = returnClause
    newReturnClause.type = TypeSyntax(voidKeyword)

    var result = node
    result.parameterClause = closureParameterClause
    result.returnClause = newReturnClause
    return result
  }

  /// Returns a value indicating whether the leading trivia of the given token contained any
  /// non-whitespace pieces.
  private func hasNonWhitespaceTrivia(_ token: TokenSyntax, at position: TriviaPosition) -> Bool {
    for piece in position == .leading ? token.leadingTrivia : token.trailingTrivia {
      switch piece {
      case .blockComment, .docBlockComment, .docLineComment, .unexpectedText, .lineComment:
        return true
      default:
        break
      }
    }
    return false
  }

  /// Returns a type syntax node with the identifier `Void` whose leading and trailing trivia have
  /// been copied from the tuple type syntax node it is replacing.
  private func makeVoidIdentifierType(toReplace node: TupleTypeSyntax) -> IdentifierTypeSyntax {
    return IdentifierTypeSyntax(
      name: TokenSyntax.identifier(
        "Void",
        leadingTrivia: node.firstToken(viewMode: .sourceAccurate)?.leadingTrivia ?? [],
        trailingTrivia: node.lastToken(viewMode: .sourceAccurate)?.trailingTrivia ?? []
      ),
      genericArgumentClause: nil
    )
  }
}

extension Finding.Message {
  fileprivate static let returnVoid: Finding.Message = "replace '()' with 'Void'"
}
