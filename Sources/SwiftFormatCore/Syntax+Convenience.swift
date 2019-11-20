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

extension Syntax {
  /// Walks up from the current node to find the nearest node that is an
  /// Expr, Stmt, or Decl.
  public var containingExprStmtOrDecl: Syntax? {
    var node: Syntax? = self
    while let parent = node?.parent {
      if parent is ExprSyntax || parent is StmtSyntax || parent is DeclSyntax {
        return parent
      }
      node = parent
    }
    return nil
  }

  /// Returns true if the node occupies a single line.
  ///
  /// - Parameters:
  ///   - includingLeadingComment: If true, factor any possible leading comments into the
  ///     determination of whether the node occupies a single line.
  ///   - sourceLocationConverter: Used to convert source positions to line/column locations.
  /// - Returns: True if the node occupies a single line.
  public func isSingleLine(
    includingLeadingComment: Bool,
    sourceLocationConverter: SourceLocationConverter
  ) -> Bool {
    guard let firstToken = firstToken, let lastToken = lastToken else { return true }

    let startPosition: AbsolutePosition
    if includingLeadingComment {
      // Iterate over the trivia, stopping at the first comment, and using that as the start
      // position.
      var currentPosition = firstToken.position
      var sawNewline = false
      loop: for piece in firstToken.leadingTrivia {
        switch piece {
        case .docLineComment,
          .docBlockComment,
          .lineComment where sawNewline,
          .blockComment where sawNewline:
          // Non-doc line or block comments before we've seen the first newline should actually be
          // considered trailing comments of the previous line.
          break loop
        case .newlines, .carriageReturns, .carriageReturnLineFeeds:
          sawNewline = true
          fallthrough
        default:
          currentPosition += piece.sourceLength
        }
      }
      startPosition = currentPosition
    } else {
      startPosition = firstToken.positionAfterSkippingLeadingTrivia
    }

    let startLocation = sourceLocationConverter.location(for: startPosition)
    let endLocation = sourceLocationConverter.location(
      for: lastToken.endPositionBeforeTrailingTrivia)

    return startLocation.line == endLocation.line
  }
}

extension SyntaxCollection {

  /// Indicates whether the syntax collection is empty.
  public var isEmpty: Bool {
    var iterator = makeIterator()
    return iterator.next() == nil
  }

  /// The first element in the syntax collection, or nil if it is empty.
  public var first: Element? {
    var iterator = makeIterator()
    guard let first = iterator.next() else { return nil }
    return first
  }

  /// The first element in the syntax collection if it is the *only* element, or nil otherwise.
  public var firstAndOnly: Element? {
    var iterator = makeIterator()
    guard let first = iterator.next() else { return nil }
    guard iterator.next() == nil else { return nil }
    return first
  }

  /// The last element in the syntax collection, or nil if it is empty.
  ///
  /// TODO: This is currently O(n). We should make the syntax collections `BidirectionalCollection`
  /// instead of `Sequence` so that we can provide these operations more efficiently.
  public var last: Element? {
    var last: Element? = nil
    var iterator = makeIterator()
    while let current = iterator.next() { last = current }
    return last
  }
}
