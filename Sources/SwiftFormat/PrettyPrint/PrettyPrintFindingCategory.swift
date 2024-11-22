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
  case endOfLineComment

  /// Findings related to the presence of absence of a trailing comma in collection literals.
  case trailingComma

  var description: String {
    switch self {
    case .endOfLineComment: return "EndOfLineComment"
    case .trailingComma: return "TrailingComma"
    }
  }

  var name: String {
    self.description
  }

}
