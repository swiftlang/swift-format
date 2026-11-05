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
import Markdown
import SwiftSyntax

extension StringProtocol {
  /// Trims whitespace from the end of a string, returning a substring view with no trailing
  /// whitespace.
  ///
  /// If the string is only whitespace, an empty substring is returned.
  ///
  /// - Returns: The substring with trailing whitespace removed.
  func trimmingTrailingWhitespace() -> Substring {
    let sub = Substring(self)
    let utf8 = sub.utf8
    var end = utf8.endIndex
    while end > utf8.startIndex {
      let prev = utf8.index(before: end)
      guard utf8[prev].isWhitespace else { break }
      end = prev
    }
    return sub[..<end]
  }

  /// Trims leading and trailing spaces and tabs, returning a substring view.
  func trimmingSpacesAndTabs() -> Substring {
    let sub = Substring(self)
    let utf8 = sub.utf8
    var start = utf8.startIndex
    let endLimit = utf8.endIndex
    while start < endLimit {
      let byte = utf8[start]
      guard byte == UInt8(ascii: " ") || byte == UInt8(ascii: "\t") else { break }
      start = utf8.index(after: start)
    }
    var end = endLimit
    while end > start {
      let prev = utf8.index(before: end)
      let byte = utf8[prev]
      guard byte == UInt8(ascii: " ") || byte == UInt8(ascii: "\t") else { break }
      end = prev
    }
    return sub[start..<end]
  }

  /// Returns `true` if the string is empty or contains only spaces and tabs.
  var isBlankSpacesOrTabs: Bool {
    return utf8.allSatisfy { $0 == UInt8(ascii: " ") || $0 == UInt8(ascii: "\t") }
  }
}

extension UTF8.CodeUnit {
  /// Checks if the UTF-8 code unit represents a whitespace character.
  ///
  /// - Returns: `true` if the code unit represents a whitespace character, otherwise `false`.
  var isWhitespace: Bool {
    switch self {
    case UInt8(ascii: " "), UInt8(ascii: "\n"), UInt8(ascii: "\t"), UInt8(ascii: "\r"), /*VT*/ 0x0B, /*FF*/ 0x0C:
      return true
    default:
      return false
    }
  }
}

struct Comment {
  enum Kind {
    case line, docLine, block, docBlock

    /// The length of the characters starting the comment.
    var prefixLength: Int {
      switch self {
      // `//`, `/*`
      case .line, .block: return 2
      // `///`, `/**`
      case .docLine, .docBlock: return 3
      }
    }

    var prefix: String {
      switch self {
      case .line: return "//"
      case .block: return "/*"
      case .docBlock: return "/**"
      case .docLine: return "///"
      }
    }
  }

  let kind: Kind
  var text: [String]
  var length: Int
  // what was the leading indentation, if any, that preceded this comment?
  var leadingIndent: Indent?

  init(kind: Kind, leadingIndent: Indent?, text: String) {
    self.kind = kind
    self.leadingIndent = leadingIndent

    switch kind {
    case .line, .docLine:
      self.length = text.count
      self.text = [text]
      self.text[0].removeFirst(kind.prefixLength)

    case .block, .docBlock:
      var fulltext: String = text
      fulltext.removeFirst(kind.prefixLength)
      fulltext.removeLast(2)
      let lines = fulltext.split(separator: "\n", omittingEmptySubsequences: false)

      // The last line in a block style comment contains the "*/" pattern to end the comment. The
      // trailing space(s) need to be kept in that line to have space between text and "*/".
      var trimmedLines: [String] = []
      trimmedLines.reserveCapacity(lines.count)
      for line in lines.dropLast() {
        trimmedLines.append(String(line.trimmingTrailingWhitespace()))
      }
      if let lastLine = lines.last {
        trimmedLines.append(String(lastLine))
      }
      self.text = trimmedLines
      self.length = self.text.reduce(0, { $0 + $1.count }) + kind.prefixLength + 3
    }
  }

  func print(indent: [Indent], shouldIndentBlankLines: Bool = true) -> String {
    switch self.kind {
    case .line, .docLine:
      let separator = "\n" + indent.indentation() + kind.prefix
      let trimmedLines = self.text.map { $0.trimmingTrailingWhitespace() }
      return kind.prefix + trimmedLines.joined(separator: separator)
    case .block, .docBlock:
      let separator = "\n"

      // if all the lines after the first matching leadingIndent, replace that prefix with the
      // current indentation level
      if let leadingIndent {
        let rest = self.text.dropFirst()

        let hasLeading = rest.allSatisfy {
          let result = $0.hasPrefix(leadingIndent.text) || $0.isEmpty
          return result
        }
        if hasLeading, let first = self.text.first, !rest.isEmpty {
          let indentation = indent.indentation()
          let restStr = rest.map {
            guard !$0.isEmpty else {
              return shouldIndentBlankLines ? indentation : ""
            }
            let stripped = $0.dropFirst(leadingIndent.text.count)
            return indentation + stripped
          }.joined(separator: separator)
          return kind.prefix + first + separator + restStr + "*/"
        }
      }

      return kind.prefix + self.text.joined(separator: separator) + "*/"
    }
  }

  mutating func addText(_ text: [String]) {
    for line in text {
      self.text.append(line)
      self.length += line.count + self.kind.prefixLength + 1
    }
  }

  /// Returns `true` if `line` (after stripping the comment introducer) is a built-in
  /// `swift-format-ignore` or `swift-format-ignore-file` directive.
  private static func isBuiltInIgnorePragma(_ line: Substring) -> Bool {
    let trimmed = line.drop { $0 == " " || $0 == "\t" }
    guard trimmed.utf8.starts(with: "swift-format-ignore".utf8) else { return false }
    var rest = trimmed.dropFirst("swift-format-ignore".count)
    if rest.utf8.starts(with: "-file".utf8) {
      rest = rest.dropFirst("-file".count)
    }
    rest = rest.drop { $0 == " " || $0 == "\t" }
    return rest.isEmpty || rest.utf8.first == UInt8(ascii: ":")
  }

  /// Compiles any user-configured `commentPragmas` regex patterns.
  static func compilePragmaRegexes(from patterns: [String]) -> [Regex<AnyRegexOutput>] {
    var result: [Regex<AnyRegexOutput>] = []
    result.reserveCapacity(patterns.count)
    for pattern in patterns {
      if let regex = try? Regex(pattern).anchorsMatchLineEndings() {
        result.append(regex)
      }
    }
    return result
  }

  /// Returns the set of 0-based line indices in `lines` that overlap any match of `pragmaRegexes`
  /// against the joined multi-line comment text.
  private static func pragmaLineIndices(
    in lines: [Substring],
    pragmaRegexes: [Regex<AnyRegexOutput>]
  ) -> Set<Int> {
    guard !lines.isEmpty, !pragmaRegexes.isEmpty else { return [] }

    // Join all lines with newlines and record the character range of each line in the joined string
    // so multi-line regex patterns can match across line breaks.
    let joined = lines.joined(separator: "\n")
    let joinedUTF8 = joined.utf8
    var lineRanges: [Range<String.Index>] = []
    lineRanges.reserveCapacity(lines.count)
    var currentStart = joinedUTF8.startIndex
    for (idx, line) in lines.enumerated() {
      let currentEnd = joinedUTF8.index(currentStart, offsetBy: line.utf8.count)
      lineRanges.append(currentStart..<currentEnd)
      if idx < lines.count - 1 {
        currentStart = joinedUTF8.index(after: currentEnd)
      }
    }

    // Mark every line whose character range overlaps any non-empty regex match.
    var matchedLines = Set<Int>()
    for regex in pragmaRegexes {
      for match in joined.matches(of: regex) {
        let matchRange = match.range
        guard !matchRange.isEmpty else { continue }

        // Binary-search `lineRanges` for the first line that ends after `matchRange.lowerBound`
        // (or is an empty line at `matchRange.lowerBound`).
        var low = 0
        var high = lineRanges.count
        while low < high {
          let mid = (low + high) / 2
          let midRange = lineRanges[mid]
          if midRange.upperBound > matchRange.lowerBound
            || (midRange.isEmpty && midRange.lowerBound >= matchRange.lowerBound)
          {
            high = mid
          } else {
            low = mid + 1
          }
        }

        var lineIdx = low
        while lineIdx < lineRanges.count && lineRanges[lineIdx].lowerBound < matchRange.upperBound {
          matchedLines.insert(lineIdx)
          lineIdx += 1
        }
      }
    }
    return matchedLines
  }

  /// Prints the comment with its Markdown content reflowed to fit within `maxLineLength`.
  func printReflowed(
    indent: [Indent],
    maxLineLength: Int,
    tabWidth: Int,
    behavior: ReflowCommentsConfiguration.Behavior,
    shouldIndentBlankLines: Bool = true,
    pragmaRegexes: [Regex<AnyRegexOutput>] = [],
    unreflowed: String? = nil
  ) -> String {
    func fallbackUnreflowed() -> String {
      return unreflowed ?? self.print(indent: indent, shouldIndentBlankLines: shouldIndentBlankLines)
    }

    guard !behavior.isNever, let leadingIndent else {
      return fallbackUnreflowed()
    }

    // Fast path: if we are only wrapping overlong lines (or the comment is a single line) and no
    // line exceeds `maxLineLength`, avoid parsing Markdown altogether.
    let indentLength = indent.length(tabWidth: tabWidth)
    let preserveLineBreaks = (behavior == .onlyLinesOverLength)
    if (preserveLineBreaks || self.text.count == 1)
      && !self.exceedsMaxLineLength(
        indentLength: indentLength,
        leadingIndent: leadingIndent,
        maxLineLength: maxLineLength,
        shouldIndentBlankLines: shouldIndentBlankLines
      )
    {
      return fallbackUnreflowed()
    }

    switch self.kind {
    case .line, .docLine:
      return printReflowedLineComment(
        indent: indent,
        indentLength: indentLength,
        maxLineLength: maxLineLength,
        preserveLineBreaks: preserveLineBreaks,
        pragmaRegexes: pragmaRegexes,
        fallbackUnreflowed: fallbackUnreflowed
      )
    case .block, .docBlock:
      return printReflowedBlockComment(
        indent: indent,
        indentLength: indentLength,
        leadingIndent: leadingIndent,
        maxLineLength: maxLineLength,
        preserveLineBreaks: preserveLineBreaks,
        shouldIndentBlankLines: shouldIndentBlankLines,
        pragmaRegexes: pragmaRegexes,
        fallbackUnreflowed: fallbackUnreflowed
      )
    }
  }

