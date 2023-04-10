//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2023 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import SwiftFormatCore
import SwiftSyntax

/// Diagnostic data that retains the separation of a finding category (if present) from the rest of
/// the message, allowing diagnostic printers that want to print those values separately to do so.
struct Diagnostic {
  /// The severity of the diagnostic.
  enum Severity {
    case note
    case warning
    case error
  }

  /// Represents the location of a diagnostic.
  struct Location {
    /// The file path associated with the diagnostic.
    var file: String

    /// The 1-based line number where the diagnostic occurred.
    var line: Int

    /// The 1-based column number where the diagnostic occurred.
    var column: Int

    /// Creates a new diagnostic location from the given source location.
    init(_ sourceLocation: SourceLocation) {
      self.file = sourceLocation.file!
      self.line = sourceLocation.line!
      self.column = sourceLocation.column!
    }

    /// Creates a new diagnostic location with the given finding location.
    init(_ findingLocation: Finding.Location) {
      self.file = findingLocation.file
      self.line = findingLocation.line
      self.column = findingLocation.column
    }
  }

  /// The severity of the diagnostic.
  var severity: Severity

  /// The location where the diagnostic occurred, if known.
  var location: Location?

  /// The category of the diagnostic, if any.
  var category: String?

  /// The message text associated with the diagnostic.
  var message: String

  var description: String {
    if let category = category {
      return "[\(category)] \(message)"
    } else {
      return message
    }
  }

  /// Creates a new diagnostic with the given severity, location, optional category, and
  /// message.
  init(severity: Severity, location: Location?, category: String? = nil, message: String) {
    self.severity = severity
    self.location = location
    self.category = category
    self.message = message
  }
}
