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

import SwiftFormatCore
import SwiftSyntax
import SwiftSyntaxParser
import TSCBasic

/// Unifies the handling of findings from the linter, parsing errors from the syntax parser, and
/// generic errors from the frontend so that they are treated uniformly by the underlying
/// diagnostics engine from the `swift-tools-support-core` package.
final class UnifiedDiagnosticsEngine {
  /// Represents a location from either the linter or the syntax parser and supports converting it
  /// to a string representation for printing.
  private enum UnifiedLocation: DiagnosticLocation {
    /// A location received from the syntax parser.
    case parserLocation(SourceLocation)

    /// A location received from the linter.
    case findingLocation(Finding.Location)

    var description: String {
      switch self {
      case .parserLocation(let location):
        // SwiftSyntax's old diagnostic printer also force-unwrapped these, so we assume that they
        // will always be present if the location itself is non-nil.
        return "\(location.file!):\(location.line!):\(location.column!)"
      case .findingLocation(let location):
        return "\(location.file):\(location.line):\(location.column)"
      }
    }
  }

  /// The underlying diagnostics engine.
  private let diagnosticsEngine: DiagnosticsEngine

  /// A Boolean value indicating whether any errors were emitted by the diagnostics engine.
  var hasErrors: Bool { diagnosticsEngine.hasErrors }

  /// A Boolean value indicating whether any warnings were emitted by the diagnostics engine.
  var hasWarnings: Bool {
    diagnosticsEngine.diagnostics.contains { $0.behavior == .warning }
  }

  /// Creates a new unified diagnostics engine with the given diagnostic handlers.
  ///
  /// - Parameter diagnosticsHandlers: An array of functions, each of which takes a `Diagnostic` as
  ///   its sole argument and returns `Void`. The functions are called whenever a diagnostic is
  ///   received by the engine.
  init(diagnosticsHandlers: [DiagnosticsEngine.DiagnosticsHandler]) {
    self.diagnosticsEngine = DiagnosticsEngine(handlers: diagnosticsHandlers)
  }

  /// Emits a generic error message.
  ///
  /// - Parameters:
  ///   - message: The message associated with the error.
  ///   - location: The location in the source code associated with the error, or nil if there is no
  ///     location associated with the error.
  func emitError(_ message: String, location: SourceLocation? = nil) {
    diagnosticsEngine.emit(.error(message), location: location.map(UnifiedLocation.parserLocation))
  }

  /// Emits a finding from the linter and any of its associated notes as diagnostics.
  ///
  /// - Parameter finding: The finding that should be emitted.
  func consumeFinding(_ finding: Finding) {
    diagnosticsEngine.emit(
      diagnosticMessage(for: finding),
      location: finding.location.map(UnifiedLocation.findingLocation))

    for note in finding.notes {
      diagnosticsEngine.emit(
        .note("\(note.message)"),
        location: note.location.map(UnifiedLocation.findingLocation))
    }
  }

  /// Emits a diagnostic from the syntax parser and any of its associated notes.
  ///
  /// - Parameter diagnostic: The syntax parser diagnostic that should be emitted.
  func consumeParserDiagnostic(_ diagnostic: SwiftSyntaxParser.Diagnostic) {
    diagnosticsEngine.emit(
      diagnosticMessage(for: diagnostic.message),
      location: diagnostic.location.map(UnifiedLocation.parserLocation))

    for note in diagnostic.notes {
      diagnosticsEngine.emit(
        .note(note.message.text),
        location: note.location.map(UnifiedLocation.parserLocation))
    }
  }

  /// Converts a diagnostic message from the syntax parser into a diagnostic message that can be
  /// used by the `TSCBasic` diagnostics engine and returns it.
  private func diagnosticMessage(for message: SwiftSyntaxParser.Diagnostic.Message)
    -> TSCBasic.Diagnostic.Message
  {
    switch message.severity {
    case .error: return .error(message.text)
    case .warning: return .warning(message.text)
    case .note: return .note(message.text)
    }
  }

  /// Converts a lint finding into a diagnostic message that can be used by the `TSCBasic`
  /// diagnostics engine and returns it.
  private func diagnosticMessage(for finding: Finding) -> TSCBasic.Diagnostic.Message {
    let message = "[\(finding.category)] \(finding.message.text)"

    switch finding.severity {
    case .error: return .error(message)
    case .warning: return .warning(message)
    }
  }
}
