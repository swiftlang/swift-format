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

/// Categories for findings emitted by the pretty printer.
enum PrettyPrintFindingCategory: FindingCategorizing {

  /// Finding related to an end-of-line comment.
  case endOfLineComment(Finding.Severity = .warning)

  /// Findings related to the presence of absence of a trailing comma in collection literals.
  case trailingComma(Finding.Severity = .warning)

  var description: String {
    switch self {
    case .endOfLineComment: return "EndOfLineComment"
    case .trailingComma: return "TrailingComma"
    }
  }

  var name: String {
    self.description
  }

  var severity: Finding.Severity {
    switch self {
      case .endOfLineComment(let severity): return severity
      case .trailingComma(let severity): return severity
    }
  }

}
