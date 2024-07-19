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
  func position(ofLeadingTriviaAt index: Trivia.Index) -> AbsolutePosition {
    guard leadingTrivia.indices.contains(index) else {
      preconditionFailure("Index was out of bounds in the node's leading trivia.")
    }

    var offset = SourceLength.zero
    for currentIndex in leadingTrivia.startIndex..<index {
      offset += leadingTrivia[currentIndex].sourceLength
    }
    return self.position + offset
  }

  /// Returns the absolute position of the trivia piece at the given index in the receiver's
  /// trailing trivia collection.
  ///
  /// If the trivia piece spans multiple characters, the value returned is the position of the first
  /// character.
  ///
  /// - Precondition: `index` is a valid index in the receiver's trailing trivia collection.
  ///
  /// - Parameter index: The index of the trivia piece in the trailing trivia whose position should
  ///   be returned.
  /// - Returns: The absolute position of the trivia piece.
  func position(ofTrailingTriviaAt index: Trivia.Index) -> AbsolutePosition {
    guard trailingTrivia.indices.contains(index) else {
      preconditionFailure("Index was out of bounds in the node's trailing trivia.")
    }

    var offset = SourceLength.zero
    for currentIndex in trailingTrivia.startIndex..<index {
      offset += trailingTrivia[currentIndex].sourceLength
    }
    return self.endPositionBeforeTrailingTrivia + offset
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
  func startLocation(
    ofLeadingTriviaAt index: Trivia.Index,
    converter: SourceLocationConverter
  ) -> SourceLocation {
    return converter.location(for: position(ofLeadingTriviaAt: index))
  }

  /// Returns the source location of the trivia piece at the given index in the receiver's trailing
  /// trivia collection.
  ///
  /// If the trivia piece spans multiple characters, the value returned is the location of the first
  /// character.
  ///
  /// - Precondition: `index` is a valid index in the receiver's trailing trivia collection.
  ///
  /// - Parameters:
  ///   - index: The index of the trivia piece in the trailing trivia whose location should be
  ///     returned.
  ///   - converter: The `SourceLocationConverter` that was previously initialized using the root
  ///     tree of this node.
  /// - Returns: The source location of the trivia piece.
  func startLocation(
    ofTrailingTriviaAt index: Trivia.Index,
    converter: SourceLocationConverter
  ) -> SourceLocation {
    return converter.location(for: position(ofTrailingTriviaAt: index))
  }

  /// The collection of all contiguous trivia preceding this node; that is, the trailing trivia of
  /// the node before it and the leading trivia of the node itself.
  var allPrecedingTrivia: Trivia {
    var result: Trivia
    if let previousTrailingTrivia = previousToken(viewMode: .sourceAccurate)?.trailingTrivia {
      result = previousTrailingTrivia
    } else {
      result = Trivia()
    }
    result += leadingTrivia
    return result
  }

  /// The collection of all contiguous trivia following this node; that is, the trailing trivia of
  /// the node and the leading trivia of the node after it.
  var allFollowingTrivia: Trivia {
    var result = trailingTrivia
    if let nextLeadingTrivia = nextToken(viewMode: .sourceAccurate)?.leadingTrivia {
      result += nextLeadingTrivia
    }
    return result
  }

  /// Indicates whether the node has any preceding line comments.
  ///
  /// Due to the way trivia is parsed, a preceding comment might be in either the leading trivia of
  /// the node or the trailing trivia of the previous token.
  var hasPrecedingLineComment: Bool {
    if let previousTrailingTrivia = previousToken(viewMode: .sourceAccurate)?.trailingTrivia,
      previousTrailingTrivia.hasLineComment
    {
      return true
    }
    return leadingTrivia.hasLineComment
  }

  /// Indicates whether the node has any preceding comments of any kind.
  ///
  /// Due to the way trivia is parsed, a preceding comment might be in either the leading trivia of
  /// the node or the trailing trivia of the previous token.
  var hasAnyPrecedingComment: Bool {
    if let previousTrailingTrivia = previousToken(viewMode: .sourceAccurate)?.trailingTrivia,
      previousTrailingTrivia.hasAnyComments
    {
      return true
    }
    return leadingTrivia.hasAnyComments
  }

  /// Indicates whether the node has any function ancestor marked with `@Test` attribute.
  var hasTestAncestor: Bool {
    var parent = self.parent
    while let existingParent = parent {
      if let functionDecl = existingParent.as(FunctionDeclSyntax.self),
          functionDecl.hasAttribute("Test", inModule: "Testing") {
        return true
      }
      parent = existingParent.parent
    }
    return false
  }
}

extension SyntaxCollection {
  /// The first element in the syntax collection if it is the *only* element, or nil otherwise.
  var firstAndOnly: Element? {
    var iterator = makeIterator()
    guard let first = iterator.next() else { return nil }
    guard iterator.next() == nil else { return nil }
    return first
  }
}
