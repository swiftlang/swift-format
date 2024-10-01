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

private let utf8Newline = UTF8.CodeUnit(ascii: "\n")
private let utf8Tab = UTF8.CodeUnit(ascii: "\t")

/// Emits linter errors for whitespace style violations by comparing the raw text of the input Swift
/// code with formatted text.
@_spi(Testing)
public class WhitespaceLinter {

  /// The text of the input source code to be linted.
  private let userText: [UTF8.CodeUnit]

  /// The formatted version of `userText`.
  private let formattedText: [UTF8.CodeUnit]

  /// The Context object containing the DiagnosticEngine.
  private let context: Context

  /// Is the current line too long?
  private var isLineTooLong: Bool

  /// Creates a new WhitespaceLinter with the given context.
  ///
  /// - Parameters:
  ///   - user: The text of the Swift source code to be linted.
  ///   - formatted: The formatted text to compare to `user`.
  ///   - context: The context object containing the DiagnosticEngine instance we wish to use.
  public init(user: String, formatted: String, context: Context) {
    self.userText = Array(user.utf8)
    self.formattedText = Array(formatted.utf8)
    self.context = context
    self.isLineTooLong = false
  }

  /// Perform whitespace linting.
  public func lint() {
    var userIndex = 0
    var formattedIndex = 0
    var userWhitespace: ArraySlice<UTF8.CodeUnit>

    repeat {
      userWhitespace = contiguousWhitespace(startingAt: userIndex, in: userText)
      let formattedWhitespace = contiguousWhitespace(startingAt: formattedIndex, in: formattedText)

      // `userText` and `formattedText` should only differ in their whitespace characters.
      assert(
        safeCodeUnit(at: userWhitespace.endIndex, in: userText)
          == safeCodeUnit(at: formattedWhitespace.endIndex, in: formattedText),
        "Non-whitespace characters do not match"
      )

      compareWhitespace(userWhitespace: userWhitespace, formattedWhitespace: formattedWhitespace)

      userIndex = userWhitespace.endIndex + 1
      formattedIndex = formattedWhitespace.endIndex + 1
    } while userWhitespace.endIndex != userText.endIndex
  }

  /// Compare the whitespace buffers between the user text and formatted text, and emit linter
  /// errors accordingly.
  ///
  /// Note: properly formatted whitespace will always be some number of newline characters
  /// followed by some number of spaces in the absence of trailing whitespace (which the
  /// pretty-printer ensures). e.g. "\n ", "\n\n  ", "\n", " ". The user's whitespace could have
  /// spaces and newlines in any order. e.g. " \n ", "  \n", etc.
  ///
  /// - Parameters:
  ///   - userWhitespace: A slice of user text representing the current span of contiguous
  ///     whitespace.
  ///   - formattedWhitespace: A slice of formatted text representing the current span of contiguous
  ///     whitespace that will be compared to the user whitespace.
  private func compareWhitespace(
    userWhitespace: ArraySlice<UTF8.CodeUnit>,
    formattedWhitespace: ArraySlice<UTF8.CodeUnit>
  ) {
    // We use a custom-crafted lazy-splitting iterator here instead of the standard
    // `Collection.split` function because Time Profiler indicated that a very large proportion of
    // the runtime of this function was spent allocating arrays inside `split` and then subsequently
    // deallocating those arrays. For the sizes of whitespace runs we're likely to work with, it is
    // much faster to pre-scan to count the number of runs and then do a single pass again over the
    // whitespace without allocating any intermediate storage.
    let userRuns = userWhitespace.lazilySplit(separator: utf8Newline)
    let formattedRuns = formattedWhitespace.lazilySplit(separator: utf8Newline)

    checkForLineLengthErrors(
      userIndex: userWhitespace.startIndex,
      formattedIndex: formattedWhitespace.startIndex,
      userRuns: userRuns,
      formattedRuns: formattedRuns
    )

    // No need to perform any further checks if the whitespace is identical.
    guard userWhitespace != formattedWhitespace else { return }

    var userIndex = userWhitespace.startIndex
    var userRunsIterator = RememberingIterator(userRuns.makeIterator())
    var formattedRunsIterator = RememberingIterator(formattedRuns.makeIterator())

    if userRuns.count == 1 && formattedRuns.count == 1 {
      let userRun = userRunsIterator.next()!
      let formattedRun = formattedRunsIterator.next()!

      // If there was only a single whitespace run in each input, then that means there weren't any
      // newlines. Therefore, we're looking at inter-token spacing, unless the whitespace runs
      // preceded the first token in the file (i.e., offset == 0), in which case we ignore it here
      // and handle it as an indentation check below.
      if userIndex > 0 {
        checkForSpacingErrors(userIndex: userIndex, userRun: userRun, formattedRun: formattedRun)
      }
    } else {
      var runIndex = 0
      let excessUserLines = userRuns.count - formattedRuns.count

      while let userRun = userRunsIterator.next() {
        let possibleFormattedRun = formattedRunsIterator.next()

        if runIndex < excessUserLines {
          // If there were excess newlines in the user input, tell the user to remove them. This
          // short-circuits the trailing whitespace check below; we don't bother telling the user
          // about trailing whitespace on a line that we're also telling them to delete.
          diagnose(.removeLineError, category: .removeLine, utf8Offset: userIndex)
          userIndex += userRun.count + 1
        } else if runIndex != userRuns.count - 1 {
          if let formattedRun = possibleFormattedRun {
            // If this isn't the last whitespace run, then it must precede a newline, so we check
            // for trailing whitespace violations.
            checkForTrailingWhitespaceErrors(
              userIndex: userIndex,
              userRun: userRun,
              formattedRun: formattedRun
            )
          }
          userIndex += userRun.count + 1
        }

        runIndex += 1
      }
    }

    if userIndex == 0 || (userRuns.count > 1 && formattedRuns.count > 1) {
      // Advance to the last formatted whitespace run if we haven't already. This run precedes
      // a token, so we check it for leading indentation violations.
      while formattedRunsIterator.next() != nil {}
      if let lastFormattedRun = formattedRunsIterator.latestElement {
        checkForIndentationErrors(
          userIndex: userIndex,
          userRun: userRunsIterator.latestElement!,
          formattedRun: lastFormattedRun
        )
      }
    }

    // If there were more lines in the formatted output and the user's line did not exceed the
    // line length limit, tell the user to add the necessary blank lines.
    let excessFormattedLines = formattedRuns.count - userRuns.count
    if excessFormattedLines > 0 && !isLineTooLong {
      diagnose(
        .addLinesError(excessFormattedLines),
        category: .addLines,
        utf8Offset: userWhitespace.startIndex
      )
    }
  }

