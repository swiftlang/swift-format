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
import SwiftSyntax

extension StringProtocol {
  /// Trims whitespace from the end of a string, returning a new string with no trailing whitespace.
  ///
  /// If the string is only whitespace, an empty string is returned.
  ///
  /// - Returns: The string with trailing whitespace removed.
  func trimmingTrailingWhitespace() -> String {
    if isEmpty { return String() }
    let utf8Array = Array(utf8)
    var idx = utf8Array.endIndex - 1
    while utf8Array[idx].isWhitespace {
      if idx == utf8Array.startIndex { return String() }
      idx -= 1
    }
    return String(decoding: utf8Array[...idx], as: UTF8.self)
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
      var trimmedLines = lines.dropLast().map({ $0.trimmingTrailingWhitespace() })
      if let lastLine = lines.last {
        trimmedLines.append(String(lastLine))
      }
      self.text = trimmedLines
      self.length = self.text.reduce(0, { $0 + $1.count }) + kind.prefixLength + 3
    }
  }

  func print(indent: [Indent]) -> String {
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
          let restStr = rest.map {
            let stripped = $0.dropFirst(leadingIndent.text.count)
            return indent.indentation() + stripped
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
}
