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

/// Block comments should be avoided in favor of line comments.
///
/// Lint: If a block comment appears, a lint error is raised.
///
/// Format: If a block comment appears on its own on a line, or if a block comment spans multiple
///         lines without appearing on the same line as code, it will be replaced with multiple
///         single-line comments.
///         If a block comment appears inline with code, it will be removed and hoisted to the line
///         above the code it appears on.
///
/// - SeeAlso: https://google.github.io/swift#non-documentation-comments
public final class NoBlockComments: SyntaxFormatRule {
  public override func visit(_ token: TokenSyntax) -> Syntax {
    var pieces = [TriviaPiece]()
    var hasBlockComment = false
    var validToken = token

    // Ensures that the comments that appear inline with code have
    // at least 2 spaces before the `//`.
    if let nextToken = token.nextToken,
      containsBlockCommentInline(trivia: nextToken.leadingTrivia)
    {
      hasBlockComment = true
      validToken = addSpacesBeforeComment(token)
    }

    // Ensures that all block comments are replaced with line comment,
    // unless the comment is between tokens on the same line.
    for piece in token.leadingTrivia {
      if case .blockComment(let text) = piece,
        !commentIsBetweenCode(token)
      {
        diagnose(.avoidBlockComment, on: token)
        hasBlockComment = true
        let lineCommentText = convertBlockCommentsToLineComments(text)
        let lineComment = TriviaPiece.lineComment(lineCommentText)
        pieces.append(lineComment)
      } else {
        pieces.append(piece)
      }
    }
    validToken = validToken.withLeadingTrivia(Trivia(pieces: pieces))
    return hasBlockComment ? validToken : token
  }

  /// Returns a Boolean value indicating if the given trivia has a piece trivia
  /// of block comment inline with code.
  private func containsBlockCommentInline(trivia: Trivia) -> Bool {
    // When the comment isn't inline with code, it doesn't need to
    // to check that there are two spaces before the line comment.
    if let firstPiece = trivia.first {
      if case .newlines(_) = firstPiece {
        return false
      }
    }
    for piece in trivia {
      if case .blockComment(_) = piece {
        return true
      }
    }
    return false
  }

  /// Indicates if a block comment is between tokens on the same line.
  /// If it does, it should only raise a lint error.
  private func commentIsBetweenCode(_ token: TokenSyntax) -> Bool {
    let hasCommentBetweenCode = token.leadingTrivia.isBetweenTokens
    if hasCommentBetweenCode {
      diagnose(.avoidBlockCommentBetweenCode, on: token)
    }
    return hasCommentBetweenCode
  }

  /// Ensures there is always at least 2 spaces before the comment.
  private func addSpacesBeforeComment(_ token: TokenSyntax) -> TokenSyntax {
    let numSpaces = token.trailingTrivia.numberOfSpaces
    if numSpaces < 2 {
      let addSpaces = 2 - numSpaces
      return token.withTrailingTrivia(
        token.trailingTrivia.appending(.spaces(addSpaces)))
    }
    return token
  }

  /// Receives the text of a Block comment and converts it to a Line Comment format text.
  private func convertBlockCommentsToLineComments(_ text: String) -> String {
    // Removes the '/*', '*/', the extra spaces and newlines from the comment.
    let textTrim = text.dropFirst(2).dropLast(2)
      .trimmingCharacters(in: .whitespacesAndNewlines)

    let splitComment = textTrim.split(separator: "\n", omittingEmptySubsequences: false)
    var lineCommentText = [String]()

    for line in splitComment {
      let startsComment = line.starts(with: " ") || line.count == 0 ? "//" : "// "
      lineCommentText.append(startsComment + line)
    }
    return lineCommentText.joined(separator: "\n")
  }
}

extension Diagnostic.Message {
  static let avoidBlockComment = Diagnostic.Message(
    .warning, "replace block comment with line comments")

  static let avoidBlockCommentBetweenCode = Diagnostic.Message(
    .warning, "remove block comment inline with code")
}

extension Trivia {
  /// Indicates if the trivia is between tokens, for example
  /// if a leading trivia that contains a comment, doesn't starts
  /// and finishes with a new line then the comment is between tokens.
  var isBetweenTokens: Bool {
    var beginsNewLine = false
    var endsNewLine = false

    if let firstPiece = self.first,
      let lastPiece = self.reversed().first
    {
      if case .newlines(_) = firstPiece {
        beginsNewLine = true
      }
      if case .newlines(_) = lastPiece {
        endsNewLine = true
      }
    }
    return !beginsNewLine && !endsNewLine
  }
}
