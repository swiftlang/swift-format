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

/// Return `Void`, not `()`, in signatures.
///
/// Note that this rule does *not* apply to function declaration signatures in order to avoid
/// conflicting with `NoVoidReturnOnFunctionSignature`.
///
/// Lint: Returning `()` in a signature yields a lint error.
///
/// Format: `-> ()` is replaced with `-> Void`
public final class ReturnVoidInsteadOfEmptyTuple: SyntaxFormatRule {
  public override func visit(_ node: FunctionTypeSyntax) -> TypeSyntax {
    guard let returnType = node.returnType.as(TupleTypeSyntax.self),
      returnType.elements.count == 0
    else {
      return super.visit(node)
    }

    diagnose(.returnVoid, on: returnType)

    // If the user has put non-whitespace trivia inside the empty tuple, like a comment, then we
    // still diagnose it as a lint error but we don't replace it because it's not obvious where the
    // comment should go.
    if hasNonWhitespaceTrivia(returnType.leftParen, at: .trailing)
        || hasNonWhitespaceTrivia(returnType.rightParen, at: .leading) {
      return super.visit(node)
    }

    // Make sure that function types nested in the argument list are also rewritten (for example,
    // `(Int -> ()) -> ()` should become `(Int -> Void) -> Void`).
    let arguments = visit(node.arguments).as(TupleTypeElementListSyntax.self)!
    let voidKeyword = makeVoidIdentifierType(toReplace: returnType)
    return TypeSyntax(node.withArguments(arguments).withReturnType(TypeSyntax(voidKeyword)))
  }

  public override func visit(_ node: ClosureSignatureSyntax) -> Syntax {
    guard let output = node.output,
      let returnType = output.returnType.as(TupleTypeSyntax.self),
      returnType.elements.count == 0
    else {
      return super.visit(node)
    }

    diagnose(.returnVoid, on: returnType)

    // If the user has put non-whitespace trivia inside the empty tuple, like a comment, then we
    // still diagnose it as a lint error but we don't replace it because it's not obvious where the
    // comment should go.
    if hasNonWhitespaceTrivia(returnType.leftParen, at: .trailing)
        || hasNonWhitespaceTrivia(returnType.rightParen, at: .leading) {
      return super.visit(node)
    }

    let input: Syntax?
    if let parameterClause = node.input?.as(ParameterClauseSyntax.self) {
      // If the closure input is a complete parameter clause (variables and types), make sure that
      // nested function types are also rewritten (for example, `label: (Int -> ()) -> ()` should
      // become `label: (Int -> Void) -> Void`).
      input = visit(parameterClause)
    } else {
      // Otherwise, it's a simple signature (just variable names, no types), so there is nothing to
      // rewrite.
      input = node.input
    }
    let voidKeyword = makeVoidIdentifierType(toReplace: returnType)
    return Syntax(node.withInput(input).withOutput(output.withReturnType(TypeSyntax(voidKeyword))))
  }

  /// Returns a value indicating whether the leading trivia of the given token contained any
  /// non-whitespace pieces.
  private func hasNonWhitespaceTrivia(_ token: TokenSyntax, at position: TriviaPosition) -> Bool {
    for piece in position == .leading ? token.leadingTrivia : token.trailingTrivia {
      switch piece {
      case .blockComment, .docBlockComment, .docLineComment, .unexpectedText, .lineComment,
        .shebang:
        return true
      default:
        break
      }
    }
    return false
  }

  /// Returns a type syntax node with the identifier `Void` whose leading and trailing trivia have
  /// been copied from the tuple type syntax node it is replacing.
  private func makeVoidIdentifierType(toReplace node: TupleTypeSyntax) -> SimpleTypeIdentifierSyntax
  {
    return SimpleTypeIdentifierSyntax(
      name: TokenSyntax.identifier(
        "Void",
        leadingTrivia: node.firstToken?.leadingTrivia ?? [],
        trailingTrivia: node.lastToken?.trailingTrivia ?? []),
      genericArgumentClause: nil)
  }
}

extension Finding.Message {
  public static let returnVoid: Finding.Message = "replace '()' with 'Void'"
}