  /// Returns `true` if any line in the comment exceeds `maxLineLength` once `indentLength` is
  /// accounted for.
  private func exceedsMaxLineLength(
    indentLength: Int,
    leadingIndent: Indent,
    maxLineLength: Int,
    shouldIndentBlankLines: Bool
  ) -> Bool {
    switch self.kind {
    case .line, .docLine:
      let baseLength = indentLength + kind.prefixLength
      return self.text.contains { line in
        // Fast path: UTF-8 byte count is O(1) and always >= Character count.
        guard baseLength + line.utf8.count > maxLineLength else { return false }
        return baseLength + line.trimmingTrailingWhitespace().count > maxLineLength
      }
    case .block, .docBlock:
      guard let firstLine = self.text.first else { return false }
      if self.text.count == 1 {
        guard indentLength + kind.prefixLength + firstLine.utf8.count + 2 > maxLineLength else {
          return false
        }
        return indentLength + kind.prefixLength + firstLine.count + 2 > maxLineLength
      }
      if indentLength + kind.prefixLength + firstLine.utf8.count > maxLineLength
        && indentLength + kind.prefixLength + firstLine.count > maxLineLength
      {
        return true
      }
      let rest = self.text.dropFirst()
      let leadingIndentText = leadingIndent.text
      let leadingIndentUTF8Count = leadingIndentText.utf8.count
      let hasLeading = rest.allSatisfy { $0.hasPrefix(leadingIndentText) || $0.isEmpty }
      for (offset, line) in rest.enumerated() {
        let isLast = (offset == rest.count - 1)
        let closingLength = isLast ? 2 : 0
        if hasLeading {
          if line.isEmpty {
            if (shouldIndentBlankLines ? indentLength : 0) + closingLength > maxLineLength {
              return true
            }
          } else if indentLength + (line.utf8.count - leadingIndentUTF8Count) + closingLength > maxLineLength
            && indentLength + (line.count - leadingIndentUTF8Count) + closingLength > maxLineLength
          {
            return true
          }
        } else if line.utf8.count + closingLength > maxLineLength
          && line.count + closingLength > maxLineLength
        {
          return true
        }
      }
      return false
    }
  }

  /// Reflows a sequence of `//` or `///` line comments while preserving banner and pragma lines
  /// verbatim.
  private func printReflowedLineComment(
    indent: [Indent],
    indentLength: Int,
    maxLineLength: Int,
    preserveLineBreaks: Bool,
    pragmaRegexes: [Regex<AnyRegexOutput>],
    fallbackUnreflowed: () -> String
  ) -> String {
    // Strip trailing whitespace and identify any lines matched by pragma regexes (after removing
    // the single space that follows the `//` or `///` prefix).
    let trimmedLines = self.text.map { $0.trimmingTrailingWhitespace() }
    let pragmaLines: Set<Int>
    if pragmaRegexes.isEmpty {
      pragmaLines = []
    } else {
      let contentLines = trimmedLines.map { line -> Substring in
        line.hasPrefix(" ") ? line.dropFirst() : line
      }
      pragmaLines = Self.pragmaLineIndices(in: contentLines, pragmaRegexes: pragmaRegexes)
    }
    let availableWidth = maxLineLength - indentLength - kind.prefixLength - 1
    var outputLines: [String] = []
    outputLines.reserveCapacity(trimmedLines.count)
    var currentSegment: [Substring] = []

    // Reflows the accumulated segment of normal comment lines while preserving leading and trailing
    // blank comment lines (`//` or `///`) around the segment.
    func flushSegment() {
      guard !currentSegment.isEmpty else { return }
      defer { currentSegment.removeAll(keepingCapacity: true) }

      let leadingEmptyCount = currentSegment.prefix { $0.isEmpty }.count
      if leadingEmptyCount == currentSegment.count {
        for _ in 0..<leadingEmptyCount {
          outputLines.append(kind.prefix)
        }
        return
      }
      let trailingEmptyCount = currentSegment.reversed().prefix { $0.isEmpty }.count
      let bodyRawLines = currentSegment[leadingEmptyCount..<(currentSegment.count - trailingEmptyCount)]

      for _ in 0..<leadingEmptyCount {
        outputLines.append(kind.prefix)
      }

      let markdownLines = bodyRawLines.map { line -> Substring in
        line.hasPrefix(" ") ? line.dropFirst() : line
      }
      let reflowedLines = MarkdownReflower.reflow(
        lines: markdownLines,
        firstLineWidth: availableWidth,
        continuationWidth: availableWidth,
        lastLineReservedSuffixLength: 0,
        preserveLineBreaks: preserveLineBreaks
      )
      for mdLine in reflowedLines {
        if mdLine.isEmpty {
          outputLines.append(kind.prefix)
        } else {
          outputLines.append(kind.prefix + " " + mdLine)
        }
      }

      for _ in 0..<trailingEmptyCount {
        outputLines.append(kind.prefix)
      }
    }

    // Partition the comment around banner and pragma lines, which are emitted verbatim.
    for (idx, rawLine) in trimmedLines.enumerated() {
      let contentSlice = rawLine.hasPrefix(" ") ? rawLine.dropFirst() : rawLine
      if Self.isBannerLine(rawLine)
        || Self.isBuiltInIgnorePragma(contentSlice)
        || pragmaLines.contains(idx)
      {
        flushSegment()
        outputLines.append(kind.prefix + rawLine)
      } else {
        currentSegment.append(rawLine)
      }
    }
    flushSegment()

    guard !outputLines.isEmpty else { return fallbackUnreflowed() }
    let separator = "\n" + indent.indentation()
    return outputLines.joined(separator: separator)
  }

