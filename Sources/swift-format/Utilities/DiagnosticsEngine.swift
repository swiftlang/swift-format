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

import SwiftDiagnostics
import SwiftFormat
import SwiftSyntax

/// Unifies the handling of findings from the linter, parsing errors from the syntax parser, and
/// generic errors from the frontend so that they are emitted in a uniform fashion.
final class DiagnosticsEngine {
  /// The handler functions that will be called to process diagnostics that are emitted.
  private let handlers: [(Diagnostic) -> Void]

  /// A Boolean value indicating whether any errors were emitted by the diagnostics engine.
  private(set) var hasErrors: Bool

  /// A Boolean value indicating whether any warnings were emitted by the diagnostics engine.
  private(set) var hasWarnings: Bool

  /// Creates a new diagnostics engine with the given diagnostic handlers.
  ///
  /// - Parameter diagnosticsHandlers: An array of functions, each of which takes a `Diagnostic` as
  ///   its sole argument and returns `Void`. The functions are called whenever a diagnostic is
  ///   received by the engine.
  init(diagnosticsHandlers: [(Diagnostic) -> Void]) {
    self.handlers = diagnosticsHandlers
    self.hasErrors = false
    self.hasWarnings = false
  }

  /// Emits the diagnostic by passing it to the registered handlers, and tracks whether it was an
  /// error or warning diagnostic.
  private func emit(_ diagnostic: Diagnostic) {
    switch diagnostic.severity {
    case .error: self.hasErrors = true
    case .warning: self.hasWarnings = true
    default: break
    }

    for handler in handlers {
      handler(diagnostic)
    }
  }

  /// Emits a generic error message.
  ///
  /// - Parameters:
  ///   - message: The message associated with the error.
  ///   - location: The location in the source code associated with the error, or nil if there is no
  ///     location associated with the error.
  func emitError(_ message: String, location: SourceLocation? = nil) {
    emit(
      Diagnostic(
        severity: .error,
        location: location.map(Diagnostic.Location.init),
        message: message
      )
    )
  }

  /// Emits a generic warning message.
  ///
  /// - Parameters:
  ///   - message: The message associated with the error.
  ///   - location: The location in the source code associated with the error, or nil if there is no
  ///     location associated with the error.
  func emitWarning(_ message: String, location: SourceLocation? = nil) {
    emit(
      Diagnostic(
        severity: .warning,
        location: location.map(Diagnostic.Location.init),
        message: message
      )
    )
  }

  /// Emits a finding from the linter and any of its associated notes as diagnostics.
  ///
  /// - Parameter finding: The finding that should be emitted.
  func consumeFinding(_ finding: Finding) {
    emit(diagnosticMessage(for: finding))

    for note in finding.notes {
      emit(
        Diagnostic(
          severity: .note,
          location: note.location.map(Diagnostic.Location.init),
          message: "\(note.message)"
        )
      )
    }
  }

  /// Emits a diagnostic from the syntax parser and any of its associated notes.
  ///
  /// - Parameter diagnostic: The syntax parser diagnostic that should be emitted.
  func consumeParserDiagnostic(
    _ diagnostic: SwiftDiagnostics.Diagnostic,
    _ location: SourceLocation
  ) {
    emit(diagnosticMessage(for: diagnostic.diagMessage, at: location))
  }

  /// Converts a diagnostic message from the syntax parser into a diagnostic message that can be
  /// used by the `TSCBasic` diagnostics engine and returns it.
  private func diagnosticMessage(
    for message: SwiftDiagnostics.DiagnosticMessage,
    at location: SourceLocation
  ) -> Diagnostic {
    let severity: Diagnostic.Severity
    switch message.severity {
    case .error: severity = .error
    case .warning: severity = .warning
    case .note: severity = .note
    case .remark: severity = .note  // should we model this?
    }
    return Diagnostic(
      severity: severity,
      location: Diagnostic.Location(location),
      category: nil,
      message: message.message
    )
  }

  /// Converts a lint finding into a diagnostic message that can be used by the `TSCBasic`
  /// diagnostics engine and returns it.
  private func diagnosticMessage(for finding: Finding) -> Diagnostic {
    let severity: Diagnostic.Severity
    switch finding.severity {
    case .error: severity = .error
    case .warning: severity = .warning
    case .refactoring: severity = .warning
    case .convention: severity = .warning
    }
    return Diagnostic(
      severity: severity,
      location: finding.location.map(Diagnostic.Location.init),
      category: "\(finding.category)",
      message: "\(finding.message.text)"
    )
  }
}
