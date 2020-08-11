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

extension DeclSyntaxProtocol {
  /// Searches through the leading trivia of this decl for a documentation comment.
  var docComment: String? {
    guard let tok = firstToken else { return nil }
    var comment = [String]()

    // We need to skip trivia until we see the first comment. This trivia will include all the
    // spaces and newlines before the doc comment.
    var hasSeenFirstLineComment = false

    // Look through for discontiguous doc comments, separated by more than 1 newline.
    gatherComments: for piece in tok.leadingTrivia.reversed() {
      switch piece {
      case .docBlockComment(let text):
        // If we see a single doc block comment, then check to see if we've seen any line comments.
        // If so, then use the line comments so far. Otherwise, return this block comment.
        if hasSeenFirstLineComment {
          break gatherComments
        }
        let blockComment = text.components(separatedBy: "\n")
        // Removes the marks of the block comment.
        var isTheFirstLine = true
        let blockCommentWithoutMarks = blockComment.map { (line: String) -> String in
          // Only the first line of the block comment start with '/**'
          let markToRemove = isTheFirstLine ? "/**" : "* "
          let trimmedLine = line.trimmingCharacters(in: .whitespaces)
          if trimmedLine.starts(with: markToRemove) {
            let numCharsToRemove = isTheFirstLine ? markToRemove.count : markToRemove.count - 1
            isTheFirstLine = false
            return trimmedLine.hasSuffix("*/")
              ? String(trimmedLine.dropFirst(numCharsToRemove).dropLast(3)) : String(
                trimmedLine.dropFirst(numCharsToRemove))
          } else if trimmedLine == "*" {
            return ""
          } else if trimmedLine.hasSuffix("*/") {
            return String(line.dropLast(3))
          }
          isTheFirstLine = false
          return line
        }

        return blockCommentWithoutMarks.joined(separator: "\n").trimmingCharacters(in: .newlines)
      case .docLineComment(let text):
        // Mark that we've started grabbing sequential line comments and append it to the
        // comment buffer.
        hasSeenFirstLineComment = true
        comment.append(text)
      case .newlines(let n), .carriageReturns(let n), .carriageReturnLineFeeds(let n):
        // Only allow for 1 newline between doc line comments, but allow for newlines between the
        // doc comment and the declaration.
        guard n == 1 || !hasSeenFirstLineComment else { break gatherComments }
      case .spaces, .tabs:
        // Skip all spaces/tabs. They're irrelevant here.
        break
      default:
        if hasSeenFirstLineComment {
          break gatherComments
        }
      }
    }

    /// Removes the "///" from every line of comment
    let docLineComments = comment.reversed().map { $0.dropFirst(3) }
    return comment.isEmpty ? nil : docLineComments.joined(separator: "\n")
  }

  var docCommentInfo: ParseComment? {
    guard let docComment = self.docComment else { return nil }
    let comments = docComment.components(separatedBy: .newlines)
    var params = [ParseComment.Parameter]()
    var commentParagraphs = [String]()
    var currentSection: DocCommentSection = .commentParagraphs
    var returnsDescription: String?
    var throwsDescription: String?
    // Takes the first sentence of the comment, and counts the number of lines it uses.
    let oneSenteceSummary = docComment.components(separatedBy: ".").first
    let numOfOneSentenceLines = oneSenteceSummary!.components(separatedBy: .newlines).count

    // Iterates to all the comments after the one sentence summary to find the parameter(s)
    // return tags and get their description.
    for line in comments.dropFirst(numOfOneSentenceLines) {
      let trimmedLine = line.trimmingCharacters(in: .whitespaces)

      if trimmedLine.starts(with: "- Parameters") {
        currentSection = .parameters
      } else if trimmedLine.starts(with: "- Parameter") {
        // If it's only a parameter it's information is inline with the parameter
        // tag, just after the ':'.
        guard let index = trimmedLine.firstIndex(of: ":") else { continue }
        let name = trimmedLine.dropFirst("- Parameter".count)[..<index]
          .trimmingCharacters(in: .init(charactersIn: " -:"))
        let summary = trimmedLine[index...].trimmingCharacters(in: .init(charactersIn: " -:"))
        params.append(ParseComment.Parameter(name: name, summary: summary))
      } else if trimmedLine.starts(with: "- Throws:") {
        currentSection = .throwsDescription
        throwsDescription = String(trimmedLine.dropFirst("- Throws:".count))
      } else if trimmedLine.starts(with: "- Returns:") {
        currentSection = .returnsDescription
        returnsDescription = String(trimmedLine.dropFirst("- Returns:".count))
      } else {
        switch currentSection {
        case .parameters:
          // After the paramters tag is found the following lines should be the parameters
          // description.
          guard let index = trimmedLine.firstIndex(of: ":") else { continue }
          let name = trimmedLine[..<index].trimmingCharacters(in: .init(charactersIn: " -:"))
          let summary = trimmedLine[index...].trimmingCharacters(in: .init(charactersIn: " -:"))
          params.append(ParseComment.Parameter(name: name, summary: summary))

        case .returnsDescription:
          // Appends the return description that is not inline with the return tag.
          returnsDescription!.append(trimmedLine)

        case .throwsDescription:
          // Appends the throws description that is not inline with the throws tag.
          throwsDescription!.append(trimmedLine)

        case .commentParagraphs:
          if trimmedLine != "" {
            commentParagraphs.append(" " + trimmedLine)
          }
        }
      }
    }

    return ParseComment(
      oneSentenceSummary: oneSenteceSummary,
      commentParagraphs: commentParagraphs,
      parameters: params,
      throwsDescription: throwsDescription,
      returnsDescription: returnsDescription
    )
  }
}

private enum DocCommentSection {
    case commentParagraphs
    case parameters
    case throwsDescription
    case returnsDescription
}

struct ParseComment {
  struct Parameter {
    var name: String
    var summary: String
  }

  var oneSentenceSummary: String?
  var commentParagraphs: [String]?
  var parameters: [Parameter]?
  var throwsDescription: String?
  var returnsDescription: String?
}
