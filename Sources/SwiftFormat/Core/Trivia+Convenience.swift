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

extension Trivia {
  var hasAnyComments: Bool {
    return contains {
      switch $0 {
      case .lineComment, .docLineComment, .blockComment, .docBlockComment:
        return true
      default:
        return false
      }
    }
  }

  /// Returns whether the trivia contains at least 1 `lineComment`.
  var hasLineComment: Bool {
    return self.contains {
      if case .lineComment = $0 { return true }
      return false
    }
  }

  /// Returns this set of trivia, without any leading spaces.
  func withoutLeadingSpaces() -> Trivia {
    return Trivia(pieces: self.pieces.drop(while: \.isSpaceOrTab))
  }

  func withoutTrailingSpaces() -> Trivia {
    guard let lastNonSpaceIndex = self.pieces.lastIndex(where: \.isSpaceOrTab) else {
      return self
    }
    return Trivia(pieces: self[..<lastNonSpaceIndex])
  }

  /// Returns this trivia, excluding the last newline and anything following it.
  ///
  /// If there is no newline in the trivia, it is returned unmodified.
  func withoutLastLine() -> Trivia {
    var maybeLastNewlineOffset: Int? = nil
    for (offset, piece) in self.enumerated() {
      switch piece {
      case .newlines, .carriageReturns, .carriageReturnLineFeeds:
        maybeLastNewlineOffset = offset
      default:
        break
      }
    }
    guard let lastNewlineOffset = maybeLastNewlineOffset else { return self }
    return Trivia(pieces: self.dropLast(self.count - lastNewlineOffset))
  }

  /// Returns `true` if this trivia contains any newlines.
  var containsNewlines: Bool {
    return contains(
      where: {
        if case .newlines = $0 { return true }
        return false
      })
  }

  /// Returns `true` if this trivia contains any spaces.
  var containsSpaces: Bool {
    return contains(
      where: {
        if case .spaces = $0 { return true }
        if case .tabs = $0 { return true }
        return false
      })
  }

  /// Returns the prefix of this trivia that corresponds to the backslash and pound signs used to
  /// represent a non-line-break continuation of a multiline string, or nil if the trivia does not
  /// represent such a continuation.
  var multilineStringContinuation: String? {
    var result = ""
    for piece in pieces {
      switch piece {
      case .backslashes, .pounds:
        piece.write(to: &result)
      default:
        break
      }
    }
    return result.isEmpty ? nil : result
  }
}
