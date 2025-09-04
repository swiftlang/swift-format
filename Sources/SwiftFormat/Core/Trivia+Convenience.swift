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

  func trimmingSuperfluousNewlines(fromClosingBrace: Bool) -> (Trivia, Int) {
    var trimmmed = 0
    var pendingNewlineCount = 0
    let pieces = self.indices.reduce([TriviaPiece]()) { (partialResult, index) in
      let piece = self[index]
      // Collapse consecutive newlines into a single one
      if case .newlines(let count) = piece {
        if fromClosingBrace {
          if index == self.count - 1 {
            // For the last index(newline right before the closing brace), collapse into a single newline
            trimmmed += count - 1
            return partialResult + [.newlines(1)]
          } else {
            pendingNewlineCount += count
            return partialResult
          }
        } else {
          if let last = partialResult.last, last.isNewline {
            trimmmed += count
            return partialResult
          } else if index == 0 {
            // For leading trivia not associated with a closing brace, collapse the first newline into a single one
            trimmmed += count - 1
            return partialResult + [.newlines(1)]
          } else {
            return partialResult + [piece]
          }
        }
      }
      // Remove spaces/tabs surrounded by newlines
      if piece.isSpaceOrTab, index > 0, index < self.count - 1, self[index - 1].isNewline, self[index + 1].isNewline {
        return partialResult
      }
      // Handle pending newlines if there are any
      if pendingNewlineCount > 0 {
        if index < self.count - 1 {
          let newlines = TriviaPiece.newlines(pendingNewlineCount)
          pendingNewlineCount = 0
          return partialResult + [newlines] + [piece]
        } else {
          return partialResult + [.newlines(1)] + [piece]
        }
      }
      // Retain other trivia pieces
      return partialResult + [piece]
    }

    return (Trivia(pieces: pieces), trimmmed)
  }
}
