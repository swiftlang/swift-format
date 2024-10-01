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
import SwiftParser
import SwiftSyntax

/// Never use `[<Type>]()` syntax. In call sites that should be replaced with `[]`,
/// for initializations use explicit type combined with empty array literal `let _: [<Type>] = []`
/// Static properties of a type that return that type should not include a reference to their type.
///
/// Lint:  Non-literal empty array initialization will yield a lint error.
/// Format: All invalid use sites would be related with empty literal (with or without explicit type annotation).
@_spi(Rules)
public final class AlwaysUseLiteralForEmptyCollectionInit: SyntaxFormatRule {
  public override class var isOptIn: Bool { return true }

  public override func visit(_ node: PatternBindingSyntax) -> PatternBindingSyntax {
    guard let initializer = node.initializer,
      let type = isRewritable(initializer)
    else {
      return node
    }

    if let type = type.as(ArrayTypeSyntax.self) {
      return rewrite(node, type: type)
    }

    if let type = type.as(DictionaryTypeSyntax.self) {
      return rewrite(node, type: type)
    }

    return node
  }

  public override func visit(_ param: FunctionParameterSyntax) -> FunctionParameterSyntax {
    guard let initializer = param.defaultValue,
      let type = isRewritable(initializer)
    else {
      return param
    }

    if let type = type.as(ArrayTypeSyntax.self) {
      return rewrite(param, type: type)
    }

    if let type = type.as(DictionaryTypeSyntax.self) {
      return rewrite(param, type: type)
    }

    return param
  }

  /// Check whether the initializer is `[<Type>]()` and, if so, it could be rewritten to use an empty collection literal.
  /// Return a type of the collection.
  public func isRewritable(_ initializer: InitializerClauseSyntax) -> TypeSyntax? {
    guard let initCall = initializer.value.as(FunctionCallExprSyntax.self),
      initCall.arguments.isEmpty
    else {
      return nil
    }

    if let arrayLiteral = initCall.calledExpression.as(ArrayExprSyntax.self) {
      return getLiteralType(arrayLiteral)
    }

    if let dictLiteral = initCall.calledExpression.as(DictionaryExprSyntax.self) {
      return getLiteralType(dictLiteral)
    }

    return nil
  }

  private func rewrite(
    _ node: PatternBindingSyntax,
    type: ArrayTypeSyntax
  ) -> PatternBindingSyntax {
    var replacement = node

    diagnose(node, type: type)

    if replacement.typeAnnotation == nil {
      // Drop trailing trivia after pattern because ':' has to appear connected to it.
      replacement.pattern = node.pattern.with(\.trailingTrivia, [])
      // Add explicit type annotation: ': [<Type>]`
      replacement.typeAnnotation = .init(
        type: type.with(\.leadingTrivia, .space)
          .with(\.trailingTrivia, .space)
      )
    }

    let initializer = node.initializer!
    let emptyArrayExpr = ArrayExprSyntax(elements: ArrayElementListSyntax.init([]))

    // Replace initializer call with empty array literal: `[<Type>]()` -> `[]`
    replacement.initializer = initializer.with(\.value, ExprSyntax(emptyArrayExpr))

    return replacement
  }

  private func rewrite(
    _ node: PatternBindingSyntax,
    type: DictionaryTypeSyntax
  ) -> PatternBindingSyntax {
    var replacement = node

    diagnose(node, type: type)

    if replacement.typeAnnotation == nil {
      // Drop trailing trivia after pattern because ':' has to appear connected to it.
      replacement.pattern = node.pattern.with(\.trailingTrivia, [])
      // Add explicit type annotation: ': [<Type>]`
      replacement.typeAnnotation = .init(
        type: type.with(\.leadingTrivia, .space)
          .with(\.trailingTrivia, .space)
      )
    }

    let initializer = node.initializer!
    // Replace initializer call with empty dictionary literal: `[<Type>]()` -> `[]`
    replacement.initializer = initializer.with(\.value, ExprSyntax(getEmptyDictionaryLiteral()))

    return replacement
  }

  private func rewrite(
    _ param: FunctionParameterSyntax,
    type: ArrayTypeSyntax
  ) -> FunctionParameterSyntax {
    guard let initializer = param.defaultValue else {
      return param
    }

    emitDiagnostic(replace: "\(initializer.value)", with: "[]", on: initializer.value)
    return param.with(\.defaultValue, initializer.with(\.value, getEmptyArrayLiteral()))
  }

  private func rewrite(
    _ param: FunctionParameterSyntax,
    type: DictionaryTypeSyntax
  ) -> FunctionParameterSyntax {
    guard let initializer = param.defaultValue else {
      return param
    }

    emitDiagnostic(replace: "\(initializer.value)", with: "[:]", on: initializer.value)
    return param.with(\.defaultValue, initializer.with(\.value, getEmptyDictionaryLiteral()))
  }

  private func diagnose(_ node: PatternBindingSyntax, type: ArrayTypeSyntax) {
    var withFixIt = "[]"
    if node.typeAnnotation == nil {
      withFixIt = ": \(type) = []"
    }

    let initCall = node.initializer!.value
    emitDiagnostic(replace: "\(initCall)", with: withFixIt, on: initCall)
  }

  private func diagnose(_ node: PatternBindingSyntax, type: DictionaryTypeSyntax) {
    var withFixIt = "[:]"
    if node.typeAnnotation == nil {
      withFixIt = ": \(type) = [:]"
    }

    let initCall = node.initializer!.value
    emitDiagnostic(replace: "\(initCall)", with: withFixIt, on: initCall)
  }

  private func emitDiagnostic(replace: String, with fixIt: String, on: ExprSyntax?) {
    diagnose(.refactorIntoEmptyLiteral(replace: replace, with: fixIt), on: on)
  }

  private func getLiteralType(_ arrayLiteral: ArrayExprSyntax) -> TypeSyntax? {
    guard arrayLiteral.elements.count == 1 else {
      return nil
    }

    var parser = Parser(arrayLiteral.description)
    let elementType = TypeSyntax.parse(from: &parser)

    guard !elementType.hasError, elementType.is(ArrayTypeSyntax.self) else {
      return nil
    }

    return elementType
  }

  private func getLiteralType(_ dictLiteral: DictionaryExprSyntax) -> TypeSyntax? {
    var parser = Parser(dictLiteral.description)
    let elementType = TypeSyntax.parse(from: &parser)

    guard !elementType.hasError, elementType.is(DictionaryTypeSyntax.self) else {
      return nil
    }

    return elementType
  }

  private func getEmptyArrayLiteral() -> ExprSyntax {
    ExprSyntax(ArrayExprSyntax(elements: ArrayElementListSyntax.init([])))
  }

  private func getEmptyDictionaryLiteral() -> ExprSyntax {
    ExprSyntax(DictionaryExprSyntax(content: .colon(.colonToken())))
  }
}

extension Finding.Message {
  fileprivate static func refactorIntoEmptyLiteral(
    replace: String,
    with: String
  ) -> Finding.Message {
    "replace '\(replace)' with '\(with)'"
  }
}
