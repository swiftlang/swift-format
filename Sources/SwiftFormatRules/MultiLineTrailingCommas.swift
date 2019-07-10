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

import Foundation
import SwiftFormatCore
import SwiftSyntax

/// Array and dictionary literals should have a trailing comma if they are split on multiple lines.
///
/// Lint: If an array or dictionary literal is split on multiple lines, and the last element does
///       not have a trailing comma, a lint error is raised.
///
/// Format: The last element of a multi-line array or dictionary literal will have a trailing comma
///         inserted if it does not have one already.
///
/// - SeeAlso: https://google.github.io/swift#trailing-commas
public final class MultiLineTrailingCommas: SyntaxFormatRule {
  public override func visit(_ node: ArrayExprSyntax) -> ExprSyntax {
    guard !node.elements.isEmpty else { return node }

    guard let lastElt = node.elements.last else { return node }
    guard lastElt.trailingComma == nil else { return node }
    guard node.rightSquare.leadingTrivia.containsNewlines else { return node }

    diagnose(.addTrailingCommaArray, on: lastElt)

    // Insert a trailing comma before the existing trailing trivia
    let newElt = lastElt.withTrailingComma(
      SyntaxFactory.makeCommaToken(trailingTrivia: lastElt.trailingTrivia ?? [])
    )
    let newEltTriviaReplaced = replaceTrivia(
      on: newElt,
      token: newElt.expression.lastToken,
      trailingTrivia: []
    ) as! ArrayElementSyntax

    let newElements = node.elements.replacing(
      childAt: lastElt.indexInParent,
      with: newEltTriviaReplaced
    )
    return node.withElements(newElements)
  }

  public override func visit(_ node: DictionaryExprSyntax) -> ExprSyntax {
    guard let elements = node.content as? DictionaryElementListSyntax else { return node }
    guard !elements.isEmpty else { return node }

    guard let lastElt = elements.last else { return node }
    guard lastElt.trailingComma == nil else { return node }
    guard node.rightSquare.leadingTrivia.containsNewlines else { return node }

    // TODO(b/77534297): location for diagnostic
    diagnose(.addTrailingCommaDictionary, on: lastElt)

    // Insert a trailing comma before the existing trailing trivia
    let newElt = lastElt.withTrailingComma(
      SyntaxFactory.makeCommaToken(trailingTrivia: lastElt.trailingTrivia ?? [])
    )
    let newEltTriviaReplaced = replaceTrivia(
      on: newElt,
      token: newElt.valueExpression.lastToken,
      trailingTrivia: []
    ) as! DictionaryElementSyntax

    let newElements = elements.replacing(
      childAt: lastElt.indexInParent,
      with: newEltTriviaReplaced
    )
    return node.withContent(newElements)
  }
}

extension Diagnostic.Message {
  static let addTrailingCommaArray = Diagnostic.Message(
    .warning, "add trailing comma on last array literal element")

  static let addTrailingCommaDictionary = Diagnostic.Message(
    .warning, "add trailing comma on last dictionary literal element")
}
