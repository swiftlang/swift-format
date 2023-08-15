//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2020 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import SwiftFormatCore

/// Information about a finding tracked by `TestingFindingConsumer`.
///
/// This type acts as a kind of type-erasing or flattening operation on `Finding`s and
/// `Finding.Note`s, allowing them to be queried during tests based on their text and location
/// without worrying about their precise nesting structure.
struct EmittedFinding {
  /// The message text of the finding.
  var message: String

  /// The line number of the finding, if it was provided.
  var line: Int?

  /// The column number of the finding, if it was provided.
  var column: Int?

  /// Creates an emitted finding from the given `Finding`.
  init(_ finding: Finding) {
    self.message = finding.message.text
    self.line = finding.location?.line
    self.column = finding.location?.column
  }

  /// Creates an emitted finding from the given `Finding.Note`.
  init(_ note: Finding.Note) {
    self.message = note.message.text
    self.line = note.location?.line
    self.column = note.location?.column
  }
}

/// Tracks the findings that were emitted and allows them to be queried during tests.
class TestingFindingConsumer {
  /// The findings that have been emitted.
  private(set) var emittedFindings = [EmittedFinding]()

  /// Indicates whether findings are being tracked.
  private var isTracking = true

  func consume(_ finding: Finding) {
    guard isTracking else { return }

    emittedFindings.append(EmittedFinding(finding))
    for note in finding.notes {
      emittedFindings.append(EmittedFinding(note))
    }
  }

  /// Pops the first finding that contains the given text and occurred at the given location from
  /// the collection of emitted findings, if possible.
  ///
  /// - Parameters:
  ///   - text: The message text to match.
  ///   - line: The expected line number of the finding.
  ///   - column: The expected column number of the finding.
  /// - Returns: True if a finding was found and popped, or false otherwise.
  func popFinding(containing text: String, atLine line: Int, column: Int) -> Bool {
    let maybeIndex = emittedFindings.firstIndex {
      $0.message.contains(text) && line == $0.line && column == $0.column
    }
    guard let index = maybeIndex else { return false }

    emittedFindings.remove(at: index)
    return true
  }

  /// Pops the first finding that contains the given text (regardless of location) from the
  /// collection of emitted findings, if possible.
  ///
  /// - Parameter text: The message text to match.
  /// - Returns: True if a finding was found and popped, or false otherwise.
  func popFinding(containing text: String) -> Bool {
    let maybeIndex = emittedFindings.firstIndex { $0.message.contains(text) }
    guard let index = maybeIndex else { return false }

    emittedFindings.remove(at: index)
    return true
  }

  /// Stops tracking findings.
  func stopTrackingFindings() {
    isTracking = false
  }
}
