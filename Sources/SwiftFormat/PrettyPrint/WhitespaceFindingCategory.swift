//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2021 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

/// Categories for findings emitted by the whitespace linter.
enum WhitespaceFindingCategory: FindingCategorizing {
  /// Findings related to trailing whitespace on a line.
  case trailingWhitespace

  /// Findings related to indentation (i.e., whitespace at the beginning of a line).
  case indentation

  /// Findings related to interior whitespace (i.e., neither leading nor trailing space).
  case spacing

  /// Findings related to specific characters used for interior whitespace.
  case spacingCharacter

  /// Findings related to the removal of line breaks.
  case removeLine

  /// Findings related to the addition of line breaks.
  case addLines

  /// Findings related to the length of a line.
  case lineLength

  var description: String {
    switch self {
    case .trailingWhitespace: return "TrailingWhitespace"
    case .indentation: return "Indentation"
    case .spacing: return "Spacing"
    case .spacingCharacter: return "SpacingCharacter"
    case .removeLine: return "RemoveLine"
    case .addLines: return "AddLines"
    case .lineLength: return "LineLength"
    }
  }

  var name: String {
    return self.description
  }
}
