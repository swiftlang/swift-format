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
  /// Returns the number of whitespace characters in this trivia.
  public var numberOfSpaces: Int {
    var count = 0
    for piece in self {
      if case .tabs = piece { count += 1 }
      guard case .spaces(let n) = piece else { continue }
      count += n
    }
    return count
  }

  /// Returns the number of newlines in this trivia.
  public var numberOfNewlines: Int {
    var count = 0
    for piece in self {
      if case .newlines(let n) = piece {
        count += n
      }
    }
    return count
  }

  /// Returns the number of leading newlines in this trivia.
  public var numberOfLeadingNewlines: Int {
    var count = 0
    loop: for piece in self {
      switch piece {
      case .newlines(let n): count += n
      case .carriageReturns(let n): count += n
      case .carriageReturnLineFeeds(let n): count += n
      default: break loop
      }
    }
    return count
  }

  public var numberOfComments: Int {
    var count = 0
    for piece in self {
      switch piece {
      case .lineComment, .docLineComment, .blockComment, .docBlockComment:
        count += 1
      default:
        continue
      }
    }
    return count
  }

  public var hasSpaces: Bool {
    for piece in self {
      if case .tabs = piece { return true }
      if case .spaces = piece { return true }
    }
    return false
  }

  public var hasBackticks: Bool {
    for piece in self {
      if case .backticks = piece { return true }
    }
    return false
  }

  /// Returns this set of trivia, without any whitespace characters.
  public func withoutSpaces() -> Trivia {
    return Trivia(
      pieces: filter {
        if case .spaces = $0 { return false }
        if case .tabs = $0 { return false }
        return true
      })
  }

  /// Returns this set of trivia without any trailing whitespace characters.
  public func withoutTrailingSpaces() -> Trivia {
    var pieces = [TriviaPiece]()
    guard var prev = first else { return self }
    for piece in dropFirst() {
      switch (prev, piece) {
      case (.spaces(_), .newlines(_)),
        (.tabs(_), .newlines(_)):
        prev = piece
      default:
        pieces.append(prev)
        prev = piece
      }
    }
    pieces.append(prev)
    return Trivia(pieces: pieces).condensed()
  }

  /// Returns this set of trivia, without any trailing whitespace characters.
  public func withoutLeadingNewLines() -> Trivia {
    let triviaCondensed = self.condensed()
    guard let firstPieceOfTrivia = triviaCondensed.first else { return self }
    if case .newlines(_) = firstPieceOfTrivia {
      var pieces = [TriviaPiece]()
      for piece in triviaCondensed.dropFirst() {
        pieces.append(piece)
      }
      return Trivia(pieces: pieces)
    } else {
      return self
    }
  }

  /// Returns this set of trivia, without any newlines.
  public func withoutNewlines() -> Trivia {
    return Trivia(
      pieces: filter {
        if case .newlines = $0 { return false }
        return true
      })
  }

  /// Returns this set of trivia, with all spaces removed except for one at the
  /// end.
  public func withOneTrailingSpace() -> Trivia {
    return withoutSpaces() + .spaces(1)
  }

  /// Returns this set of trivia, with all spaces removed except for one at the
  /// beginning.
  public func withOneLeadingSpace() -> Trivia {
    return .spaces(1) + withoutSpaces()
  }

  /// Returns this set of trivia, with all newlines removed except for one.
  public func withOneLeadingNewline() -> Trivia {
    return .newlines(1) + withoutNewlines()
  }

  /// Returns this set of trivia, with all newlines removed except for one.
  public func withOneTrailingNewline() -> Trivia {
    return withoutNewlines() + .newlines(1)
  }

  /// Walks through trivia looking for multiple separate trivia entities with
  /// the same base kind, and condenses them.
  /// `[.spaces(1), .spaces(2)]` becomes `[.spaces(3)]`.
  public func condensed() -> Trivia {
    guard var prev = first else { return self }
    var pieces = [TriviaPiece]()
    for piece in dropFirst() {
      switch (prev, piece) {
      case (.spaces(let l), .spaces(let r)):
        prev = .spaces(l + r)
      case (.tabs(let l), .tabs(let r)):
        prev = .tabs(l + r)
      case (.newlines(let l), .newlines(let r)):
        prev = .newlines(l + r)
      case (.carriageReturns(let l), .carriageReturns(let r)):
        prev = .carriageReturns(l + r)
      case (.carriageReturnLineFeeds(let l), .carriageReturnLineFeeds(let r)):
        prev = .carriageReturnLineFeeds(l + r)
      case (.verticalTabs(let l), .verticalTabs(let r)):
        prev = .verticalTabs(l + r)
      case (.garbageText(let l), .garbageText(let r)):
        prev = .garbageText(l + r)
      case (.backticks(let l), .backticks(let r)):
        prev = .backticks(l + r)
      case (.formfeeds(let l), .formfeeds(let r)):
        prev = .formfeeds(l + r)
      default:
        pieces.append(prev)
        prev = piece
      }
    }
    pieces.append(prev)
    return Trivia(pieces: pieces)
  }

  /// Returns `true` if this trivia contains any newlines.
  public var containsNewlines: Bool {
    return contains(
      where: {
        if case .newlines = $0 { return true }
        return false
      })
  }

  /// Returns `true` if this trivia contains any spaces.
  public var containsSpaces: Bool {
    return contains(
      where: {
        if case .spaces = $0 { return true }
        if case .tabs = $0 { return true }
        return false
      })
  }
}