  /// Check the user text for line length violations.
  ///
  /// - Parameters:
  ///   - userIndex The current character offset within the user text.
  ///   - formattedIndex: The current character offset within the formatted text.
  ///   - userRuns: The current newline-separated runs of whitespace in the user text.
  ///   - formattedRuns: The current newline-separated runs of whitespace in the formatted text.
  private func checkForLineLengthErrors(
    userIndex: Int,
    formattedIndex: Int,
    userRuns: LazySplitSequence<ArraySlice<UTF8.CodeUnit>>,
    formattedRuns: LazySplitSequence<ArraySlice<UTF8.CodeUnit>>
  ) {
    // Only run this check at the start of a line.
    guard
      (userRuns.count > 1 && formattedRuns.count > 1)
        || (userRuns.count == 1 && formattedRuns.count == 1 && userIndex == 0)
    else {
      return
    }

    let lengthLimit = context.configuration.lineLength

    // Move the offset to the first non-whitespace character.
    var adjustedUserIndex = userIndex
    var lastUserRun: ArraySlice<UTF8.CodeUnit>!
    for (index, userRun) in userRuns.enumerated() {
      lastUserRun = userRun
      if index < userRuns.count - 1 {
        adjustedUserIndex += userRun.count + 1
      }
    }

    // Calculate the length of the user's line.
    let userIndent = lastUserRun.count
    var userLength = userIndent
    for index in adjustedUserIndex..<userText.count {
      // Count characters up to the newline.
      if userText[index] == utf8Newline { break }
      userLength += 1
    }

    // Exit if the user's line is within limits
    if userLength <= lengthLimit {
      isLineTooLong = false
      return
    }

    // Move the offset to the first non-whitespace character.
    var adjustedFormattedIndex = formattedIndex
    var lastFormattedRun: ArraySlice<UTF8.CodeUnit>!
    for (index, formattedRun) in formattedRuns.enumerated() {
      lastFormattedRun = formattedRun
      if index < formattedRuns.count - 1 {
        adjustedFormattedIndex += formattedRun.count + 1
      }
    }

    // Calculate the length of the formatted line.
    let formattedIndent = lastFormattedRun.count
    var formattedLength = formattedIndent
    for index in adjustedFormattedIndex..<formattedText.count {
      // Count characters up to the newline.
      if formattedText[index] == utf8Newline { break }
      formattedLength += 1
    }

    // If the formatted text produces a line that is too long, don't raise an error.
    if formattedLength > lengthLimit {
      isLineTooLong = false
      return
    }

    isLineTooLong = true
    diagnose(.lineLengthError, category: .lineLength, utf8Offset: adjustedUserIndex)
  }

