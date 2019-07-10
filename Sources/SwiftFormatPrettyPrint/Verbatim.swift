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
import SwiftFormatConfiguration

struct Verbatim {
  var lines: [String] = []
  var leadingWhitespaceCounts: [Int] = []

  init(text: String) {
    tokenizeTextAndTrimWhitespace(text: text)
  }

  mutating func tokenizeTextAndTrimWhitespace(text: String) {
    lines = text.split(separator: "\n", omittingEmptySubsequences: false).map { String($0) }

    // Prevents an extra leading new line from being created.
    if lines[0] == "" {
      lines.remove(at: 0)
    }

    guard lines.count > 0, let index = lines.firstIndex(where: { $0 != "" }) else { return }

    // Get the number of leading whitespaces of the first line, and subract this from the number of
    // leading whitespaces for subsequent lines (if possible). Record the new leading whitespaces
    // counts, and trim off whitespace from the ends of the strings.
    let count = countLeadingWhitespaces(text: lines[index])
    leadingWhitespaceCounts = lines.map { max(countLeadingWhitespaces(text: $0) - count, 0) }
    lines = lines.map { $0.trimmingCharacters(in: CharacterSet(charactersIn: " ")) }
  }

  func print(indent: [Indent]) -> String {
    var output = ""
    for i in 0..<lines.count {
      if lines[i] != "" {
        output += indent.indentation()
        output += String(repeating: " ", count: leadingWhitespaceCounts[i])
        output += lines[i]
      }
      if i < lines.count - 1 {
        output += "\n"
      }
    }
    return output
  }

  func countLeadingWhitespaces(text: String) -> Int {
    var count = 0
    for char in text {
      if char == " " { count += 1 } else { break }
    }
    return count
  }
}
