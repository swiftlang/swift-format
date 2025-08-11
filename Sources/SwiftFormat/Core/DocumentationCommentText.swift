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

import SwiftSyntax

/// The text contents of a documentation comment extracted from trivia.
///
/// This type should be used when only the text of the comment is important, not the Markdown
/// structural organization. It automatically handles trimming leading indentation from comments as
/// well as "ASCII art" in block comments (i.e., leading asterisks on each line).
@_spi(Testing)
@_spi(Rules)
public struct DocumentationCommentText {
  /// Denotes the kind of punctuation used to introduce the comment.
  public enum Introducer {
    /// The comment was introduced entirely by line-style comments (`///`).
    case line

    /// The comment was introduced entirely by block-style comments (`/** ... */`).
    case block

    /// The comment was introduced by a mixture of line-style and block-style comments.
    case mixed
  }

  /// The comment text extracted from the trivia.
  public let text: String

  /// The index in the trivia collection passed to the initializer where the comment started.
  public let startIndex: Trivia.Index

  /// The kind of punctuation used to introduce the comment.
  public let introducer: Introducer

  /// Extracts and returns the body text of a documentation comment represented as a trivia
  /// collection.
  ///
  /// This implementation is based on
  /// https://github.com/apple/swift/blob/main/lib/Markup/LineList.cpp.
  ///
  /// - Parameter trivia: The trivia collection from which to extract the comment text.
  /// - Returns: If a comment was found, a tuple containing the `String` containing the extracted
  ///   text and the index into the trivia collection where the comment began is returned.
  ///   Otherwise, `nil` is returned.
  public init?(extractedFrom trivia: Trivia) {
    /// Represents a line of text and its leading indentation.
    struct Line {
      var text: Substring
      var firstNonspaceDistance: Int

      init(_ text: Substring) {
        self.text = text
        self.firstNonspaceDistance = indentationDistance(of: text)
      }
    }

    // Look backwards from the end of the trivia collection to find the logical start of the
    // comment. We have to copy it into an array since `Trivia` doesn't support bidirectional
    // indexing.
    let triviaArray = Array(trivia)
    let commentStartIndex = findCommentStartIndex(triviaArray)

    // Determine the indentation level of the first line of the comment. This is used to adjust
    // block comments, whose text spans multiple lines.
    let leadingWhitespace = contiguousWhitespace(in: triviaArray, before: commentStartIndex)
    var lines = [Line]()

    var introducer: Introducer?
    func updateIntroducer(_ newIntroducer: Introducer) {
      if let knownIntroducer = introducer, knownIntroducer != newIntroducer {
        introducer = .mixed
      } else {
        introducer = newIntroducer
      }
    }

    // Extract the raw lines of text (which will include their leading comment punctuation, which is
    // stripped).
    for triviaPiece in trivia[commentStartIndex...] {
      switch triviaPiece {
      case .docLineComment(let line):
        updateIntroducer(.line)
        lines.append(Line(line.dropFirst(3)))

      case .docBlockComment(let line):
        updateIntroducer(.block)

        var cleaned = line.dropFirst(3)
        if cleaned.hasSuffix("*/") {
          cleaned = cleaned.dropLast(2)
        }

        var hasASCIIArt = false
        if cleaned.hasPrefix("\n") {
          cleaned = cleaned.dropFirst()
          hasASCIIArt = asciiArtLength(of: cleaned, leadingSpaces: leadingWhitespace) != 0
        }

        while !cleaned.isEmpty {
          var index = cleaned.firstIndex(where: \.isNewline) ?? cleaned.endIndex
          if hasASCIIArt {
            cleaned =
              cleaned.dropFirst(asciiArtLength(of: cleaned, leadingSpaces: leadingWhitespace))
            index = cleaned.firstIndex(where: \.isNewline) ?? cleaned.endIndex
          }

          // Don't add an unnecessary blank line at the end when `*/` is on its own line.
          guard cleaned.firstIndex(where: { !$0.isWhitespace }) != nil else {
            break
          }

          let line = cleaned.prefix(upTo: index)
          lines.append(Line(line))
          cleaned = cleaned[index...].dropFirst()
        }

      default:
        break
      }
    }

    // Concatenate the lines into a single string, trimming any leading indentation that might be
    // present.
    guard
      let introducer = introducer,
      !lines.isEmpty,
      let firstLineIndex = lines.firstIndex(where: { !$0.text.isEmpty })
    else { return nil }

    let initialIndentation = indentationDistance(of: lines[firstLineIndex].text)
    var result = ""
    for line in lines[firstLineIndex...] {
      let countToDrop = min(initialIndentation, line.firstNonspaceDistance)
      result.append(contentsOf: "\(line.text.dropFirst(countToDrop))\n")
    }

    guard !result.isEmpty else { return nil }

    let commentStartDistance =
      triviaArray.distance(from: triviaArray.startIndex, to: commentStartIndex)
    self.text = result
    self.startIndex = trivia.index(trivia.startIndex, offsetBy: commentStartDistance)
    self.introducer = introducer
  }
}

/// Returns the distance from the start of the string to the first non-whitespace character.
private func indentationDistance(of text: Substring) -> Int {
  return text.distance(
    from: text.startIndex,
    to: text.firstIndex { !$0.isWhitespace } ?? text.endIndex
  )
}

/// Returns the number of contiguous whitespace characters (spaces and tabs only) that precede the
/// given trivia piece.
private func contiguousWhitespace(
  in trivia: [TriviaPiece],
  before index: Array<TriviaPiece>.Index
) -> Int {
  var index = index
  var whitespace = 0
  loop: while index != trivia.startIndex {
    index = trivia.index(before: index)
    switch trivia[index] {
    case .spaces(let count): whitespace += count
    case .tabs(let count): whitespace += count
    default: break loop
    }
  }
  return whitespace
}

/// Returns the number of characters considered block comment "ASCII art" at the beginning of the
/// given string.
private func asciiArtLength(of string: Substring, leadingSpaces: Int) -> Int {
  let spaces = string.prefix(leadingSpaces)
  if spaces.count != leadingSpaces {
    return 0
  }
  if spaces.contains(where: { !$0.isWhitespace }) {
    return 0
  }

  let string = string.dropFirst(leadingSpaces)
  if string.hasPrefix(" * ") {
    return leadingSpaces + 3
  }
  if string.hasPrefix(" *\n") {
    return leadingSpaces + 2
  }
  return 0
}

/// Returns the start index of the earliest comment in the Trivia if we work backwards and
/// skip through comments, newlines, and whitespace. Then we advance a bit forward to be sure
/// the returned index is actually a comment and not whitespace.
private func findCommentStartIndex(_ triviaArray: [TriviaPiece]) -> Array<TriviaPiece>.Index {
  func firstCommentIndex(_ slice: ArraySlice<TriviaPiece>) -> Array<TriviaPiece>.Index {
    return slice.firstIndex(where: {
      switch $0 {
      case .docLineComment, .docBlockComment:
        return true
      default:
        return false
      }
    }) ?? slice.endIndex
  }

  if let lastNonDocCommentIndex = triviaArray.lastIndex(where: {
    switch $0 {
    case .docBlockComment, .docLineComment,
      .newlines(1), .carriageReturns(1), .carriageReturnLineFeeds(1),
      .spaces, .tabs:
      return false
    default:
      return true
    }
  }) {
    let nextIndex = triviaArray.index(after: lastNonDocCommentIndex)
    return firstCommentIndex(triviaArray[nextIndex...])
  } else {
    return firstCommentIndex(triviaArray[...])
  }
}
