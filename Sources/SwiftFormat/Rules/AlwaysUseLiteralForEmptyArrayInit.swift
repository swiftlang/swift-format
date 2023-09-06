//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2023 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import Foundation
import SwiftSyntax
import SwiftParser

/// Never use `[<Type>]()` syntax. In call sites that should be replaced with `[]`,
/// for initializations use explicit type combined with empty array literal `let _: [<Type>] = []`
/// Static properties of a type that return that type should not include a reference to their type.
///
/// Lint:  Non-literal empty array initialization will yield a lint error.
/// Format: All invalid use sites would be related with empty literal (with or without explicit type annotation).
@_spi(Rules)
public final class AlwaysUseLiteralForEmptyArrayInit : SyntaxFormatRule {
  public override class var isOptIn: Bool { return true }

  public override func visit(_ node: PatternBindingSyntax) -> PatternBindingSyntax {
    guard let initializer = node.initializer else {
      return node
    }

    // Check whether the initializer is `[<Type>]()`
    guard let initCall = initializer.value.as(FunctionCallExprSyntax.self),
          var arrayLiteral = initCall.calledExpression.as(ArrayExprSyntax.self),
          initCall.arguments.isEmpty else {
      return node
    }

    guard let elementType = getElementType(arrayLiteral) else {
      return node
    }

    var replacement = node

    var withFixIt = "[]"
    if replacement.typeAnnotation == nil {
      withFixIt = ": [\(elementType)] = []"
    }

    diagnose(.refactorEmptyArrayInit(replace: "\(initCall)", with: withFixIt), on: initCall)

    if replacement.typeAnnotation == nil {
      // Drop trailing trivia after pattern because ':' has to appear connected to it.
      replacement.pattern = node.pattern.with(\.trailingTrivia, [])
      // Add explicit type annotiation: ': [<Type>]`
      replacement.typeAnnotation = .init(type: ArrayTypeSyntax(leadingTrivia: .space,
                                                               element: elementType,
                                                               trailingTrivia: .space))
    }

    // Replace initializer call with empty array literal: `[<Type>]()` -> `[]`
    arrayLiteral.elements = ArrayElementListSyntax.init([])
    replacement.initializer = initializer.with(\.value, ExprSyntax(arrayLiteral))

    return replacement
  }

  private func getElementType(_ arrayLiteral: ArrayExprSyntax) -> TypeSyntax? {
    guard let elementExpr = arrayLiteral.elements.firstAndOnly?.as(ArrayElementSyntax.self) else {
      return nil
    }

    var parser = Parser(elementExpr.description)
    let elementType = TypeSyntax.parse(from: &parser)
    return elementType.hasError ? nil : elementType
  }
}

extension Finding.Message {
  public static func refactorEmptyArrayInit(replace: String, with: String) -> Finding.Message {
    "replace '\(replace)' with '\(with)'"
  }
}