  /// Compare user and formatted whitespace buffers, and check for indentation errors.
  ///
  /// Example:
  ///
  ///     func myFun() {
  ///     let a = 123  // Indentation error on this line
  ///     }
  ///
  /// - Parameters:
  ///   - userIndex: The current character offset within the user text.
  ///   - userRun: A run of whitespace from the user text.
  ///   - formattedRun: A run of whitespace from the formatted text.
  private func checkForIndentationErrors(
    userIndex: Int,
    userRun: ArraySlice<UTF8.CodeUnit>,
    formattedRun: ArraySlice<UTF8.CodeUnit>
  ) {
    guard userRun != formattedRun else { return }

    let actual = indentation(of: userRun)
    let expected = indentation(of: formattedRun)
    diagnose(
      .indentationError(expected: expected, actual: actual),
      category: .indentation,
      utf8Offset: userIndex
    )
  }

  /// Compare user and formatted whitespace buffers, and check for trailing whitespace.
  ///
  /// - Parameters:
  ///   - userIndex: The current character offset within the user text.
  ///   - userRun: The tokenized user whitespace buffer.
  ///   - formattedRun: The tokenized formatted whitespace buffer.
  private func checkForTrailingWhitespaceErrors(
    userIndex: Int,
    userRun: ArraySlice<UTF8.CodeUnit>,
    formattedRun: ArraySlice<UTF8.CodeUnit>
  ) {
    if userRun != formattedRun {
      diagnose(.trailingWhitespaceError, category: .trailingWhitespace, utf8Offset: userIndex)
    }
  }

  /// Compare user and formatted whitespace buffers, and check for spacing errors.
  ///
  /// Example:
  ///
  ///     let a : Int = 123  // Spacing error before the colon
  ///
  /// - Parameters:
  ///   - userIndex: The current character offset within the user text.
  ///   - userRun: The tokenized user whitespace buffer.
  ///   - formattedRun: The tokenized formatted whitespace buffer.
  private func checkForSpacingErrors(
    userIndex: Int,
    userRun: ArraySlice<UTF8.CodeUnit>,
    formattedRun: ArraySlice<UTF8.CodeUnit>
  ) {
    guard userRun != formattedRun else { return }

    // This assumes tabs will always be forbidden for inter-token spacing (but not for leading
    // indentation).
    if userRun.contains(utf8Tab) {
      diagnose(.spacingCharError, category: .spacingCharacter, utf8Offset: userIndex)
    } else if formattedRun.count != userRun.count {
      let delta = formattedRun.count - userRun.count
      diagnose(.spacingError(delta), category: .spacing, utf8Offset: userIndex)
    }
  }

  /// Find the next non-whitespace character in a given string, and any leading whitespace before
  /// the character.
  ///
  /// If the character at `offset` is whitespace, we scan forward until we find a non-whitespace
  /// character. We then return the new offset, the character we landed on, and a string containing
  /// the character's leading whitespace.
  ///
  /// - Parameters:
  ///   - offset: The printable character offset within the string.
  ///   - data: The input string.
  /// - Returns: A slice of `data` that covers the contiguous whitespace starting at the given
  ///   index.
  private func contiguousWhitespace(
    startingAt offset: Int,
    in data: [UTF8.CodeUnit]
  ) -> ArraySlice<UTF8.CodeUnit> {
    guard
      let whitespaceEnd =
        data[offset...].firstIndex(where: { !UnicodeScalar($0).properties.isWhitespace })
    else {
      return data[offset..<data.endIndex]
    }
    return data[offset..<whitespaceEnd]
  }

  /// Returns the code unit at the given index, or nil if the index is the end of the data.
  ///
  /// This helper is only used in an assertion that verifies that the non-whitespace code units in
  /// the text are identical, but is not evaluated in release builds.
  private func safeCodeUnit(at index: Int, in data: [UTF8.CodeUnit]) -> UTF8.CodeUnit? {
    return index != data.endIndex ? data[index] : nil
  }

  /// Emits a finding with the given message and category. The message will correspond to a specific
  /// location (line and column number) in the input Swift source file (`userText`).
  ///
  /// - Parameters:
  ///   - message: The message we wish to emit.
  ///   - category: The category of the finding.
  ///   - utf8Offset: The UTF-8 offset location of the message.
  private func diagnose(
    _ message: Finding.Message,
    category: WhitespaceFindingCategory,
    utf8Offset: Int
  ) {
    let absolutePosition = AbsolutePosition(utf8Offset: utf8Offset)
    let sourceLocation = context.sourceLocationConverter.location(for: absolutePosition)
    context.findingEmitter.emit(
      message,
      category: category,
      location: Finding.Location(sourceLocation)
    )
  }