  /// Reflows a `/* ... */` or `/** ... */` block comment while preserving delimiter placement,
  /// interior `*` prefixes, and indentation.
  private func printReflowedBlockComment(
    indent: [Indent],
    indentLength: Int,
    leadingIndent: Indent,
    maxLineLength: Int,
    preserveLineBreaks: Bool,
    shouldIndentBlankLines: Bool,
    pragmaRegexes: [Regex<AnyRegexOutput>],
    fallbackUnreflowed: () -> String
  ) -> String {
    // Ensure all lines after the first share the comment's original `leadingIndent`; if not, leave
    // the comment unreflowed just as `print` leaves it unindented.
    guard let firstLine = self.text.first else {
      return fallbackUnreflowed()
    }
    let rest = self.text.dropFirst()
    let leadingIndentText = leadingIndent.text
    let leadingIndentUTF8Count = leadingIndentText.utf8.count
    let hasLeading = rest.allSatisfy {
      $0.hasPrefix(leadingIndentText) || $0.isEmpty
    }
    guard rest.isEmpty || hasLeading else {
      return fallbackUnreflowed()
    }

    var normalizedLines: [Substring] = []
    normalizedLines.reserveCapacity(self.text.count)
    normalizedLines.append(firstLine[...])
    for line in rest {
      if line.isEmpty {
        normalizedLines.append("")
      } else {
        normalizedLines.append(Substring(line.utf8.dropFirst(leadingIndentUTF8Count)))
      }
    }

    if normalizedLines.count == 1 && Self.isBannerLine(normalizedLines[0]) {
      return fallbackUnreflowed()
    }

    // Determine whether the opening `/*` / `/**` and closing `*/` delimiters appear on their own
    // lines or inline with comment text, and extract any inline closing delimiter (e.g. ` */` or
    // ` **/`).
    let opensOnOwnLine =
      normalizedLines.count > 1
      && normalizedLines[0].isBlankSpacesOrTabs

    let lastRaw = normalizedLines[normalizedLines.count - 1]
    let lastTrimmed = lastRaw.trimmingSpacesAndTabs()
    let closesOnOwnLine =
      normalizedLines.count > 1
      && (lastTrimmed.isEmpty || lastTrimmed.utf8.allSatisfy { $0 == UInt8(ascii: "*") })

    let ownLineClosingDelimiter: String
    let inlineClosingDelimiter: String
    if closesOnOwnLine {
      ownLineClosingDelimiter = lastRaw + "*/"
      inlineClosingDelimiter = ""
    } else {
      ownLineClosingDelimiter = ""
      let starsCount = lastRaw.utf8.reversed().prefix { $0 == UInt8(ascii: "*") }.count
      let beforeStars = lastRaw.dropLast(starsCount)
      if starsCount > 0 && beforeStars.utf8.last?.isWhitespace == true {
        let stars = String(repeating: "*", count: starsCount)
        inlineClosingDelimiter = " " + stars + "*/"
        normalizedLines[normalizedLines.count - 1] = beforeStars.trimmingTrailingWhitespace()
      } else if lastRaw.utf8.last?.isWhitespace == true {
        inlineClosingDelimiter = " */"
        normalizedLines[normalizedLines.count - 1] = lastRaw.trimmingTrailingWhitespace()
      } else {
        inlineClosingDelimiter = "*/"
      }
    }

    // Slice out the interior content lines between any standalone opening/closing delimiter lines.
    let startIdx = opensOnOwnLine ? 1 : 0
    let endIdx = closesOnOwnLine ? (normalizedLines.count - 1) : normalizedLines.count
    guard startIdx < endIdx else {
      return fallbackUnreflowed()
    }

    let rawContentLines = normalizedLines[startIdx..<endIdx]
    if rawContentLines.allSatisfy({ $0.isBlankSpacesOrTabs }) {
      return fallbackUnreflowed()
    }

    // Check if interior lines use ASCII art `*` prefixes (e.g. ` * ` or `* `).
    let interiorCandidateLines = opensOnOwnLine ? rawContentLines : rawContentLines.dropFirst()
    let starIndent: Substring? = {
      guard let firstInterior = interiorCandidateLines.first(where: { !$0.isBlankSpacesOrTabs }) else {
        return nil
      }
      let leadingWS = firstInterior.prefix { $0 == " " || $0 == "\t" }
      let leadingWSUTF8Count = leadingWS.utf8.count
      for line in interiorCandidateLines where !line.isBlankSpacesOrTabs {
        guard line.hasPrefix(leadingWS) else { return nil }
        let afterWS = Substring(line.utf8.dropFirst(leadingWSUTF8Count))
        guard afterWS.utf8.first == UInt8(ascii: "*") else { return nil }
        let afterStar = afterWS.dropFirst()
        guard
          afterStar.isEmpty
            || afterStar.utf8.first == UInt8(ascii: " ")
            || afterStar.utf8.first == UInt8(ascii: "\t")
        else {
          return nil
        }
      }
      return leadingWS
    }()

    let indentation = indent.indentation()
    let reservedSuffixLength = closesOnOwnLine ? 0 : inlineClosingDelimiter.utf8.count
    let firstLineLeadingSpace = (!opensOnOwnLine && rawContentLines[startIdx].hasPrefix(" ")) ? " " : ""

    // Compute the stripped Markdown lines, continuation prefixes, and available line widths for
    // whichever block-comment layout is used (`*`-prefixed, opening delimiter on its own line, or
    // opening delimiter inline with the first content line).
    let strippedLines: [Substring]
    let continuationLinePrefix: String
    let emptyContinuationLine: String
    let firstLineWidth: Int
    let continuationWidth: Int

    if let starIndent {
      let starPrefixEmpty = starIndent + "*"
      let starPrefixNonEmpty = starIndent + "* "
      let starPrefixEmptyUTF8Count = starPrefixEmpty.utf8.count
      strippedLines = rawContentLines.enumerated().map { (idx, line) in
        if idx == 0 && !opensOnOwnLine {
          return line.dropFirst(firstLineLeadingSpace.utf8.count).trimmingTrailingWhitespace()
        }
        if line.isBlankSpacesOrTabs {
          return ""
        }
        var afterStar = Substring(line.utf8.dropFirst(starPrefixEmptyUTF8Count))
        if afterStar.hasPrefix(" ") || afterStar.hasPrefix("\t") {
          afterStar = afterStar.dropFirst()
        }
        return afterStar.trimmingTrailingWhitespace()
      }
      continuationLinePrefix = indentation + starPrefixNonEmpty
      emptyContinuationLine = indentation + starPrefixEmpty
      continuationWidth = maxLineLength - indentLength - starPrefixNonEmpty.utf8.count
      firstLineWidth =
        opensOnOwnLine
        ? continuationWidth
        : (maxLineLength - indentLength - kind.prefixLength - firstLineLeadingSpace.utf8.count)
    } else if opensOnOwnLine {
      let commonIndent = Self.commonLeadingWhitespace(of: rawContentLines)
      let commonIndentUTF8Count = commonIndent.utf8.count
      strippedLines = rawContentLines.map { line -> Substring in
        guard !line.isEmpty else { return "" }
        return Substring(line.utf8.dropFirst(commonIndentUTF8Count)).trimmingTrailingWhitespace()
      }
      continuationLinePrefix = indentation + commonIndent
      emptyContinuationLine = shouldIndentBlankLines ? indentation : ""
      continuationWidth = maxLineLength - indentLength - commonIndentUTF8Count
      firstLineWidth = continuationWidth
    } else {
      let interiorSlice = rawContentLines.dropFirst()
      let continuationIndent =
        (interiorSlice.allSatisfy { $0.isEmpty })
        ? Substring(String(repeating: " ", count: kind.prefixLength + firstLineLeadingSpace.utf8.count))
        : Self.commonLeadingWhitespace(of: interiorSlice)
      let continuationIndentUTF8Count = continuationIndent.utf8.count

      var lines: [Substring] = []
      lines.reserveCapacity(rawContentLines.count)
      lines.append(
        rawContentLines[startIdx].dropFirst(firstLineLeadingSpace.utf8.count).trimmingTrailingWhitespace()
      )
      for line in interiorSlice {
        if line.isEmpty {
          lines.append("")
        } else if line.hasPrefix(continuationIndent) {
          lines.append(
            Substring(line.utf8.dropFirst(continuationIndentUTF8Count)).trimmingTrailingWhitespace()
          )
        } else {
          lines.append(line.trimmingSpacesAndTabs())
        }
      }
      strippedLines = lines
      continuationLinePrefix = indentation + continuationIndent
      emptyContinuationLine = shouldIndentBlankLines ? indentation : ""
      firstLineWidth = maxLineLength - indentLength - kind.prefixLength - firstLineLeadingSpace.utf8.count
      continuationWidth = maxLineLength - indentLength - continuationIndentUTF8Count
    }

    // Reflow the stripped Markdown lines and re-attach the block comment prefixes and delimiters.
    let reflowedLines = Self.reflowBlockBodyLines(
      strippedLines,
      firstLineWidth: firstLineWidth,
      continuationWidth: continuationWidth,
      lastLineReservedSuffixLength: reservedSuffixLength,
      preserveLineBreaks: preserveLineBreaks,
      pragmaRegexes: pragmaRegexes
    )
    guard !reflowedLines.isEmpty else { return fallbackUnreflowed() }

    var resultLines: [String] = []
    resultLines.reserveCapacity(reflowedLines.count + 2)
    if opensOnOwnLine {
      resultLines.append(kind.prefix)
      for mdLine in reflowedLines {
        resultLines.append(mdLine.isEmpty ? emptyContinuationLine : continuationLinePrefix + mdLine)
      }
    } else {
      let firstMd = reflowedLines[0]
      resultLines.append(firstMd.isEmpty ? kind.prefix : kind.prefix + firstLineLeadingSpace + firstMd)
      for mdLine in reflowedLines.dropFirst() {
        resultLines.append(mdLine.isEmpty ? emptyContinuationLine : continuationLinePrefix + mdLine)
      }
    }

    if closesOnOwnLine {
      resultLines.append(indentation + ownLineClosingDelimiter)
    } else {
      let lastIdx = resultLines.count - 1
      let lastLineColumnWidth = (lastIdx == 0 ? indentLength : 0) + resultLines[lastIdx].count
      if lastLineColumnWidth + inlineClosingDelimiter.count > maxLineLength {
        let trimmedClosing = String(inlineClosingDelimiter.trimmingSpacesAndTabs())
        if let starIndent {
          resultLines.append(indentation + starIndent + trimmedClosing)
        } else {
          resultLines.append(indentation + trimmedClosing)
        }
      } else {
        resultLines[lastIdx] += inlineClosingDelimiter
      }
    }
    return resultLines.joined(separator: "\n")
  }

  /// Returns the longest common leading whitespace prefix (`" "` or `"\t"`) shared by the non-empty
  /// lines in `lines`.
  private static func commonLeadingWhitespace(of lines: ArraySlice<Substring>) -> Substring {
    guard let firstNonEmpty = lines.first(where: { !$0.isEmpty }) else { return "" }
    var prefix = firstNonEmpty.prefix { $0 == " " || $0 == "\t" }
    for line in lines where !line.isEmpty {
      let prefixUTF8 = prefix.utf8
      let lineUTF8 = line.utf8
      var pIdx = prefixUTF8.startIndex
      var lIdx = lineUTF8.startIndex
      while pIdx < prefixUTF8.endIndex && lIdx < lineUTF8.endIndex && prefixUTF8[pIdx] == lineUTF8[lIdx] {
        pIdx = prefixUTF8.index(after: pIdx)
        lIdx = lineUTF8.index(after: lIdx)
      }
      prefix = prefix[..<pIdx]
      if prefix.isEmpty { break }
    }
    return prefix
  }

  /// Partitions the body lines of a block comment around banner and pragma lines and reflows each
  /// contiguous Markdown segment.
  private static func reflowBlockBodyLines(
    _ lines: [Substring],
    firstLineWidth: Int,
    continuationWidth: Int,
    lastLineReservedSuffixLength: Int,
    preserveLineBreaks: Bool,
    pragmaRegexes: [Regex<AnyRegexOutput>]
  ) -> [String] {
    let pragmaLines = pragmaLineIndices(in: lines, pragmaRegexes: pragmaRegexes)
    var output: [String] = []
    output.reserveCapacity(lines.count)
    var currentSegment: [Substring] = []

    // Reflows `currentSegment` while preserving any leading or trailing blank lines around it.
    func flushSegment(isFinalSegment: Bool) {
      guard !currentSegment.isEmpty else { return }
      defer { currentSegment.removeAll(keepingCapacity: true) }

      let leadingEmptyCount = currentSegment.prefix { $0.isEmpty }.count
      if leadingEmptyCount == currentSegment.count {
        for _ in 0..<leadingEmptyCount {
          output.append("")
        }
        return
      }
      let trailingEmptyCount = currentSegment.reversed().prefix { $0.isEmpty }.count
      let bodyLines = Array(currentSegment[leadingEmptyCount..<(currentSegment.count - trailingEmptyCount)])

      for _ in 0..<leadingEmptyCount {
        output.append("")
      }

      let effectiveFirstWidth = output.isEmpty ? firstLineWidth : continuationWidth
      let effectiveReservedSuffix = (isFinalSegment && trailingEmptyCount == 0) ? lastLineReservedSuffixLength : 0
      let reflowed = MarkdownReflower.reflow(
        lines: bodyLines,
        firstLineWidth: effectiveFirstWidth,
        continuationWidth: continuationWidth,
        lastLineReservedSuffixLength: effectiveReservedSuffix,
        preserveLineBreaks: preserveLineBreaks
      )
      output.append(contentsOf: reflowed)

      for _ in 0..<trailingEmptyCount {
        output.append("")
      }
    }

    for (idx, line) in lines.enumerated() {
      if isBannerLine(line) || isBuiltInIgnorePragma(line) || pragmaLines.contains(idx) {
        flushSegment(isFinalSegment: false)
        output.append(String(line))
      } else {
        currentSegment.append(line)
      }
      if idx == lines.count - 1 {
        flushSegment(isFinalSegment: true)
      }
    }

    return output
  }

