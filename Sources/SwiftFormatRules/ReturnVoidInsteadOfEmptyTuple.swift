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
    else { return TypeSyntax(node) }
    diagnose(.returnVoid, on: node.returnType)
    let voidKeyword = SyntaxFactory.makeSimpleTypeIdentifier(
      name: SyntaxFactory.makeIdentifier(
        "Void",
        trailingTrivia: returnType.rightParen.trailingTrivia),
      genericArgumentClause: nil)
    return TypeSyntax(node.withReturnType(TypeSyntax(voidKeyword)))
  }
}

extension Diagnostic.Message {
  public static let returnVoid = Diagnostic.Message(.warning, "replace '()' with 'Void'")
}
