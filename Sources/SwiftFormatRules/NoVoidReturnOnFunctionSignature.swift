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

/// Functions that return `()` or `Void` should omit the return signature.
///
/// Lint: Function declarations that explicitly return `()` or `Void` will yield a lint error.
///
/// Format: Function declarations with explicit returns of `()` or `Void` will have their return
///         signature stripped.
public final class NoVoidReturnOnFunctionSignature: SyntaxFormatRule {
  /// Remove the `-> Void` return type for function signatures. Do not remove
  /// it for closure signatures, because that may introduce an ambiguity when closure signatures
  /// are inferred.
  public override func visit(_ node: FunctionSignatureSyntax) -> Syntax {
    if let ret = node.output?.returnType.as(SimpleTypeIdentifierSyntax.self), ret.name.text == "Void" {
      diagnose(.removeRedundantReturn("Void"), on: ret)
      return Syntax(node.withOutput(nil))
    }
    if let tup = node.output?.returnType.as(TupleTypeSyntax.self), tup.elements.isEmpty {
      diagnose(.removeRedundantReturn("()"), on: tup)
      return Syntax(node.withOutput(nil))
    }
    return Syntax(node)
  }
}

extension Finding.Message {
  public static func removeRedundantReturn(_ type: String) -> Finding.Message {
    "remove explicit '\(type)' return type"
  }
}
