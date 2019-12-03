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

import SwiftFormatConfiguration
import SwiftFormatCore
import SwiftSyntax

/// Emits linter errors for whitespace style violations by comparing the raw text of the input Swift
/// code with formatted text.
public class WhitespaceLinter {

  /// The text of the input source code to be linted.
  let userText: String

  /// The formatted version of `userText`.
  let formattedText: String

  /// The Context object containing the DiagnosticEngine.
  let context: Context

  /// Is the current line too long?
  var isLineTooLong: Bool

  /// Creates a new WhitespaceLinter with the given context.
  ///
  /// - Parameters:
  ///   - user: The text of the Swift source code to be linted.
  ///   - formatted: The formatted text to compare to `user`.
  ///   - context: The context object containing the DiagnosticEngine instance we wish to use.
  public init(user: String, formatted: String, context: Context) {
    self.userText = user
    self.formattedText = formatted
    self.context = context
    self.isLineTooLong = false
  }

  /// Perform whitespace linting.
  public func lint() {
    var userOffset = 0
    var formOffset = 0
    var isFirstCharater = true
    var lastChar: Character?

    repeat {
      let userNext = nextCharacter(offset: userOffset, data: self.userText)
      let formNext = nextCharacter(offset: formOffset, data: self.formattedText)

      // `userText` and `formattedText` should only differ in their whitespace characters.
      if userNext.char != formNext.char {
        fatalError("Characters do not match")
      }

      lastChar = userNext.char

      compareWhitespace(
        userOffset: userOffset,
        formOffset: formOffset,
        isFirstCharacter: isFirstCharater,
        userWs: userNext.whitespace,
        formattedWs: formNext.whitespace
      )

      userOffset = userNext.offset + 1
      formOffset = formNext.offset + 1
      isFirstCharater = false
    } while lastChar != nil
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
  ///   - userOffset: The current character offset within the user text.
  ///   - formOffset: The current character offset within the formatted text.
  ///   - isFirstCharacter: Are we at the first character in the text?
  ///   - userWs: The user leading whitespace buffer at the current character.
  ///   - formattedWs: The formatted leading whitespace buffer at the current character.
  func compareWhitespace(
    userOffset: Int, formOffset: Int, isFirstCharacter: Bool, userWs: String, formattedWs: String
  ) {
    // e.g. "\n" -> ["", ""], and "" -> [""]
    let userTokens = userWs.split(
      separator: "\n", omittingEmptySubsequences: false).map(String.init)
    let formTokens = formattedWs.split(
      separator: "\n", omittingEmptySubsequences: false).map(String.init)

    checkForLineLengthErrors(
      userOffset: userOffset,
      formOffset: formOffset,
      isFirstCharacter: isFirstCharacter,
      user: userTokens,
      form: formTokens)

    if userWs == formattedWs { return }

    checkForIndentationErrors(
      userOffset: userOffset,
      isFirstCharacter: isFirstCharacter,
      user: userTokens,
      form: formTokens)

    checkForTrailingWhitespaceErrors(userOffset: userOffset, user: userTokens, form: formTokens)

    checkForSpacingErrors(
      userOffset: userOffset,
      isFirstCharacter: isFirstCharacter,
      user: userTokens,
      form: formTokens)

    checkForRemoveLineErrors(userOffset: userOffset, user: userTokens, form: formTokens)

    checkForAddLineErrors(userOffset: userOffset, user: userTokens, form: formTokens)
  }

  /// Check the user text for line length violations.
  ///
  /// - Parameters:
  ///   - userOffset: The current character offset within the user text.
  ///   - formOffset: The current character offset within the formatted text.
  ///   - isFirstCharacter: Are we at the first character in the text?
  ///   - user: The tokenized user whitespace buffer.
  ///   - form: The tokenized formatted whitespace buffer.
  func checkForLineLengthErrors(
    userOffset: Int, formOffset: Int, isFirstCharacter: Bool, user: [String], form: [String]
  ) {
    // Only run this check at the start of a line.
    guard
      (user.count > 1 && form.count > 1)
        || (form.count == 1 && form.count == 1 && isFirstCharacter)
    else {
      return
    }

    let lengthLimit = context.configuration.lineLength

    var userLength = 0
    var formLength = 0

    // Move the offset to the first non-whitespace character.
    var adjustedUserOffset = userOffset
    for i in 0..<(user.count - 1) {
      adjustedUserOffset += user[i].count + 1
    }

    // Calculate the length of the user's line.
    if let userIndent = user.last?.count {
      userLength = userIndent
      for i in adjustedUserOffset..<userText.count {
        let index = userText.index(userText.startIndex, offsetBy: i)
        let char = userText[index]

        // Count characters up to the newline.
        if char == "\n" { break } else { userLength += 1 }
      }
    }

    // Exit if the user's line is within limits
    if userLength <= lengthLimit {
      isLineTooLong = false
      return
    }

    // Move the offset to the first non-whitespace character.
    var adjustedFormOffset = formOffset
    for i in 0..<(form.count - 1) {
      adjustedFormOffset += form[i].count + 1
    }

    // Calculate the length of the formatted line.
    if let formIndent = form.last?.count {
      formLength = formIndent
      for i in adjustedFormOffset..<formattedText.count {
        let index = formattedText.index(formattedText.startIndex, offsetBy: i)
        let char = formattedText[index]

        // Count characters up to the newline.
        if char == "\n" { break } else { formLength += 1 }
      }
    }

    // If the formatted text produces a line that is too long, don't raise an error.
    if formLength > lengthLimit {
      isLineTooLong = false
      return
    }

    let pos = calculatePosition(offset: adjustedUserOffset, data: self.userText)

    isLineTooLong = true
    diagnose(.lineLengthError, line: pos.line, column: pos.column, utf8Offset: 0)
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
  ///   - userOffset: The current character offset within the user text.
  ///   - isFirstCharacter: Are we at the first character in the text?
  ///   - user: The tokenized user whitespace buffer.
  ///   - form: The tokenized formatted whitespace buffer.
  func checkForIndentationErrors(
    userOffset: Int, isFirstCharacter: Bool, user: [String], form: [String]
  ) {
    guard form.count > 1 && user.count > 1 else {
      // Ordinarily, we only look for indentation spacing following a newline. The first character
      // of a file is a special case since it isn't preceded by any newlines.
      if form.count == 1 && user.count == 1 && isFirstCharacter {
        if form[0] != user[0] {
          let actual = indentation(of: user[0])
          let expected = indentation(of: form[0])
          diagnose(
            .indentationError(expected: expected, actual: actual),
            line: 1,
            column: 1,
            utf8Offset: 0)
        }
      }
      return
    }
    var offset = 0
    for i in 0..<(user.count - 1) {
      offset += user[i].count + 1
    }
    if form.last != user.last {
      let pos = calculatePosition(offset: userOffset + offset, data: self.userText)
      let actual = indentation(of: user.last ?? "")
      let expected = indentation(of: form.last ?? "")
      diagnose(
        .indentationError(expected: expected, actual: actual),
        line: pos.line,
        column: pos.column,
        utf8Offset: 0)
    }
  }

  /// Compare user and formatted whitespace buffers, and check for trailing whitespace.
  ///
  /// - Parameters:
  ///   - userOffset: The current character offset within the user text.
  ///   - user: The tokenized user whitespace buffer.
  ///   - form: The tokenized formatted whitespace buffer.
  func checkForTrailingWhitespaceErrors(userOffset: Int, user: [String], form: [String]) {
    guard form.count > 1 && user.count > 1 else { return }
    var offset = 0
    for i in 0..<(user.count - 1) {
      if user[i].count > 0 {
        let pos = calculatePosition(offset: userOffset + offset, data: self.userText)
        diagnose(.trailingWhitespaceError, line: pos.line, column: pos.column, utf8Offset: 0)
      }
      offset += user[i].count + 1
    }
  }

  /// Compare user and formatted whitespace buffers, and check for spacing errors.
  ///
  /// Example:
  ///
  ///     let a : Int = 123  // Spacing error before the colon
  ///
  /// - Parameters:
  ///   - userOffset: The current character offset within the user text.
  ///   - isFirstCharacter: Are we at the first character in the text?
  ///   - user: The tokenized user whitespace buffer.
  ///   - form: The tokenized formatted whitespace buffer.
  func checkForSpacingErrors(
    userOffset: Int, isFirstCharacter: Bool, user: [String], form: [String]
  ) {
    // The spaces in front of the first character of a file are indentation and not spacing related.
    guard form.count == 1 && user.count == 1 && !isFirstCharacter else { return }
    guard form[0] != user[0] else { return }

    let pos = calculatePosition(offset: userOffset, data: self.userText)
    let illegalSpacingCharacters = ["\t"]
    if illegalSpacingCharacters.contains(where: { user[0].contains($0) }) {
      diagnose(.spacingCharError, line: pos.line, column: pos.column, utf8Offset: 0)
    } else if form[0].count != user[0].count {
      let delta = form[0].count - user[0].count
      diagnose(.spacingError(delta), line: pos.line, column: pos.column, utf8Offset: 0)
    }
  }

  /// Compare user and formatted whitespace buffers, and check if linebreaks need to be removed.
  ///
  /// Example:
  ///   Formatted:
  ///
  ///       func myfun() { return 123 }
  ///
  ///   User:
  ///
  ///       func myfun() {
  ///         return 123  // this linebreak must be removed
  ///       }  // this linebreak must be removed
  ///
  /// - Parameters:
  ///   - userOffset: The current character offset within the user text.
  ///   - user: The tokenized user whitespace buffer.
  ///   - form: The tokenized formatted whitespace buffer.
  func checkForRemoveLineErrors(userOffset: Int, user: [String], form: [String]) {
    guard form.count < user.count else { return }
    var offset = 0
    for i in 0..<(user.count - form.count) {
      let pos = calculatePosition(offset: userOffset + offset, data: self.userText)
      diagnose(.removeLineError, line: pos.line, column: pos.column, utf8Offset: 0)
      offset += user[i].count + 1
    }
  }

  /// Compare user and formatted whitespace buffers, and check if additional line breaks need to be
  /// added.
  ///
  /// Example:
  ///   Formatted:
  ///
  ///       func myFun() {
  ///         return 123
  ///       }
  ///
  ///   User:
  ///
  ///       func myFun() { return 123 }  //  add linesbreaks before and after the return statement
  ///
  /// - Parameters:
  ///   - userOffset: The current character offset within the user text.
  ///   - user: The tokenized user whitespace buffer.
  ///   - form: The tokenized formatted whitespace buffer.
  func checkForAddLineErrors(userOffset: Int, user: [String], form: [String]) {
    guard form.count > user.count && !isLineTooLong else { return }
    let pos = calculatePosition(offset: userOffset, data: self.userText)
    diagnose(
      .addLinesError(form.count - user.count), line: pos.line, column: pos.column, utf8Offset: 0
    )
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
  /// - Returns a tuple of the new offset, the non-whitespace character we landed on, and a string
  ///   containing the leading whitespace.
  func nextCharacter(offset: Int, data: String)
    -> (offset: Int, char: Character?, whitespace: String)
  {
    var whitespaceBuffer = ""

    for i in offset..<data.count {
      let index = data.index(data.startIndex, offsetBy: i)
      let char = data[index]

      if char.isWhitespace {
        whitespaceBuffer += String(char)
      } else {
        return (offset: i, char: char, whitespace: whitespaceBuffer)
      }
    }
    return (offset: data.count - 1, char: nil, whitespace: whitespaceBuffer)
  }

  /// Given a string and a printable charater offset, calculate the line and column number.
  ///
  /// - Parameters:
  ///   - offset: The printable character offset.
  ///   - data: The input string for which we want the line and column numbers.
  /// - Returns a tuple with the line and column numbers within `data`.
  func calculatePosition(offset: Int, data: String) -> (line: Int, column: Int) {
    var line = 1
    var column = 0

    for (index, char) in data.enumerated() {
      if char == "\n" {
        line += 1
        column = 0
      } else {
        column += 1
      }
      if index == offset { break }
    }
    return (line: line, column: column)
  }

  /// Emits the provided diagnostic message to the DiagnosticEngine. The message will correspond to
  /// a specific location (line and column number) in the input Swift source file (`userText`).
  ///
  /// - Parameters:
  ///   - message: The Diagnostic.Message object we wish to emit.
  ///   - line: The line number location of the message
  ///   - column: The column number location of the message
  ///   - utf8Offset: The utf8 offset location of the message
  ///   - actions: Used for attaching notes, highlights, etc.
  func diagnose(
    _ message: Diagnostic.Message,
    line: Int,
    column: Int,
    utf8Offset: Int,
    actions: ((inout Diagnostic.Builder) -> Void)? = nil
  ) {
    let loc = SourceLocation(
      line: line, column: column, offset: utf8Offset, file: context.fileURL.path)
    context.diagnosticEngine?.diagnose(
      message,
      location: loc,
      actions: actions
    )
  }

  /// Returns the indentation that represents the indentation of the given whitespace, which is the
  /// leading spacing for a line.
  ///
  /// A return value of nil indicates that there was no indentation.
  private func indentation(of whitespace: String) -> WhitespaceIndentation {
    if whitespace.count == 0 {
      return .none
    }

    var orderedRuns: [(char: Character, count: Int)] = []
    for char in whitespace {
      // Any non-whitespace character indicates the end of the indentation whitespace.
      guard char.isWhitespace else { break }

      let lastRun = orderedRuns.last
      if lastRun?.char == char {
        orderedRuns[orderedRuns.endIndex - 1].count += 1
      } else {
        orderedRuns.append((char, 1))
      }
    }

    let indents = orderedRuns.map { run in
      // Assumes any non-tab whitespace character is some type of space.
      return run.char == "\t" ? Indent.tabs(run.count) : Indent.spaces(run.count)
    }
    if indents.count == 1, let onlyIndent = indents.first {
      return .homogeneous(onlyIndent)
    }
    return .heterogeneous(indents)
  }
}

/// Describes the composition of the whitespace that creates an indentation for a line of code.
enum WhitespaceIndentation: Equatable {
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
  var diagnosticDescription: String {
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
  var diagnosticDescription: String {
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

extension Diagnostic.Message {
  static let trailingWhitespaceError = Diagnostic.Message(
    .warning, "[TrailingWhitespace]: remove trailing whitespace")

  static func indentationError(
    expected expectedIndentation: WhitespaceIndentation,
    actual actualIndentation: WhitespaceIndentation
  ) -> Diagnostic.Message {
    switch expectedIndentation {
    case .none:
      return .init(.warning, "[Indentation] remove all leading whitespace")

    case .homogeneous, .heterogeneous:
      if case .homogeneous(let expectedIndent) = expectedIndentation,
        case .homogeneous(let actualIndent) = actualIndentation
      {
        if case .spaces(let expectedCount) = expectedIndent,
          case .spaces(let actualCount) = actualIndent
        {
          let delta = expectedCount - actualCount
          let verb = delta > 0 ? "indent" : "unindent"
          return .init(.warning, "[Indentation] \(verb) by \(abs(delta)) spaces")
        }
        if case .tabs(let expectedCount) = expectedIndent,
          case .tabs(let actualCount) = actualIndent
        {
          let delta = expectedCount - actualCount
          let verb = delta > 0 ? "indent" : "unindent"
          return .init(.warning, "[Indentation] \(verb) by \(abs(delta)) tabs")
        }
        // Intentionally fallthrough to the heterogeneous indentation diagnostic below.
      }
      // Otherwise, the change can't be described by a simple add/remove N spaces/tabs. It's easier
      // to instruct the user to remove the existing whitespace and add the appropriate sequence of
      // indenting characters.
      let expectedDescription = expectedIndentation.diagnosticDescription
      return .init(.warning, "[Indentation] replace leading whitespace with \(expectedDescription)")
    }
  }

  static func spacingError(_ spaces: Int) -> Diagnostic.Message {
    let verb = spaces > 0 ? "add" : "remove"
    let noun = abs(spaces) == 1 ? "space" : "spaces"
    return .init(.warning, "[Spacing]: \(verb) \(abs(spaces)) \(noun)")
  }

  static let spacingCharError = Diagnostic.Message(
    .warning, "[SpacingCharacter]: use spaces for spacing")

  static let removeLineError = Diagnostic.Message(.warning, "[RemoveLine]: remove line break")

  static func addLinesError(_ lines: Int) -> Diagnostic.Message {
    return .init(.warning, "[AddLines]: add \(lines) line breaks")
  }

  static let lineLengthError = Diagnostic.Message(.warning, "[LineLength]: line is too long")
}
