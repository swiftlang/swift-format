//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2025 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import Markdown
import SwiftSyntax

/// Joins comments that were hard-wrapped across multiple lines back into one line when the combined
/// text still fits within the configured line length.
///
/// The rule reflows only line comments (`//`) and documentation line comments (`///`); it leaves
/// block comments (`/* ... */` and `/** ... */`) untouched. It parses the body of each comment as
/// Markdown and joins only lines that belong to the same paragraph. The Markdown parser recognizes
/// lists, headings, indented and fenced code blocks, block quotes, and thematic breaks, and the
/// rule leaves all of them untouched, along with blank lines between paragraphs. The rule also
/// never merges "divider" lines that contain no words (for example `//===----===//`) or lines
/// matching `reflowComments.preservedLinePrefixes`. If a comment block contains a `//===...===//`
/// file header, the rule leaves the whole block alone. `reflowComments.reflowedCommentKinds`
/// controls which kinds of comments the rule reflows.
///
/// Lint: If two adjacent comment lines in the same paragraph can be joined without exceeding
///       `lineLength`, a lint error is raised.
///
/// Format: Adjacent comment lines in the same paragraph that can be joined without exceeding
///         `lineLength` are merged.
@_spi(Rules)
public final class ReflowComments: SyntaxFormatRule {
  public override class var isOptIn: Bool { return true }

  private var kindsToReflow: Set<ReflowCommentsConfiguration.CommentKind> {
    context.configuration.reflowComments.reflowedCommentKinds
  }

  private var tabWidth: Int { context.configuration.tabWidth }

  private var lineLength: Int { context.configuration.lineLength }

  public override func visit(_ token: TokenSyntax) -> TokenSyntax {
    let trivia = token.leadingTrivia
    guard trivia.contains(where: \.isComment) else { return token }
    guard !containsFileHeaderSeparator(trivia) else { return token }

    let joinableLineIndices = joinableCommentIndices(in: trivia)
    guard !joinableLineIndices.isEmpty else { return token }

    var output: [TriviaPiece] = []
    var changed = false
    var index = 0
    while index < trivia.count {
      guard let kind = trivia[index].commentKind, let configKind = kind.configKind, kindsToReflow.contains(configKind)
      else {
        output.append(trivia[index])
        index += 1
        continue
      }

      let indent = trivia.indentWidth(before: index, tabWidth: tabWidth)
      var content = lineContent(trivia[index], kind: kind)
      var lastMerged = index
      while let next = nextLineCommentIndex(in: trivia, after: lastMerged, kind: kind),
        joinableLineIndices.contains(next)
      {
        let body = continuationContent(trivia[next], kind: kind)
        guard fits(content, body, renderedPrefixWidth: indent + kind.prefixLength + 1) else { break }
        diagnose(.hardWrappedComment, on: token, anchor: .leadingTrivia(next))
        content += " " + body
        lastMerged = next
        changed = true
      }

      // Leave an unmerged comment exactly as written; only rebuild when something merged.
      output.append(lastMerged == index ? trivia[index] : TriviaPiece(commentKind: kind, content: content))
      index = lastMerged + 1
    }

    guard changed else { return token }
    var result = token
    result.leadingTrivia = Trivia(pieces: output)
    return result
  }

  // MARK: - Line comment merging

  /// The index of the next same-kind line comment following `index`, if it is separated from it by
  /// exactly one newline. Returns nil at a blank line (two or more newlines), any non-comment /
  /// non-whitespace piece, a comment of a different kind, or the end of the trivia.
  private func nextLineCommentIndex(in trivia: Trivia, after index: Int, kind: Comment.Kind) -> Int? {
    var newlineCount = 0
    var j = index + 1
    while j < trivia.count {
      switch trivia[j] {
      case .newlines(let n), .carriageReturns(let n), .carriageReturnLineFeeds(let n):
        newlineCount += n
        j += 1
      case .spaces, .tabs:
        j += 1
      case .lineComment, .docLineComment:
        guard newlineCount == 1, trivia[j].commentKind == kind else { return nil }
        return j
      default:
        return nil
      }
    }
    return nil
  }

