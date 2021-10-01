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

import SwiftSyntax
import SwiftSyntaxParser

/// Information about a diagnostic tracked by `DiagnosticTrackingConsumer`.
struct EmittedDiagnostic {
  /// The message text of the diagnostic.
  var message: String

  /// The line number of the diagnostic, if it was provided.
  var line: Int?

  /// The column number of the diagnostic, if it was provided.
  var column: Int?

  /// Creates an emitted diagnostic from the given SwiftSyntax `Diagnostic`.
  init(_ diagnostic: Diagnostic) {
    self.message = diagnostic.message.text
    self.line = diagnostic.location?.line
    self.column = diagnostic.location?.column
  }

  /// Creates an emitted diagnostic from the given SwiftSyntax `Note`.
  init(_ note: Note) {
    self.message = note.message.text
    self.line = note.location?.line
    self.column = note.location?.column
  }
}

/// Tracks the diagnostics that were emitted and allows them to be .
class DiagnosticTrackingConsumer: DiagnosticConsumer {
  /// The diagnostics that have been emitted.
  private(set) var emittedDiagnostics = [EmittedDiagnostic]()

  /// Indicates whether diagnostics are being tracked.
  private var isTracking = true

  func handle(_ diagnostic: Diagnostic) {
    guard isTracking else { return }

    emittedDiagnostics.append(EmittedDiagnostic(diagnostic))
    for note in diagnostic.notes {
      emittedDiagnostics.append(EmittedDiagnostic(note))
    }
  }

  func finalize() {}

  /// Pops the first diagnostic that contains the given text and occurred at the given location from
  /// the collection of emitted diagnostics, if possible.
  ///
  /// - Parameters:
  ///   - text: The message text to match.
  ///   - line: The expected line number of the diagnostic.
  ///   - column: The expected column number of the diagnostic.
  /// - Returns: True if a diagnostic was found and popped, or false otherwise.
  func popDiagnostic(containing text: String, atLine line: Int, column: Int) -> Bool {
    let maybeIndex = emittedDiagnostics.firstIndex {
      $0.message.contains(text) && line == $0.line && column == $0.column
    }
    guard let index = maybeIndex else { return false }

    emittedDiagnostics.remove(at: index)
    return true
  }

  /// Pops the first diagnostic that contains the given text (regardless of location) from the
  /// collection of emitted diagnostics, if possible.
  ///
  /// - Parameter text: The message text to match.
  /// - Returns: True if a diagnostic was found and popped, or false otherwise.
  func popDiagnostic(containing text: String) -> Bool {
    let maybeIndex = emittedDiagnostics.firstIndex { $0.message.contains(text) }
    guard let index = maybeIndex else { return false }

    emittedDiagnostics.remove(at: index)
    return true
  }

  /// Stops tracking diagnostics.
  func stopTrackingDiagnostics() {
    isTracking = false
  }
}
