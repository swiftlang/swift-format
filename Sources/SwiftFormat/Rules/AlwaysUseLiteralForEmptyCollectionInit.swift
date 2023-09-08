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
public final class AlwaysUseLiteralForEmptyCollectionInit : SyntaxFormatRule {
  public override class var isOptIn: Bool { return true }

  public override func visit(_ node: PatternBindingSyntax) -> PatternBindingSyntax {
    // Check whether the initializer is `[<Type>]()`
    guard let initializer = node.initializer,
          let initCall = initializer.value.as(FunctionCallExprSyntax.self),
          initCall.arguments.isEmpty else {
      return node
    }

    if let arrayLiteral = initCall.calledExpression.as(ArrayExprSyntax.self),
       let type = getLiteralType(arrayLiteral) {
      return rewrite(node, type: type)
    }

    if let dictLiteral = initCall.calledExpression.as(DictionaryExprSyntax.self),
       let type = getLiteralType(dictLiteral) {
      return rewrite(node, type: type)
    }

    return node
  }

  private func rewrite(_ node: PatternBindingSyntax,
                       type: ArrayTypeSyntax) -> PatternBindingSyntax {
    var replacement = node

    diagnose(node, type: type)

    if replacement.typeAnnotation == nil {
      // Drop trailing trivia after pattern because ':' has to appear connected to it.
      replacement.pattern = node.pattern.with(\.trailingTrivia, [])
      // Add explicit type annotiation: ': [<Type>]`
      replacement.typeAnnotation = .init(type: type.with(\.leadingTrivia, .space)
                                                   .with(\.trailingTrivia, .space))
    }

    let initializer = node.initializer!
    let emptyArrayExpr = ArrayExprSyntax(elements: ArrayElementListSyntax.init([]))

    // Replace initializer call with empty array literal: `[<Type>]()` -> `[]`
    replacement.initializer = initializer.with(\.value, ExprSyntax(emptyArrayExpr))

    return replacement
  }

  private func rewrite(_ node: PatternBindingSyntax,
                       type: DictionaryTypeSyntax) -> PatternBindingSyntax {
    var replacement = node

    diagnose(node, type: type)

    if replacement.typeAnnotation == nil {
      // Drop trailing trivia after pattern because ':' has to appear connected to it.
      replacement.pattern = node.pattern.with(\.trailingTrivia, [])
      // Add explicit type annotiation: ': [<Type>]`
      replacement.typeAnnotation = .init(type: type.with(\.leadingTrivia, .space)
                                                   .with(\.trailingTrivia, .space))
    }

    let initializer = node.initializer!
    let emptyDictExpr = DictionaryExprSyntax(content: .colon(.colonToken()))

    // Replace initializer call with empty dictionary literal: `[<Type>]()` -> `[]`
    replacement.initializer = initializer.with(\.value, ExprSyntax(emptyDictExpr))

    return replacement
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

  private func getLiteralType(_ arrayLiteral: ArrayExprSyntax) -> ArrayTypeSyntax? {
    guard let elementExpr = arrayLiteral.elements.firstAndOnly,
          elementExpr.is(ArrayElementSyntax.self) else {
      return nil
    }

    var parser = Parser(arrayLiteral.description)
    let elementType = TypeSyntax.parse(from: &parser)
    return elementType.hasError ? nil : elementType.as(ArrayTypeSyntax.self)
  }

  private func getLiteralType(_ dictLiteral: DictionaryExprSyntax) -> DictionaryTypeSyntax? {
    var parser = Parser(dictLiteral.description)
    let elementType = TypeSyntax.parse(from: &parser)
    return elementType.hasError ? nil : elementType.as(DictionaryTypeSyntax.self)
  }
}

extension Finding.Message {
  public static func refactorIntoEmptyLiteral(replace: String, with: String) -> Finding.Message {
    "replace '\(replace)' with '\(with)'"
  }
}