  /// One line of a run of consecutive same-kind line comments.
  private struct CommentLine {
    var triviaIndex: Int
    /// Only reflowable prose lines are eligible for a paragraph id.
    var isReflowable: Bool
    /// The joinable paragraph this line belongs to, or nil if it can never be joined with a neighbor.
    var paragraphID: Int?
  }

  /// Walks a parsed comment run to tag each reflowable line with the ID of the paragraph that
  /// contains it.
  private struct ParagraphTagger: MarkupWalker {
    /// The run being tagged; `paragraphID` is filled in as paragraphs are visited.
    var run: [CommentLine]
    private var nextParagraphID = 0

    // Skip block quotes entirely; their lines are never joined.
    mutating func visitBlockQuote(_ blockQuote: BlockQuote) {}

    mutating func visitParagraph(_ paragraph: Paragraph) {
      defer { nextParagraphID += 1 }
      guard let range = paragraph.range else { return }
      let lowerLine = range.lowerBound.line - 1
      let upperLine = range.upperBound.line - 1
      guard lowerLine <= upperLine else { return }
      for line in lowerLine...upperLine where line >= 0 && line < run.count && run[line].isReflowable {
        run[line].paragraphID = nextParagraphID
      }
    }
  }

  /// Returns the trivia indices of every line comment that may be joined with the line comment
  /// immediately before it.
  private func joinableCommentIndices(in trivia: Trivia) -> Set<Int> {
    var result = Set<Int>()
    var runStart = 0
    while runStart < trivia.count {
      guard let kind = trivia[runStart].commentKind, kind.isLine else {
        runStart += 1
        continue
      }

      let run = commentRun(in: trivia, from: runStart, kind: kind)
      for k in 1..<run.count where canJoin(run, at: k) {
        result.insert(run[k].triviaIndex)
      }
      runStart = run.last!.triviaIndex + 1
    }
    return result
  }

  /// Gathers a maximal run of same-kind line comments separated by single newlines, starting at
  /// `start`, and tags each line with the joinable paragraph it belongs to.
  private func commentRun(in trivia: Trivia, from start: Int, kind: Comment.Kind) -> [CommentLine] {
    var run: [CommentLine] = []
    var body = ""
    var index: Int? = start
    while let i = index {
      let content = lineContent(trivia[i], kind: kind)
      if !run.isEmpty { body += "\n" }
      body += content
      run.append(CommentLine(triviaIndex: i, isReflowable: isReflowableProse(content), paragraphID: nil))
      index = nextLineCommentIndex(in: trivia, after: i, kind: kind)
    }

    // A join needs two adjacent reflowable-prose lines; without such a pair (including any
    // single-line run) nothing can merge, so skip the Markdown parse and leave every line unpaired.
    guard (1..<run.count).contains(where: { run[$0].isReflowable && run[$0 - 1].isReflowable }) else {
      return run
    }

    let document = Document(parsing: body, options: [.disableSmartOpts])
    var tagger = ParagraphTagger(run: run)
    tagger.visit(document)
    return tagger.run
  }

  /// Returns the text of a line comment after removing its delimiter and one following space.
  private func lineContent(_ piece: TriviaPiece, kind: Comment.Kind) -> String {
    var content = String(piece.commentText.dropFirst(kind.prefixLength))
    // Strip only one space for now. Extra leading spaces can be meaningful formatting, for example
    // an indented code block:
    //
    //     foo()
    //     bar()
    if content.hasPrefix(" ") { content.removeFirst() }
    return content
  }

  /// Like `lineContent`, but also drops any remaining leading whitespace. Use this for a
  /// continuation line that merges into the preceding line, for example the wrapped remainder of a
  /// DocC parameter description.
  private func continuationContent(_ piece: TriviaPiece, kind: Comment.Kind) -> String {
    return String(lineContent(piece, kind: kind).drop(while: \.isSpaceOrTab))
  }

  // MARK: - Shared predicates

