//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2024 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import Foundation

/// Used by the PrettyPrint class to actually assemble the output string. This struct
/// tracks state specific to the output (line number, column, etc.) rather than the pretty
/// printing algorithm itself.
struct PrettyPrintBuffer {
  /// The maximum number of consecutive blank lines that may appear in a file.
  let maximumBlankLines: Int

  /// The width of the horizontal tab in spaces.
  let tabWidth: Int

  /// If true, output is generated as normal. If false, the various state variables are
  /// updated as normal but nothing is appended to the output (used by selection formatting).
  var isEnabled: Bool = true

  /// Indicates whether or not the printer is currently at the beginning of a line.
  private(set) var isAtStartOfLine: Bool = true

  /// Keeps track of the most recent number of consecutive newlines that have been printed.
  ///
  /// This value is reset to zero whenever non-newline content is printed.
  private(set) var consecutiveNewlineCount: Int = 0

  /// Keeps track of the current line number being printed.
  private(set) var lineNumber: Int = 1

  /// Keeps track of the most recent number of spaces that should be printed before the next text
  /// token.
  private(set) var pendingSpaces: Int = 0

  /// Current column position of the printer. If we just printed a newline and nothing else, it
  /// will still point to the position of the previous line.
  private(set) var column: Int

  /// The current indentation level to be used when text is appended to a new line.
  var currentIndentation: [Indent]

  /// The accumulated output of the pretty printer.
  private(set) var output: String = ""

  init(maximumBlankLines: Int, tabWidth: Int, column: Int = 0) {
    self.maximumBlankLines = maximumBlankLines
    self.tabWidth = tabWidth
    self.currentIndentation = []
    self.column = column
  }

  /// Writes newlines into the output stream, taking into account any preexisting consecutive
  /// newlines and the maximum allowed number of blank lines.
  ///
  /// This function does some implicit collapsing of consecutive newlines to ensure that the
  /// results are consistent when breaks and explicit newlines coincide. For example, imagine a
  /// break token that fires (thus creating a single non-discretionary newline) because it is
  /// followed by a group that contains 2 discretionary newlines that were found in the user's
  /// source code at that location. In that case, the break "overlaps" with the discretionary
  /// newlines and it will write a newline before we get to the discretionaries. Thus, we have to
  /// subtract the previously written newlines during the second call so that we end up with the
  /// correct number overall.
  ///
  /// - Parameters:
  ///   - newlines: The number and type of newlines to write.
  ///   - shouldIndentBlankLines: A Boolean value indicating whether to insert spaces
  ///     for blank lines based on the current indentation level.
  mutating func writeNewlines(_ newlines: NewlineBehavior, shouldIndentBlankLines: Bool) {
    let numberToPrint: Int
    switch newlines {
    case .elective:
      numberToPrint = consecutiveNewlineCount == 0 ? 1 : 0
    case .soft(let count, _):
      // We add 1 to the max blank lines because it takes 2 newlines to create the first blank line.
      numberToPrint = min(count, maximumBlankLines + 1) - consecutiveNewlineCount
    case .hard(let count):
      numberToPrint = count
    case .escaped:
      numberToPrint = 1
    }

    guard numberToPrint > 0 else { return }
    for number in 0..<numberToPrint {
      if shouldIndentBlankLines, number >= 1 {
        writeRaw(currentIndentation.indentation())
      }
      writeRaw("\n")
    }

    lineNumber += numberToPrint
    isAtStartOfLine = true
    consecutiveNewlineCount += numberToPrint
    pendingSpaces = 0
    column = 0
  }

  /// Writes the given text to the output stream.
  ///
  /// Before printing the text, this function will print any line-leading indentation or interior
  /// leading spaces that are required before the text itself.
  mutating func write(_ text: String) {
    if isAtStartOfLine {
      writeRaw(currentIndentation.indentation())
      column = currentIndentation.length(tabWidth: tabWidth)
      isAtStartOfLine = false
    } else if pendingSpaces > 0 {
      writeRaw(String(repeating: " ", count: pendingSpaces))
    }
    writeRaw(text)
    consecutiveNewlineCount = 0
    pendingSpaces = 0

    // In case of comments, we may get a multi-line string.
    // To account for that case, we need to correct the lineNumber count.
    // The new column is only the position within the last line.
    var lastLength = 0
    // We are only interested in "\n" we can use the UTF8 view and skip the grapheme clustering.
    for element in text.utf8 {
      if element == UInt8(ascii: "\n") {
        lineNumber += 1
        lastLength = 0
      } else {
        lastLength += 1
      }
    }
    column += lastLength
  }

  /// Request that the given number of spaces be printed out before the next text token.
  ///
  /// Spaces are printed only when the next text token is printed in order to prevent us from
  /// printing lines that are only whitespace or have trailing whitespace.
  mutating func enqueueSpaces(_ count: Int) {
    pendingSpaces += count
    column += count
  }

  mutating func writeVerbatim(_ verbatim: String, _ length: Int) {
    writeRaw(verbatim)
    consecutiveNewlineCount = 0
    pendingSpaces = 0
    column += length
  }

  /// Calls writeRaw, but also updates some state variables that are normally tracked by
  /// higher level functions. This is used when we switch from disabled formatting to
  /// enabled formatting, writing all the previous information as-is.
  mutating func writeVerbatimAfterEnablingFormatting<S: StringProtocol>(_ str: S) {
    writeRaw(str)
    if str.hasSuffix("\n") {
      isAtStartOfLine = true
      consecutiveNewlineCount = 1
    } else {
      isAtStartOfLine = false
      consecutiveNewlineCount = 0
    }
  }

  /// Append the given string to the output buffer.
  ///
  /// No further processing is performed on the string.
  private mutating func writeRaw<S: StringProtocol>(_ str: S) {
    guard isEnabled else { return }
    output.append(String(str))
  }
}