  /// Returns `true` if `line` (after stripping the comment introducer) is a banner/divider line
  /// such as `===----------------------------------------------------------------------===//`.
  private static func isBannerLine(_ line: Substring) -> Bool {
    let trimmed = line.trimmingSpacesAndTabs()
    let utf8 = trimmed.utf8
    guard utf8.count >= 3 else { return false }
    var bannerCharCount = 0
    var hasEquals = false
    var hasHyphen = false
    for byte in utf8 {
      switch byte {
      case UInt8(ascii: "="):
        bannerCharCount += 1
        hasEquals = true
      case UInt8(ascii: "-"):
        bannerCharCount += 1
        hasHyphen = true
      case UInt8(ascii: "*"), UInt8(ascii: "/"), UInt8(ascii: "~"), UInt8(ascii: "_"):
        bannerCharCount += 1
      case UInt8(ascii: " "):
        break
      default:
        return false
      }
    }
    guard bannerCharCount >= 3 else { return false }

    // Unindented lines immediately after `//` (e.g. `//---`) or lines with `===---` / trailing `/`
    // are treated as banners rather than Markdown thematic breaks.
    if let firstByte = line.utf8.first,
      firstByte != UInt8(ascii: " ") && firstByte != UInt8(ascii: "\t")
    {
      return true
    }
    if utf8.last == UInt8(ascii: "/") || (hasEquals && hasHyphen) {
      return true
    }
    return false
  }
}

/// Reflows Markdown lines by walking the parsed `Markdown.Document` syntax tree while preserving
/// original formatting constructs.
private struct MarkdownReflower {
  let markdownLines: [Substring]
  let firstLineWidth: Int
  let continuationWidth: Int
  let lastLineReservedSuffixLength: Int
  let preserveLineBreaks: Bool
  var outputLines: [String] = []

  /// Parses `lines` as a Markdown document and returns the reflowed lines.
  static func reflow(
    lines: [Substring],
    firstLineWidth: Int,
    continuationWidth: Int,
    lastLineReservedSuffixLength: Int,
    preserveLineBreaks: Bool
  ) -> [String] {
    guard !lines.isEmpty else { return [] }
    let source = lines.joined(separator: "\n")
    let document = Document(parsing: source, options: [.disableSmartOpts])
    guard document.childCount > 0 else {
      return lines.map { String($0) }
    }

    var reflower = MarkdownReflower(
      markdownLines: lines,
      firstLineWidth: firstLineWidth,
      continuationWidth: continuationWidth,
      lastLineReservedSuffixLength: lastLineReservedSuffixLength,
      preserveLineBreaks: preserveLineBreaks
    )
    reflower.outputLines.reserveCapacity(lines.count)
    reflower.visitBlockChildren(
      Array(document.blockChildren),
      containerLineRange: 1...lines.count,
      containerContentStartCol: 1,
      firstLinePrefix: "",
      continuationPrefix: "",
      isLastBlockInDocument: true
    )
    return reflower.outputLines
  }

  /// Appends a single output line with `prefix` and `content`, trimming trailing whitespace.
  private mutating func emitLine(_ content: Substring, prefix: String) {
    let trimmedContent = content.trimmingTrailingWhitespace()
    if trimmedContent.isEmpty {
      outputLines.append(String(prefix.trimmingTrailingWhitespace()))
    } else {
      outputLines.append(prefix + trimmedContent)
    }
  }

  /// Returns the maximum number of characters available for content on the next emitted line after
  /// accounting for `prefixLength`.
  private func availableWidth(forPrefixLength prefixLength: Int) -> Int {
    let baseWidth = outputLines.isEmpty ? firstLineWidth : continuationWidth
    return baseWidth - prefixLength
  }

  /// Returns `true` if `line` consists solely of horizontal whitespace and/or `>` blockquote
  /// markers.
  fileprivate func isBlankOrBlockQuoteBlank(_ line: Substring) -> Bool {
    return line.utf8.allSatisfy {
      $0 == UInt8(ascii: " ") || $0 == UInt8(ascii: "\t") || $0 == UInt8(ascii: ">")
    }
  }

  /// Returns `true` if `codeBlock` is delimited by backtick or tilde fences (` ``` ` or `~~~`)
  /// rather than 4-space indentation.
  private func isFencedCodeBlock(_ codeBlock: CodeBlock) -> Bool {
    guard let range = codeBlock.range,
      range.lowerBound.line >= 1,
      range.lowerBound.line <= markdownLines.count
    else {
      return codeBlock.language != nil
    }
    let line = markdownLines[range.lowerBound.line - 1]
    let startIdx = utf8Index(in: line, column: range.lowerBound.column)
    let rest = line[startIdx...]
    return rest.hasPrefix("`") || rest.hasPrefix("~")
  }

  /// Returns the 1-based last source line of `block`, excluding any trailing blank lines that
  /// `cmark-gfm` absorbs into the `SourceRange` of open container and indented code blocks.
  private func effectiveEndLine(of block: BlockMarkup) -> Int {
    guard let range = block.range else { return 0 }
    let startLine = max(1, range.lowerBound.line)
    var endLine = min(markdownLines.count, range.upperBound.line)
    if let codeBlock = block as? CodeBlock, isFencedCodeBlock(codeBlock) {
      return endLine
    }
    while endLine > startLine && isBlankOrBlockQuoteBlank(markdownLines[endLine - 1]) {
      endLine -= 1
    }
    return endLine
  }

  /// Strips enclosing container prefixes (blockquote `>` markers and list continuation spaces)
  /// from a continuation line of a block or unvisited source gap.
  private func stripContinuationPrefix(
    from rawLine: Substring,
    maxPrefixColumns: Int,
    continuationPrefix: String
  ) -> Substring {
    guard !continuationPrefix.isEmpty else { return rawLine }
    let expectedQuotes = continuationPrefix.utf8.reduce(into: 0) { count, byte in
      if byte == UInt8(ascii: ">") { count += 1 }
    }
    let utf8 = rawLine.utf8
    var idx = utf8.startIndex
    var colsConsumed = 0
    var quotesConsumed = 0
    while idx < utf8.endIndex {
      let b = utf8[idx]
      if b == UInt8(ascii: ">") && quotesConsumed < expectedQuotes {
        quotesConsumed += 1
        colsConsumed += 1
        idx = utf8.index(after: idx)
      } else if (b == UInt8(ascii: " ") || b == UInt8(ascii: "\t"))
        && colsConsumed < maxPrefixColumns
      {
        colsConsumed += 1
        idx = utf8.index(after: idx)
      } else {
        break
      }
    }
    return rawLine[idx...]
  }

  /// Returns `true` if `prevBlock` and `block` were separated by at least one blank line in the
  /// original Markdown source.
  private func hasBlankSeparatorLine(before block: BlockMarkup, after prevBlock: BlockMarkup) -> Bool {
    let prevEnd = effectiveEndLine(of: prevBlock)
    if let currStart = block.range?.lowerBound.line,
      prevEnd >= 1,
      currStart > prevEnd + 1
    {
      return true
    }
    if let currStart = block.range?.lowerBound.line,
      currStart >= 2,
      currStart - 1 <= markdownLines.count
    {
      let lineBeforeCurr = markdownLines[currStart - 2]
      if isBlankOrBlockQuoteBlank(lineBeforeCurr) {
        return true
      }
    }
    return false
  }

