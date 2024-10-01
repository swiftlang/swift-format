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

/// Functions that return `()` or `Void` should omit the return signature.
///
/// Lint: Function declarations that explicitly return `()` or `Void` will yield a lint error.
///
/// Format: Function declarations with explicit returns of `()` or `Void` will have their return
///         signature stripped.
@_spi(Rules)
public final class NoVoidReturnOnFunctionSignature: SyntaxFormatRule {
  /// Remove the `-> Void` return type for function signatures. Do not remove
  /// it for closure signatures, because that may introduce an ambiguity when closure signatures
  /// are inferred.
  public override func visit(_ node: FunctionSignatureSyntax) -> FunctionSignatureSyntax {
    guard let returnType = node.returnClause?.type else { return node }

    if let identifierType = returnType.as(IdentifierTypeSyntax.self),
      identifierType.name.text == "Void",
      identifierType.genericArgumentClause?.arguments.isEmpty ?? true
    {
      diagnose(.removeRedundantReturn("Void"), on: identifierType)
      return removingReturnClause(from: node)
    }
    if let tupleType = returnType.as(TupleTypeSyntax.self), tupleType.elements.isEmpty {
      diagnose(.removeRedundantReturn("()"), on: tupleType)
      return removingReturnClause(from: node)
    }

    return node
  }

  /// Returns a copy of the given function signature with the return clause removed.
  private func removingReturnClause(
    from signature: FunctionSignatureSyntax
  ) -> FunctionSignatureSyntax {
    var result = signature
    result.returnClause = nil
    return result
  }
}

extension Finding.Message {
  fileprivate static func removeRedundantReturn(_ type: String) -> Finding.Message {
    "remove the explicit return type '\(type)' from this function"
  }
}
