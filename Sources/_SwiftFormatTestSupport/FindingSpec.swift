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

import SwiftFormat

/// A description of a `Finding` that can be asserted during tests.
public struct FindingSpec {
  /// The marker that identifies the finding.
  public var marker: String

  /// The message text associated with the finding.
  public var message: String

  /// A description of a `Note` that should be associated with this finding.
  public var notes: [NoteSpec]

  /// A description of a `Note` that should be associated with this finding.
  public var severity: Finding.Severity

  /// Creates a new `FindingSpec` with the given values.
  public init(_ marker: String = "1️⃣", message: String, notes: [NoteSpec] = [], severity: Finding.Severity = .warning) {
    self.marker = marker
    self.message = message
    self.notes = notes
    self.severity = severity
  }
}

/// A description of a `Note` that can be asserted during tests.
public struct NoteSpec {
  /// The marker that identifies the note.
  public var marker: String

  /// The message text associated with the note.
  public var message: String

  /// Creates a new `NoteSpec` with the given values.
  public init(_ marker: String, message: String) {
    self.marker = marker
    self.message = message
  }
}