  /// Visits a sequence of sibling block nodes, emitting blank separator lines between blocks as
  /// well as any unvisited source lines (such as `[label]: url` link reference definitions that
  /// `cmark-gfm` strips from the syntax tree during block finalization).
  private mutating func visitBlockChildren(
    _ children: [BlockMarkup],
    containerLineRange: ClosedRange<Int>? = nil,
    containerContentStartCol: Int = 1,
    firstLinePrefix: String,
    continuationPrefix: String,
    isLastBlockInDocument: Bool
  ) {
    var hasEmittedAnyInContainer = false
    var prevEmittedEndLine: Int? = nil
    let maxPrefixCols = max(containerContentStartCol - 1, continuationPrefix.utf8.count)

    func strippedContainerLine(_ lineNum: Int) -> Substring {
      let rawLine = markdownLines[lineNum - 1]
      if lineNum == containerLineRange?.lowerBound {
        let startIdx = utf8Index(in: rawLine, column: containerContentStartCol)
        return rawLine[startIdx...]
      }
      return stripContinuationPrefix(
        from: rawLine,
        maxPrefixColumns: maxPrefixCols,
        continuationPrefix: continuationPrefix
      )
    }

    func hasUnvisitedContent(from startLine: Int, to endLine: Int) -> Bool {
      let clampedStart = max(1, startLine)
      let clampedEnd = min(markdownLines.count, endLine)
      guard clampedStart <= clampedEnd else { return false }
      for lineNum in clampedStart...clampedEnd {
        if !isBlankOrBlockQuoteBlank(strippedContainerLine(lineNum)) {
          return true
        }
      }
      return false
    }

    // Emits any non-blank unvisited lines in `gapStart...gapEnd` verbatim.
    func emitUnvisitedGap(from gapStart: Int, to gapEnd: Int) {
      let clampedStart = max(1, gapStart)
      let clampedEnd = min(markdownLines.count, gapEnd)
      guard clampedStart <= clampedEnd else { return }

      var firstNonBlank: Int? = nil
      var lastNonBlank: Int? = nil
      for lineNum in clampedStart...clampedEnd {
        if !isBlankOrBlockQuoteBlank(strippedContainerLine(lineNum)) {
          if firstNonBlank == nil { firstNonBlank = lineNum }
          lastNonBlank = lineNum
        }
      }
      guard let contentStart = firstNonBlank, let contentEnd = lastNonBlank else { return }

      if let prevEnd = prevEmittedEndLine, contentStart > prevEnd + 1 {
        emitLine("", prefix: continuationPrefix)
      }
      for lineNum in contentStart...contentEnd {
        let slice = strippedContainerLine(lineNum)
        if isBlankOrBlockQuoteBlank(slice) {
          emitLine("", prefix: continuationPrefix)
        } else {
          let prefix = hasEmittedAnyInContainer ? continuationPrefix : firstLinePrefix
          hasEmittedAnyInContainer = true
          emitLine(slice, prefix: prefix)
        }
      }
      prevEmittedEndLine = contentEnd
    }

    if let containerRange = containerLineRange {
      let firstChildStart = children.first?.range?.lowerBound.line ?? (containerRange.upperBound + 1)
      if containerRange.lowerBound <= firstChildStart - 1 {
        emitUnvisitedGap(from: containerRange.lowerBound, to: firstChildStart - 1)
      }
    }

    let trailingGapHasContent: Bool = {
      guard let containerRange = containerLineRange, let lastChild = children.last else {
        return false
      }
      let lastEnd = effectiveEndLine(of: lastChild)
      guard lastEnd >= 1, lastEnd + 1 <= containerRange.upperBound else { return false }
      return hasUnvisitedContent(from: lastEnd + 1, to: containerRange.upperBound)
    }()

    for (index, child) in children.enumerated() {
      if index > 0,
        let prevEnd = prevEmittedEndLine,
        let currStart = child.range?.lowerBound.line,
        prevEnd + 1 <= currStart - 1
      {
        emitUnvisitedGap(from: prevEnd + 1, to: currStart - 1)
      }

      if hasEmittedAnyInContainer {
        let separatedByBlank: Bool
        if let prevEnd = prevEmittedEndLine,
          let currStart = child.range?.lowerBound.line,
          currStart > prevEnd + 1
        {
          separatedByBlank = true
        } else if index > 0 {
          separatedByBlank = hasBlankSeparatorLine(before: child, after: children[index - 1])
        } else {
          separatedByBlank = false
        }
        if separatedByBlank {
          emitLine("", prefix: continuationPrefix)
        }
      }

      let childFirstPrefix = hasEmittedAnyInContainer ? continuationPrefix : firstLinePrefix
      hasEmittedAnyInContainer = true
      let childIsLast =
        isLastBlockInDocument && (index == children.count - 1) && !trailingGapHasContent
      visitBlock(
        child,
        firstLinePrefix: childFirstPrefix,
        continuationPrefix: continuationPrefix,
        isLastBlockInDocument: childIsLast
      )
      prevEmittedEndLine = effectiveEndLine(of: child)
    }

    if let containerRange = containerLineRange, !children.isEmpty {
      let afterLastStart = (prevEmittedEndLine ?? (containerRange.lowerBound - 1)) + 1
      if afterLastStart <= containerRange.upperBound {
        emitUnvisitedGap(from: afterLastStart, to: containerRange.upperBound)
      }
    }
  }

  /// Dispatches a single `BlockMarkup` node to its specialized reflow handler, or emits it
  /// verbatim if it is a construct that should not be reflowed (such as headings, tables, or HTML).
  private mutating func visitBlock(
    _ block: BlockMarkup,
    firstLinePrefix: String,
    continuationPrefix: String,
    isLastBlockInDocument: Bool
  ) {
    switch block {
    case let paragraph as Paragraph:
      visitParagraph(
        paragraph,
        firstLinePrefix: firstLinePrefix,
        continuationPrefix: continuationPrefix,
        isLastBlockInDocument: isLastBlockInDocument
      )

    case let blockQuote as BlockQuote:
      let quoteRange: ClosedRange<Int>?
      let contentStartCol: Int
      if let range = blockQuote.range {
        let startLine = max(1, range.lowerBound.line)
        let endLine = max(startLine, effectiveEndLine(of: blockQuote))
        quoteRange = startLine <= endLine ? (startLine...endLine) : nil
        let rawLine = markdownLines[startLine - 1]
        let startIdx = utf8Index(in: rawLine, column: range.lowerBound.column)
        let utf8 = rawLine.utf8
        var idx = startIdx
        while idx < utf8.endIndex && (utf8[idx] == UInt8(ascii: " ") || utf8[idx] == UInt8(ascii: "\t")) {
          idx = utf8.index(after: idx)
        }
        if idx < utf8.endIndex && utf8[idx] == UInt8(ascii: ">") {
          idx = utf8.index(after: idx)
          if idx < utf8.endIndex && (utf8[idx] == UInt8(ascii: " ") || utf8[idx] == UInt8(ascii: "\t")) {
            idx = utf8.index(after: idx)
          }
        }
        contentStartCol = utf8.distance(from: utf8.startIndex, to: idx) + 1
      } else {
        quoteRange = nil
        contentStartCol = 3
      }
      visitBlockChildren(
        Array(blockQuote.blockChildren),
        containerLineRange: quoteRange,
        containerContentStartCol: contentStartCol,
        firstLinePrefix: firstLinePrefix + "> ",
        continuationPrefix: continuationPrefix + "> ",
        isLastBlockInDocument: isLastBlockInDocument
      )

    case let unorderedList as UnorderedList:
      visitListItems(
        Array(unorderedList.listItems),
        isOrdered: false,
        firstLinePrefix: firstLinePrefix,
        continuationPrefix: continuationPrefix,
        isLastBlockInDocument: isLastBlockInDocument
      )

    case let orderedList as OrderedList:
      visitListItems(
        Array(orderedList.listItems),
        isOrdered: true,
        firstLinePrefix: firstLinePrefix,
        continuationPrefix: continuationPrefix,
        isLastBlockInDocument: isLastBlockInDocument
      )

    case let codeBlock as CodeBlock:
      visitCodeBlock(
        codeBlock,
        firstLinePrefix: firstLinePrefix,
        continuationPrefix: continuationPrefix
      )

    default:
      emitVerbatimBlock(
        block,
        firstLinePrefix: firstLinePrefix,
        continuationPrefix: continuationPrefix
      )
    }
  }

  /// Visits the items of an ordered or unordered list, preserving loose-list blank lines and
  /// indenting continuation lines to align with each item's content.
  private mutating func visitListItems(
    _ items: [ListItem],
    isOrdered: Bool,
    firstLinePrefix: String,
    continuationPrefix: String,
    isLastBlockInDocument: Bool
  ) {
    for (index, item) in items.enumerated() {
      if index > 0 {
        let prevItem = items[index - 1]
        if hasBlankSeparatorLine(before: item, after: prevItem) {
          emitLine("", prefix: continuationPrefix)
        }
      }
      let itemFirstLinePrefix = index == 0 ? firstLinePrefix : continuationPrefix
      let (markerWithSpace, continuationSpaces, contentStartCol) = extractListMarker(
        for: item,
        isOrdered: isOrdered
      )
      let itemRange: ClosedRange<Int>? = {
        guard let range = item.range else { return nil }
        let startLine = max(1, range.lowerBound.line)
        let endLine = max(startLine, effectiveEndLine(of: item))
        return startLine <= endLine ? (startLine...endLine) : nil
      }()
      let itemIsLast = isLastBlockInDocument && (index == items.count - 1)
      if item.childCount == 0 {
        if let itemRange {
          let firstLine = markdownLines[itemRange.lowerBound - 1]
          let afterMarkerIdx = utf8Index(in: firstLine, column: contentStartCol)
          let hasContent =
            !isBlankOrBlockQuoteBlank(firstLine[afterMarkerIdx...])
            || itemRange.upperBound > itemRange.lowerBound
          if hasContent {
            visitBlockChildren(
              [],
              containerLineRange: itemRange,
              containerContentStartCol: contentStartCol,
              firstLinePrefix: itemFirstLinePrefix + markerWithSpace,
              continuationPrefix: continuationPrefix + continuationSpaces,
              isLastBlockInDocument: itemIsLast
            )
            continue
          }
        }
        emitLine(markerWithSpace[...], prefix: itemFirstLinePrefix)
      } else {
        visitBlockChildren(
          Array(item.blockChildren),
          containerLineRange: itemRange,
          containerContentStartCol: contentStartCol,
          firstLinePrefix: itemFirstLinePrefix + markerWithSpace,
          continuationPrefix: continuationPrefix + continuationSpaces,
          isLastBlockInDocument: itemIsLast
        )
      }
    }
  }