  /// Returns the indentation that represents the indentation of the given whitespace, which is the
  /// leading spacing for a line.
  private func indentation(of whitespace: ArraySlice<UTF8.CodeUnit>) -> WhitespaceIndentation {
    if whitespace.count == 0 {
      return .none
    }

    var orderedRuns: [(char: UTF8.CodeUnit, count: Int)] = []
    for char in whitespace {
      let lastRun = orderedRuns.last
      if lastRun?.char == char {
        orderedRuns[orderedRuns.endIndex - 1].count += 1
      } else {
        orderedRuns.append((char, 1))
      }
    }

    let indents = orderedRuns.map { run in
      // Assumes any non-tab whitespace character is some type of space.
      return run.char == utf8Tab ? Indent.tabs(run.count) : Indent.spaces(run.count)
    }
    if indents.count == 1, let onlyIndent = indents.first {
      return .homogeneous(onlyIndent)
    }
    return .heterogeneous(indents)
  }
}

/// Describes the composition of the whitespace that creates an indentation for a line of code.
public enum WhitespaceIndentation: Equatable {
  /// The line has no preceding whitespace, meaning there's no indentation.
  case none

  /// The line's leading whitespace consists of a single run of one kind of whitespace character.
  case homogeneous(Indent)

  /// The line's leading whitespace consists of multiple runs of different kinds of whitespace
  /// characters.
  case heterogeneous([Indent])
}

extension Indent {
  /// Returns a string that describes the indentation in a human readable format, which is
  /// appropriate for use in diagnostic messages.
  fileprivate var diagnosticDescription: String {
    switch self {
    case .spaces(let count):
      let noun = count == 1 ? "space" : "spaces"
      return "\(count) \(noun)"
    case .tabs(let count):
      let noun = count == 1 ? "tab" : "tabs"
      return "\(count) \(noun)"
    }
  }
}

extension WhitespaceIndentation {
  /// Returns a string that describes the whitespace in a human readable format, which is
  /// appropriate for use in diagnostic messages.
  fileprivate var diagnosticDescription: String {
    switch self {
    case .none:
      return "no indentation"
    case .heterogeneous(let indents):
      guard let first = indents.first else { return "no indentation" }
      return indents.dropFirst().reduce(first.diagnosticDescription) {
        return $0 + ", " + $1.diagnosticDescription
      }
    case .homogeneous(let indent):
      return indent.diagnosticDescription
    }
  }
}

extension Finding.Message {
  fileprivate static let trailingWhitespaceError: Finding.Message = "remove trailing whitespace"

  fileprivate static func indentationError(
    expected expectedIndentation: WhitespaceIndentation,
    actual actualIndentation: WhitespaceIndentation
  ) -> Finding.Message {
    switch expectedIndentation {
    case .none:
      return "remove all leading whitespace"

    case .homogeneous, .heterogeneous:
      if case .homogeneous(let expectedIndent) = expectedIndentation,
        case .homogeneous(let actualIndent) = actualIndentation
      {
        if case .spaces(let expectedCount) = expectedIndent,
          case .spaces(let actualCount) = actualIndent
        {
          let delta = expectedCount - actualCount
          let verb = delta > 0 ? "indent" : "unindent"
          return "\(verb) by \(abs(delta)) spaces"
        }
        if case .tabs(let expectedCount) = expectedIndent,
          case .tabs(let actualCount) = actualIndent
        {
          let delta = expectedCount - actualCount
          let verb = delta > 0 ? "indent" : "unindent"
          return "\(verb) by \(abs(delta)) tabs"
        }
        // Intentionally fallthrough to the heterogeneous indentation diagnostic below.
      }
      // Otherwise, the change can't be described by a simple add/remove N spaces/tabs. It's easier
      // to instruct the user to remove the existing whitespace and add the appropriate sequence of
      // indenting characters.
      let expectedDescription = expectedIndentation.diagnosticDescription
      return "replace leading whitespace with \(expectedDescription)"
    }
  }

  fileprivate static func spacingError(_ spaces: Int) -> Finding.Message {
    let verb = spaces > 0 ? "add" : "remove"
    let noun = abs(spaces) == 1 ? "space" : "spaces"
    return "\(verb) \(abs(spaces)) \(noun)"
  }

  fileprivate static let spacingCharError: Finding.Message = "use spaces for spacing"

  fileprivate static let removeLineError: Finding.Message = "remove line break"

  fileprivate static func addLinesError(_ lines: Int) -> Finding.Message {
    let noun = lines == 1 ? "break" : "breaks"
    return "add \(lines) line \(noun)"
  }

  fileprivate static let lineLengthError: Finding.Message = "line is too long"
}
