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

extension SyntaxProtocol {
  /// Walks up from the current node to find the nearest node that is an
  /// Expr, Stmt, or Decl.
  public var containingExprStmtOrDecl: Syntax? {
    var node: Syntax? = Syntax(self)
    while let parent = node?.parent {
      if parent.is(ExprSyntax.self) || parent.is(StmtSyntax.self) || parent.is(DeclSyntax.self) {
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

  /// Returns the absolute position of the trivia piece at the given index in the receiver's leading
  /// trivia collection.
  ///
  /// If the trivia piece spans multiple characters, the value returned is the position of the first
  /// character.
  ///
  /// - Precondition: `index` is a valid index in the receiver's leading trivia collection.
  ///
  /// - Parameter index: The index of the trivia piece in the leading trivia whose position should
  ///   be returned.
  /// - Returns: The absolute position of the trivia piece.
  public func position(ofLeadingTriviaAt index: Trivia.Index) -> AbsolutePosition {
    let leadingTrivia = self.leadingTrivia ?? []
    guard leadingTrivia.indices.contains(index) else {
      preconditionFailure("Index was out of bounds in the node's leading trivia.")
    }

    var offset = SourceLength.zero
    for currentIndex in leadingTrivia.startIndex..<index {
      offset += leadingTrivia[currentIndex].sourceLength
    }
    return self.position + offset
  }

  /// Returns the source location of the trivia piece at the given index in the receiver's leading
  /// trivia collection.
  ///
  /// If the trivia piece spans multiple characters, the value returned is the location of the first
  /// character.
  ///
  /// - Precondition: `index` is a valid index in the receiver's leading trivia collection.
  ///
  /// - Parameters:
  ///   - index: The index of the trivia piece in the leading trivia whose location should be
  ///     returned.
  ///   - converter: The `SourceLocationConverter` that was previously initialized using the root
  ///     tree of this node.
  /// - Returns: The source location of the trivia piece.
  public func startLocation(
    ofLeadingTriviaAt index: Trivia.Index,
    converter: SourceLocationConverter
  ) -> SourceLocation {
    return converter.location(for: position(ofLeadingTriviaAt: index))
  }
}

extension SyntaxCollection {
  /// The first element in the syntax collection if it is the *only* element, or nil otherwise.
  public var firstAndOnly: Element? {
    var iterator = makeIterator()
    guard let first = iterator.next() else { return nil }
    guard iterator.next() == nil else { return nil }
    return first
  }
}