  /// Extracts the list marker (including any task-list checkbox and post-marker spacing) from the
  /// source line of `item`, along with the matching continuation indentation spaces and 1-based
  /// content start column.
  private func extractListMarker(
    for item: ListItem,
    isOrdered: Bool
  ) -> (markerWithSpace: String, continuationSpaces: String, contentStartCol: Int) {
    guard let range = item.range,
      range.lowerBound.line >= 1,
      range.lowerBound.line <= markdownLines.count
    else {
      return (isOrdered ? "1. " : "- ", isOrdered ? "   " : "  ", isOrdered ? 4 : 3)
    }
    let line = markdownLines[range.lowerBound.line - 1]
    let startIdx = utf8Index(in: line, column: range.lowerBound.column)
    let slice = line[startIdx...]

    // Extract the raw bullet or ordered list marker token (e.g. `-`, `*`, `+`, `1.`, `1)`).
    let markerToken = slice.prefix { !$0.isWhitespace }
    guard !markerToken.isEmpty else {
      return (isOrdered ? "1. " : "- ", isOrdered ? "   " : "  ", range.lowerBound.column)
    }

    // Preserve the original spacing after the marker, unless the marker is followed by an indented
    // code block (> 4 spaces) or end-of-line.
    let afterMarker = slice[markerToken.endIndex...]
    let rawSpacesAfterMarker = afterMarker.prefix { $0 == " " || $0 == "\t" }
    let afterMarkerSpaces = afterMarker[rawSpacesAfterMarker.endIndex...]
    let rawSpacesCount = rawSpacesAfterMarker.utf8.count
    let spacesAfterMarkerCount: Int
    if rawSpacesAfterMarker.isEmpty || afterMarkerSpaces.isEmpty
      || (rawSpacesCount > 4 && item.child(at: 0) is CodeBlock)
    {
      spacesAfterMarkerCount = 1
    } else {
      spacesAfterMarkerCount = rawSpacesCount
    }

    let baseMarkerWithSpace =
      String(markerToken) + String(repeating: " ", count: spacesAfterMarkerCount)

    // For task list items, include the `[ ]` / `[x]` checkbox and any spacing after it so
    // continuation lines align with the item text after the checkbox.
    if let checkbox = item.checkbox {
      let checkboxToken: Substring
      let spacesAfterCheckboxCount: Int
      let contentStartIdx: String.Index
      if afterMarkerSpaces.hasPrefix("[x]") || afterMarkerSpaces.hasPrefix("[X]")
        || afterMarkerSpaces.hasPrefix("[ ]")
      {
        checkboxToken = afterMarkerSpaces.prefix(3)
        let afterCheckbox = afterMarkerSpaces[checkboxToken.endIndex...]
        let rawSpacesAfterCheckbox = afterCheckbox.prefix { $0 == " " || $0 == "\t" }
        let afterCheckboxSpaces = afterCheckbox[rawSpacesAfterCheckbox.endIndex...]
        contentStartIdx = afterCheckboxSpaces.startIndex
        if rawSpacesAfterCheckbox.isEmpty || afterCheckboxSpaces.isEmpty {
          spacesAfterCheckboxCount = 1
        } else {
          spacesAfterCheckboxCount = rawSpacesAfterCheckbox.utf8.count
        }
      } else {
        checkboxToken = checkbox == .checked ? "[x]" : "[ ]"
        spacesAfterCheckboxCount = 1
        contentStartIdx = afterMarkerSpaces.startIndex
      }
      let fullMarker =
        baseMarkerWithSpace + checkboxToken + String(repeating: " ", count: spacesAfterCheckboxCount)
      let continuationSpaces = String(repeating: " ", count: fullMarker.utf8.count)
      let contentStartCol = line.utf8.distance(from: line.utf8.startIndex, to: contentStartIdx) + 1
      return (fullMarker, continuationSpaces, contentStartCol)
    }

    let continuationSpaces = String(repeating: " ", count: baseMarkerWithSpace.utf8.count)
    let contentStartCol =
      line.utf8.distance(from: line.utf8.startIndex, to: afterMarkerSpaces.startIndex) + 1
    return (baseMarkerWithSpace, continuationSpaces, contentStartCol)
  }

  /// Emits a fenced or indented code block without wrapping its contents.
  private mutating func visitCodeBlock(
    _ codeBlock: CodeBlock,
    firstLinePrefix: String,
    continuationPrefix: String
  ) {
    let isFenced = isFencedCodeBlock(codeBlock)

    // Indented code blocks nested inside containers (lists/blockquotes) are emitted using their
    // parsed lines prefixed by 4 spaces; top-level and fenced code blocks are emitted verbatim.
    if !isFenced && !continuationPrefix.isEmpty {
      var code = codeBlock.code[...]
      if code.hasSuffix("\n") {
        code = code.dropLast()
      }
      let lines = code.split(separator: "\n", omittingEmptySubsequences: false)
      for (idx, line) in lines.enumerated() {
        let prefix = idx == 0 ? firstLinePrefix : continuationPrefix
        if line.isEmpty {
          emitLine("", prefix: prefix)
        } else {
          emitLine(line, prefix: prefix + "    ")
        }
      }
    } else {
      emitVerbatimBlock(
        codeBlock,
        firstLinePrefix: firstLinePrefix,
        continuationPrefix: continuationPrefix
      )
    }
  }

  /// Emits the original source lines covered by `block` without reflowing them.
  private mutating func emitVerbatimBlock(
    _ block: BlockMarkup,
    firstLinePrefix: String,
    continuationPrefix: String
  ) {
    guard let range = block.range else { return }
    let startLine = max(1, range.lowerBound.line)
    let endLine = effectiveEndLine(of: block)
    guard startLine <= endLine else { return }

    let startCol = range.lowerBound.column
    let maxPrefixCols = max(startCol - 1, continuationPrefix.utf8.count)
    for lineNum in startLine...endLine {
      let rawLine = markdownLines[lineNum - 1]
      if lineNum == startLine {
        if firstLinePrefix.isEmpty && continuationPrefix.isEmpty {
          emitLine(rawLine, prefix: firstLinePrefix)
        } else {
          let startIdx = utf8Index(in: rawLine, column: startCol)
          emitLine(rawLine[startIdx...], prefix: firstLinePrefix)
        }
      } else {
        if continuationPrefix.isEmpty {
          emitLine(rawLine, prefix: continuationPrefix)
        } else {
          let stripped = stripContinuationPrefix(
            from: rawLine,
            maxPrefixColumns: maxPrefixCols,
            continuationPrefix: continuationPrefix
          )
          emitLine(stripped, prefix: continuationPrefix)
        }
      }
    }
  }

  /// Returns the number of line breaks spanned by the inline children of `container`.
  private func countInlineNewlines(in container: InlineContainer) -> Int {
    var count = 0
    for child in container.inlineChildren {
      switch child {
      case is SoftBreak, is LineBreak:
        count += 1
      case let inlineCode as InlineCode:
        if let range = inlineCode.range, range.upperBound.line > range.lowerBound.line {
          count += range.upperBound.line - range.lowerBound.line
        }
      case let inlineHTML as InlineHTML:
        count += inlineHTML.rawHTML.utf8.reduce(into: 0) { acc, byte in
          if byte == UInt8(ascii: "\n") { acc += 1 }
        }
      case let nested as InlineContainer:
        count += countInlineNewlines(in: nested)
      default:
        break
      }
    }
    return count
  }

  /// Returns the stripped paragraph content slice on 1-based `lineNum` for a paragraph starting at
  /// `(paragraphStartLine, paragraphStartCol)`.
  fileprivate func paragraphLineContent(
    atLine lineNum: Int,
    paragraphStartLine: Int,
    paragraphStartCol: Int
  ) -> Substring {
    guard lineNum >= 1, lineNum <= markdownLines.count else { return "" }
    let rawLine = markdownLines[lineNum - 1]
    if lineNum == paragraphStartLine {
      let startIdx = utf8Index(in: rawLine, column: paragraphStartCol)
      return rawLine[startIdx...]
    }
    return rawLine.drop { $0 == " " || $0 == "\t" || $0 == ">" }
  }

  /// Collects inline words from `paragraph` and wraps them to fit within the available line width.
  private mutating func visitParagraph(
    _ paragraph: Paragraph,
    firstLinePrefix: String,
    continuationPrefix: String,
    isLastBlockInDocument: Bool
  ) {
    let rawStartLine = max(1, paragraph.range?.lowerBound.line ?? 1)
    let endLine = min(markdownLines.count, paragraph.range?.upperBound.line ?? markdownLines.count)
    let paragraphStartCol = paragraph.range?.lowerBound.column ?? 1

    // If `cmark-gfm` stripped leading `[label]: url` or `^[label]: attrs` reference definitions
    // from the start of this paragraph before parsing its remaining prose, emit those leading
    // definition lines verbatim first.
    var strippedLeadingLines = 0
    if rawStartLine < endLine {
      let firstContent = paragraphLineContent(
        atLine: rawStartLine,
        paragraphStartLine: rawStartLine,
        paragraphStartCol: paragraphStartCol
      )
      if (firstContent.hasPrefix("[") || firstContent.hasPrefix("^["))
        && firstContent.contains("]:")
      {
        let inlineSpanLines = 1 + countInlineNewlines(in: paragraph)
        let totalLines = endLine - rawStartLine + 1
        if totalLines > inlineSpanLines {
          strippedLeadingLines = totalLines - inlineSpanLines
        }
      }
    }

    var isFirstLineOfParagraph = true
    if strippedLeadingLines > 0 {
      for lineNum in rawStartLine..<(rawStartLine + strippedLeadingLines) {
        let prefix = isFirstLineOfParagraph ? firstLinePrefix : continuationPrefix
        isFirstLineOfParagraph = false
        let slice = paragraphLineContent(
          atLine: lineNum,
          paragraphStartLine: rawStartLine,
          paragraphStartCol: paragraphStartCol
        )
        emitLine(slice, prefix: prefix)
      }
    }

    // Collect breakable words grouped into logical lines (in `.always` mode a paragraph is a single
    // logical line unless it contains hard `\` line breaks; in `.onlyLinesOverLength` mode each
    // source line is kept as a separate logical line).
    var collector = InlineWordCollector(
      reflower: self,
      paragraphStartLine: rawStartLine,
      paragraphStartCol: paragraphStartCol,
      strippedLeadingLines: strippedLeadingLines
    )
    for child in paragraph.inlineChildren {
      collector.collectInline(child)
    }
    let logicalLines = collector.finish()
    guard !logicalLines.isEmpty else { return }

    var currentLine = ""
    currentLine.reserveCapacity(max(64, max(firstLineWidth, continuationWidth)))

    for (lineIdx, entry) in logicalLines.enumerated() {
      let words = entry.words
      let isFinalLogicalLine = isLastBlockInDocument && (lineIdx == logicalLines.count - 1)

      // In `.onlyLinesOverLength` mode on top-level paragraphs, preserve each source line's
      // original leading indentation.
      let extraIndent: Substring
      if preserveLineBreaks && firstLinePrefix.isEmpty && continuationPrefix.isEmpty,
        entry.sourceLine >= 1,
        entry.sourceLine <= markdownLines.count
      {
        let rawSourceLine = markdownLines[entry.sourceLine - 1]
        extraIndent = rawSourceLine.prefix { $0 == " " || $0 == "\t" }
      } else {
        extraIndent = ""
      }

      let firstActivePrefix =
        extraIndent.isEmpty ? firstLinePrefix : firstLinePrefix + extraIndent
      let contActivePrefix =
        extraIndent.isEmpty ? continuationPrefix : continuationPrefix + extraIndent
      let firstPrefixCount = firstActivePrefix.count
      let contPrefixCount = contActivePrefix.count

      // Greedily pack words onto `currentLine` up to `maxWidth`, reserving space on the very last
      // word of the document if an inline closing `*/` delimiter needs to fit on that line.
      currentLine.removeAll(keepingCapacity: true)
      var currentLineLength = 0
      for (wordIdx, word) in words.enumerated() {
        let isFinalWord = isFinalLogicalLine && (wordIdx == words.count - 1)
        let reservedSuffix = isFinalWord ? lastLineReservedSuffixLength : 0
        let activePrefixCount = isFirstLineOfParagraph ? firstPrefixCount : contPrefixCount
        let maxWidth = availableWidth(forPrefixLength: activePrefixCount)
        let wordLength = word.count

        if currentLine.isEmpty {
          currentLine.append(contentsOf: word)
          currentLineLength = wordLength
        } else if currentLineLength + 1 + wordLength + reservedSuffix <= maxWidth {
          currentLine.append(" ")
          currentLine.append(contentsOf: word)
          currentLineLength += 1 + wordLength
        } else {
          let activePrefix = isFirstLineOfParagraph ? firstActivePrefix : contActivePrefix
          emitLine(currentLine[...], prefix: activePrefix)
          isFirstLineOfParagraph = false
          currentLine.removeAll(keepingCapacity: true)
          currentLine.append(contentsOf: word)
          currentLineLength = wordLength
        }
      }

      if !currentLine.isEmpty {
        let activePrefix = isFirstLineOfParagraph ? firstActivePrefix : contActivePrefix
        emitLine(currentLine[...], prefix: activePrefix)
        isFirstLineOfParagraph = false
      }
    }
  }