  /// Whether line `k` of a run may be joined with line `k - 1`: both belong to the same joinable
  /// paragraph. A nil `paragraphID` marks a line that can never join.
  private func canJoin(_ run: [CommentLine], at k: Int) -> Bool {
    guard let id = run[k].paragraphID else { return false }
    return run[k - 1].paragraphID == id
  }

  /// Whether a line's content is ordinary prose that may be reflowed, as opposed to a divider or a
  /// line protected by the configured prefix rules.
  private func isReflowableProse(_ content: String) -> Bool {
    guard !content.isEmpty, !isBanner(content), !isDivider(content) else { return false }
    let preservedPrefixes = context.configuration.reflowComments.preservedLinePrefixes
    return !preservedPrefixes.contains(where: { content.hasPrefix($0) })
  }

  /// Whether a line is a divider or a decorated banner that must never be joined.
  ///
  /// Covers word-free rules (for example `------`, `=-=-=-`) and titled banners that begin with a
  /// run of rule characters (for example `===--- Section ---===//`, `=== Notes ===`). 
  private func isBanner(_ content: String) -> Bool {
    let ruleChars: Set<Character> = ["=", "-", "*", "_", "#", "~"]
    let trimmed = content.drop(while: \.isSpaceOrTab)
    if let first = trimmed.first, ruleChars.contains(first),
      trimmed.prefix(while: { $0 == first }).count >= 3
    {
      return true
    }
    return false
  }

  /// A "divider" line contains no letters or digits, for example `------` or `===----===//`.
  private func isDivider<S: StringProtocol>(_ content: S) -> Bool {
    return !content.contains { $0.isLetter || $0.isNumber }
  }

  /// Whether any comment among the given trivia pieces is a `//===...===//` file-header sentinel.
  private func containsFileHeaderSeparator(_ pieces: Trivia) -> Bool {
    for piece in pieces {
      guard let kind = piece.commentKind, kind.isLine else { continue }
      // Inspect the raw text so no stripped copy is allocated.
      var body = piece.commentText.dropFirst(kind.prefixLength)
      if body.first == " " { body = body.dropFirst() }
      if body.hasPrefix("===") && isDivider(body) { return true }
    }
    return false
  }

  private func fits(_ content: String, _ addition: String, renderedPrefixWidth: Int) -> Bool {
    return renderedPrefixWidth + content.count + 1 + addition.count <= lineLength
  }
}

extension Comment.Kind {
  /// The configuration kind that gates this comment kind, or nil for block comments, which this
  /// rule does not reflow.
  fileprivate var configKind: ReflowCommentsConfiguration.CommentKind? {
    switch self {
    case .line: return .line
    case .docLine: return .docLine
    case .block, .docBlock: return nil
    }
  }

  fileprivate var isLine: Bool { self == .line || self == .docLine }
}

extension TriviaPiece {
  /// The comment kind corresponding to this trivia piece, or nil if it is not a comment.
  fileprivate var commentKind: Comment.Kind? {
    switch self {
    case .lineComment: return .line
    case .docLineComment: return .docLine
    case .blockComment: return .block
    case .docBlockComment: return .docBlock
    default: return nil
    }
  }

  fileprivate init(commentKind kind: Comment.Kind, content: String) {
    let text = kind.prefix + " " + content
    switch kind {
    case .docLine:
      self = .docLineComment(text)
    case .line:
      self = .lineComment(text)
    case .block:
      self = .blockComment(text)
    case .docBlock:
      self = .docBlockComment(text)
    }
  }

  /// The source text of a comment trivia piece, or the empty string for non-comment pieces.
  fileprivate var commentText: String {
    switch self {
    case .lineComment(let text), .docLineComment(let text),
      .blockComment(let text), .docBlockComment(let text):
      return text
    default:
      return ""
    }
  }
}

extension Character {
  fileprivate var isSpaceOrTab: Bool { self == " " || self == "\t" }
}

extension Finding.Message {
  fileprivate static let hardWrappedComment: Finding.Message =
    "join this comment with the preceding line"
}
