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
  case trailingWhitespace(Finding.Severity = .warning)

  /// Findings related to indentation (i.e., whitespace at the beginning of a line).
  case indentation(Finding.Severity = .warning)

  /// Findings related to interior whitespace (i.e., neither leading nor trailing space).
  case spacing(Finding.Severity = .warning)

  /// Findings related to specific characters used for interior whitespace.
  case spacingCharacter(Finding.Severity = .warning)

  /// Findings related to the removal of line breaks.
  case removeLine(Finding.Severity = .warning)

  /// Findings related to the addition of line breaks.
  case addLines(Finding.Severity = .warning)

  /// Findings related to the length of a line.
  case lineLength(Finding.Severity = .warning)

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

  var severity: Finding.Severity {
    switch self {
      case .trailingWhitespace(let severity): return severity
      case .indentation(let severity): return severity
      case .spacing(let severity): return severity
      case .spacingCharacter(let severity): return severity
      case .removeLine(let severity): return severity
      case .addLines(let severity): return severity
      case .lineLength(let severity): return severity
    }
  }
}
