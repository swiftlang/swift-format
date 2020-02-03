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