  /// Converts a 1-based UTF-8 column index from `swift-markdown` into a scalar-aligned
  /// `String.Index` in `line`.
  fileprivate func utf8Index(in line: Substring, column: Int) -> String.Index {
    let offset = max(0, column - 1)
    let utf8 = line.utf8
    guard offset < utf8.count else { return line.endIndex }
    var idx = utf8.index(utf8.startIndex, offsetBy: offset)
    while idx < utf8.endIndex && (utf8[idx] & 0xC0) == 0x80 {
      idx = utf8.index(after: idx)
    }
    return idx
  }
}

/// Walks the inline children of a Markdown `Paragraph` and flattens them into logical lines of
/// whitespace-delimited words while keeping unbreakable inline spans (such as inline code,
/// autolinks, and link destinations) attached to their surrounding tokens.
private struct InlineWordCollector {
  let reflower: MarkdownReflower
  let paragraphStartLine: Int
  let paragraphStartCol: Int
  let strippedLeadingLines: Int
  var currentSourceLine: Int
  var currentLineStartSourceLine: Int
  var logicalLines: [(words: [Substring], sourceLine: Int)] = []
  var currentLineWords: [Substring] = []
  /// Holds the current word when it consists of a single slice from source or `Text.string`.
  var pendingWordSlice: Substring = ""
  /// Holds the current word only when multiple adjacent unbreakable spans are concatenated.
  var compoundWordBuffer: String = ""
  /// Tracks whether a hard `LineBreak` (`\`) has been encountered in the current paragraph.
  /// `cmark-gfm` does not increment its line counter after a backslash line break, which invalidates
  /// `SourceRange` on subsequent inline nodes in the same paragraph.
  var hasSeenLineBreak: Bool = false

  /// Creates a word collector for a paragraph starting at `(paragraphStartLine, paragraphStartCol)`
  /// in `reflower.markdownLines`, after `strippedLeadingLines` stripped reference definitions.
  init(
    reflower: MarkdownReflower,
    paragraphStartLine: Int,
    paragraphStartCol: Int,
    strippedLeadingLines: Int
  ) {
    self.reflower = reflower
    self.paragraphStartLine = paragraphStartLine
    self.paragraphStartCol = paragraphStartCol
    self.strippedLeadingLines = strippedLeadingLines
    let initialLine = paragraphStartLine + strippedLeadingLines
    self.currentSourceLine = initialLine
    self.currentLineStartSourceLine = initialLine
  }

  /// Returns the stripped paragraph content for 1-based `lineNum`.
  private func paragraphLineContent(atLine lineNum: Int) -> Substring {
    return reflower.paragraphLineContent(
      atLine: lineNum,
      paragraphStartLine: paragraphStartLine,
      paragraphStartCol: paragraphStartCol
    )
  }

  /// Returns a scalar-aligned `String.Index` at `byteOffset` in `slice`, or `nil` if `byteOffset`
  /// is out of bounds or lands on a UTF-8 continuation byte.
  private func scalarAlignedUTF8Index(in slice: Substring, byteOffset: Int) -> String.Index? {
    let utf8 = slice.utf8
    guard byteOffset >= 0, byteOffset <= utf8.count else { return nil }
    let idx = utf8.index(utf8.startIndex, offsetBy: byteOffset)
    if idx < utf8.endIndex && (utf8[idx] & 0xC0) == 0x80 {
      return nil
    }
    return idx
  }

  /// Extracts a single-line source slice within the current paragraph corresponding to `range`,
  /// accounting for continuation line indentation.
  private func singleLineParagraphSourceText(in range: Markdown.SourceRange) -> Substring? {
    guard !hasSeenLineBreak, range.lowerBound.line == range.upperBound.line else { return nil }
    let actualLine = range.lowerBound.line + strippedLeadingLines
    let lineContent = paragraphLineContent(atLine: actualLine)
    let startOffset = range.lowerBound.column - paragraphStartCol
    let endOffset = range.upperBound.column - paragraphStartCol
    guard startOffset <= endOffset,
      let startIdx = scalarAlignedUTF8Index(in: lineContent, byteOffset: startOffset),
      let endIdx = scalarAlignedUTF8Index(in: lineContent, byteOffset: endOffset)
    else {
      return nil
    }
    return lineContent[startIdx..<endIdx]
  }

  /// Returns the remainder of the paragraph source line starting at `location`.
  private func paragraphSourceSlice(from location: Markdown.SourceLocation) -> Substring? {
    guard !hasSeenLineBreak else { return nil }
    let actualLine = location.line + strippedLeadingLines
    let lineContent = paragraphLineContent(atLine: actualLine)
    let startOffset = location.column - paragraphStartCol
    guard let startIdx = scalarAlignedUTF8Index(in: lineContent, byteOffset: startOffset) else {
      return nil
    }
    return lineContent[startIdx...]
  }

  /// Moves any accumulated characters in `pendingWordSlice` / `compoundWordBuffer` into
  /// `currentLineWords`.
  mutating func flushWord() {
    if !compoundWordBuffer.isEmpty {
      currentLineWords.append(Substring(compoundWordBuffer))
      compoundWordBuffer = ""
      pendingWordSlice = ""
    } else if !pendingWordSlice.isEmpty {
      currentLineWords.append(pendingWordSlice)
      pendingWordSlice = ""
    }
  }

  /// Appends plain text that may be broken at whitespace boundaries, slicing contiguous words as
  /// `Substring` views to avoid per-character string allocations.
  mutating func appendBreakableText(_ sub: Substring) {
    let utf8 = sub.utf8
    var idx = utf8.startIndex
    let end = utf8.endIndex
    while idx < end {
      let byte = utf8[idx]
      if byte == UInt8(ascii: " ") || byte == UInt8(ascii: "\t")
        || byte == UInt8(ascii: "\n") || byte == UInt8(ascii: "\r")
      {
        flushWord()
        idx = utf8.index(after: idx)
        while idx < end {
          let b = utf8[idx]
          guard
            b == UInt8(ascii: " ") || b == UInt8(ascii: "\t")
              || b == UInt8(ascii: "\n") || b == UInt8(ascii: "\r")
          else { break }
          idx = utf8.index(after: idx)
        }
      } else {
        let wordStart = idx
        idx = utf8.index(after: idx)
        while idx < end {
          let b = utf8[idx]
          if b == UInt8(ascii: " ") || b == UInt8(ascii: "\t")
            || b == UInt8(ascii: "\n") || b == UInt8(ascii: "\r")
          {
            break
          }
          idx = utf8.index(after: idx)
        }
        let wordSlice = sub[wordStart..<idx]
        if idx < end && pendingWordSlice.isEmpty && compoundWordBuffer.isEmpty {
          currentLineWords.append(wordSlice)
        } else {
          appendUnbreakableText(wordSlice)
        }
      }
    }
  }

  /// Appends text to the current word that must not be split at internal spaces (such as inline
  /// code).
  mutating func appendUnbreakableText(_ text: Substring) {
    guard !text.isEmpty else { return }
    if !compoundWordBuffer.isEmpty {
      compoundWordBuffer.append(contentsOf: text)
    } else if !pendingWordSlice.isEmpty {
      compoundWordBuffer = String(pendingWordSlice)
      compoundWordBuffer.append(contentsOf: text)
      pendingWordSlice = ""
    } else {
      pendingWordSlice = text
    }
  }

