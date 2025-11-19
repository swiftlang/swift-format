//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2025 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

/// A description of a `Finding` that can be asserted during tests.
public struct FindingSpec {
  /// The marker that identifies the finding.
  package var marker: String

  /// The message text associated with the finding.
  package var message: String

  /// A description of a `Note` that should be associated with this finding.
  package var notes: [NoteSpec]

  /// Creates a new `FindingSpec` with the given values.
  package init(_ marker: String = "1️⃣", message: String, notes: [NoteSpec] = []) {
    self.marker = marker
    self.message = message
    self.notes = notes
  }
}

/// A description of a `Note` that can be asserted during tests.
package struct NoteSpec {
  /// The marker that identifies the note.
  package var marker: String

  /// The message text associated with the note.
  package var message: String

  /// Creates a new `NoteSpec` with the given values.
  package init(_ marker: String, message: String) {
    self.marker = marker
    self.message = message
  }
}