  /// Handles a soft line break (`\n`) between source lines within a paragraph.
  mutating func softBreak() {
    flushWord()
    currentSourceLine += 1
    if reflower.preserveLineBreaks {
      logicalLines.append((words: currentLineWords, sourceLine: currentLineStartSourceLine))
      currentLineWords = []
      currentLineStartSourceLine = currentSourceLine
    }
  }

  /// Handles a hard line break (a trailing `\` at the end of a line), which always forces a line
  /// break in the output.
  mutating func hardLineBreak() {
    appendUnbreakableText("\\")
    flushWord()
    logicalLines.append((words: currentLineWords, sourceLine: currentLineStartSourceLine))
    currentLineWords = []
    currentSourceLine += 1
    currentLineStartSourceLine = currentSourceLine
    hasSeenLineBreak = true
  }

  /// Flushes any remaining buffered word/line and returns the collected logical lines.
  mutating func finish() -> [(words: [Substring], sourceLine: Int)] {
    flushWord()
    if !currentLineWords.isEmpty {
      logicalLines.append((words: currentLineWords, sourceLine: currentLineStartSourceLine))
      currentLineWords = []
    }
    return logicalLines
  }

  /// Formats a fallback closing suffix `](destination "title")` for a `Link` or `Image`.
  private func formatLinkFallbackClosing(destination: String?, title: String?) -> Substring {
    let dest = destination ?? ""
    if let title, !title.isEmpty {
      let escapedTitle = title.replacingOccurrences(of: "\"", with: "\\\"")
      return Substring("](\(dest) \"\(escapedTitle)\")")
    }
    return Substring("](\(dest))")
  }

  /// Recursively collects words and inline formatting delimiters from `markup`.
  mutating func collectInline(_ markup: InlineMarkup) {
    switch markup {
    case let text as Text:
      // Prefer slicing the raw source line when it contains backslash escapes (`\`) or HTML
      // entities (`&`) so `cmark`'s unescaping does not alter the original text.
      if let range = text.range,
        let raw = singleLineParagraphSourceText(in: range),
        raw.utf8.contains(UInt8(ascii: "\\")) || raw.utf8.contains(UInt8(ascii: "&")),
        raw.utf8.count >= text.string.utf8.count
      {
        appendBreakableText(raw)
        return
      }
      appendBreakableText(text.string[...])

    case is SoftBreak:
      softBreak()

    case is LineBreak:
      hardLineBreak()

    case let inlineCode as InlineCode:
      // Preserve the original backtick delimiter length from source when available, and treat the
      // entire code span as a single unbreakable token.
      var effectiveTicks: Substring = inlineCode.code.utf8.contains(UInt8(ascii: "`")) ? "``" : "`"
      if let range = inlineCode.range {
        if range.lowerBound.line == range.upperBound.line {
          if let raw = singleLineParagraphSourceText(in: range),
            raw.hasPrefix("`") && raw.hasSuffix("`") && raw.contains(inlineCode.code)
          {
            appendUnbreakableText(raw)
            return
          }
        } else {
          if let startSlice = paragraphSourceSlice(from: range.lowerBound) {
            let ticks = startSlice.prefix { $0 == "`" }
            if !ticks.isEmpty {
              effectiveTicks = ticks
            }
          }
          currentSourceLine += range.upperBound.line - range.lowerBound.line
        }
      }
      let needsSpace =
        inlineCode.code.hasPrefix("`") || inlineCode.code.hasSuffix("`")
        || (effectiveTicks.count > 1 && inlineCode.code.utf8.contains(UInt8(ascii: "`")))
      if needsSpace {
        appendUnbreakableText(Substring("\(effectiveTicks) \(inlineCode.code) \(effectiveTicks)"))
      } else {
        appendUnbreakableText(Substring("\(effectiveTicks)\(inlineCode.code)\(effectiveTicks)"))
      }

    case let symbolLink as SymbolLink:
      if let range = symbolLink.range,
        let raw = singleLineParagraphSourceText(in: range),
        raw.hasPrefix("``") && raw.hasSuffix("``")
      {
        appendUnbreakableText(raw)
        return
      }
      appendUnbreakableText(Substring("``\(symbolLink.destination ?? "")``"))

    case let emphasis as Emphasis:
      collectDelimitedInline(emphasis, defaultDelimiter: "*", alternateChar: "_")

    case let strong as Strong:
      collectDelimitedInline(strong, defaultDelimiter: "**", alternateChar: "_")

    case let strikethrough as Strikethrough:
      collectDelimitedInline(strikethrough, defaultDelimiter: "~~", alternateChar: "~")

    case let link as Link:
      // Autolinks (`<https://...>`) are kept as a single unbreakable token; standard and reference
      // links allow wrapping inside the link text while keeping `](...)` / `][...]` attached.
      if let range = link.range,
        let raw = singleLineParagraphSourceText(in: range),
        raw.hasPrefix("<") && raw.hasSuffix(">")
      {
        appendUnbreakableText(raw)
        return
      }
      if link.isAutolink, let dest = link.destination {
        appendUnbreakableText(Substring("<\(dest)>"))
        return
      }
      collectBracketedInline(
        link,
        opening: "[",
        fallbackClosing: formatLinkFallbackClosing(destination: link.destination, title: link.title),
        allowReferenceStyle: true
      )

    case let image as Image:
      collectBracketedInline(
        image,
        opening: "![",
        fallbackClosing: formatLinkFallbackClosing(destination: image.source, title: image.title),
        allowReferenceStyle: true
      )

    case let inlineHTML as InlineHTML:
      appendUnbreakableText(inlineHTML.rawHTML[...])

    case let customInline as CustomInline:
      appendBreakableText(customInline.text[...])

    case let inlineAttributes as InlineAttributes:
      collectBracketedInline(
        inlineAttributes,
        opening: "^[",
        fallbackClosing: Substring("](\(inlineAttributes.attributes))"),
        allowReferenceStyle: false
      )

    default:
      if let range = markup.range, let raw = singleLineParagraphSourceText(in: range) {
        appendBreakableText(raw)
      }
    }
  }

  /// Collects an inline container wrapped in symmetric delimiters (such as `*`/`_` for emphasis,
  /// `**`/`__` for strong, or `~~` for strikethrough), preserving the delimiter spelling from
  /// source when available.
  private mutating func collectDelimitedInline(
    _ markup: InlineContainer,
    defaultDelimiter: Substring,
    alternateChar: Character
  ) {
    let delimiter: Substring = {
      guard let range = markup.range,
        let startSlice = paragraphSourceSlice(from: range.lowerBound)
      else {
        return defaultDelimiter
      }
      let prefix = startSlice.prefix { $0 == alternateChar }
      guard !prefix.isEmpty else { return defaultDelimiter }
      if alternateChar == "_" {
        return defaultDelimiter.count == 2 ? "__" : "_"
      }
      return prefix.count <= 2 ? prefix : defaultDelimiter
    }()
    appendUnbreakableText(delimiter)
    for child in markup.inlineChildren {
      collectInline(child)
    }
    appendUnbreakableText(delimiter)
  }

  /// Returns `true` if `suffix` is a valid closing suffix for a bracketed inline (`](...)`,
  /// `][...]`, or shortcut `]`).
  private func isValidBracketedClosingSuffix(_ suffix: Substring, allowReferenceStyle: Bool) -> Bool {
    if suffix.hasPrefix("](") && suffix.hasSuffix(")") {
      return true
    }
    if allowReferenceStyle {
      if (suffix.hasPrefix("][") && suffix.hasSuffix("]")) || suffix == "]" {
        return true
      }
    }
    return false
  }

  /// Collects a bracketed inline container (such as a link `[...](...)`, image `![...](...)`, or
  /// inline attributes `^[...](...)`), allowing word breaks between children while keeping the
  /// opening bracket and closing destination/reference suffix attached to the first and last words.
  private mutating func collectBracketedInline(
    _ markup: InlineContainer,
    opening: Substring,
    fallbackClosing: Substring,
    allowReferenceStyle: Bool
  ) {
    let childCount = markup.childCount
    if childCount == 0 {
      if let range = markup.range,
        let raw = singleLineParagraphSourceText(in: range),
        raw.hasPrefix(opening)
          && (raw.hasSuffix(")") || (allowReferenceStyle && raw.hasSuffix("]")))
      {
        appendUnbreakableText(raw)
        return
      }
      appendUnbreakableText(opening)
      appendUnbreakableText(fallbackClosing)
      return
    }

    appendUnbreakableText(opening)
    for child in markup.inlineChildren {
      collectInline(child)
    }

    guard !hasSeenLineBreak, let range = markup.range else {
      appendUnbreakableText(fallbackClosing)
      return
    }

    // Determine the starting byte offset of the closing `](...)` / `][...]` / `]` suffix on
    // `currentSourceLine` after the last inline child.
    let startOffset: Int
    if let lastChildRange = markup.child(at: childCount - 1)?.range {
      startOffset = lastChildRange.upperBound.column - paragraphStartCol
    } else {
      startOffset = 0
    }

    let endOffset = range.upperBound.column - paragraphStartCol
    let firstLineContent = paragraphLineContent(atLine: currentSourceLine)
    let firstLineUTF8Count = firstLineContent.utf8.count

    if endOffset <= firstLineUTF8Count {
      if startOffset <= endOffset,
        let startIdx = scalarAlignedUTF8Index(in: firstLineContent, byteOffset: startOffset),
        let endIdx = scalarAlignedUTF8Index(in: firstLineContent, byteOffset: endOffset)
      {
        let closingSuffix = firstLineContent[startIdx..<endIdx].trimmingSpacesAndTabs()
        if isValidBracketedClosingSuffix(closingSuffix, allowReferenceStyle: allowReferenceStyle) {
          appendUnbreakableText(closingSuffix)
          return
        }
      }
    }

    appendUnbreakableText(fallbackClosing)
  }
}
