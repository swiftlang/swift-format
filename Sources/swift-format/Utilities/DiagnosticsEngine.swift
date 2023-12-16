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
import SwiftSyntax
import SwiftDiagnostics

/// Unifies the handling of findings from the linter, parsing errors from the syntax parser, and
/// generic errors from the frontend so that they are emitted in a uniform fashion.
///
/// To best support parallel mode, the diagnostic engine asynchronously enqueues diagnostics and the
/// `emit*` and `consume*` methods return immediately, before the handlers have been called.
/// However, the engine does guarantee the following:
///
/// *   Diagnostics are processed in the order that those methods are called.
/// *   Calls to the registered handlers will not overlap, so they do not need to internally
///     synchronize themselves (for example, when printing diagnostics across multiple tasks to
///     standard error).
actor DiagnosticsEngine {
  /// The handler functions that will be called to process diagnostics that are emitted.
  private let handlers: [(Diagnostic) -> Void]

  /// A Boolean value indicating whether any errors were emitted by the diagnostics engine.
  private(set) var hasErrors: Bool

  /// A Boolean value indicating whether any warnings were emitted by the diagnostics engine.
  private(set) var hasWarnings: Bool

  /// The continuation used to enqueue emitted diagnostics into the async stream.
  private nonisolated let continuation: AsyncStream<Diagnostic>.Continuation

  /// The background task that iterates over the diagnostics as they are emitted and hands them off
  /// to the handlers.
  private var streamTask: Task<Void, Never>!

  /// Creates a new diagnostics engine with the given diagnostic handlers.
  ///
  /// - Parameter diagnosticsHandlers: An array of functions, each of which takes a `Diagnostic` as
  ///   its sole argument and returns `Void`. The functions are called whenever a diagnostic is
  ///   received by the engine.
  init(diagnosticsHandlers: [(Diagnostic) -> Void]) async {
    self.handlers = diagnosticsHandlers
    self.hasErrors = false
    self.hasWarnings = false

    var continuation: AsyncStream<Diagnostic>.Continuation!
    let diagnosticStream: AsyncStream<Diagnostic> = .init { continuation = $0 }
    self.continuation = continuation
    self.streamTask = Task {
      await self.streamDiagnostics(from: diagnosticStream)
    }
  }

  /// Processes diagnostics from the given stream as they arrive, sending each one to the registered
  /// handlers.
  private func streamDiagnostics(from stream: AsyncStream<Diagnostic>) async {
    for await diagnostic in stream {
      switch diagnostic.severity {
      case .error: self.hasErrors = true
      case .warning: self.hasWarnings = true
      default: break
      }

      for handler in handlers {
        handler(diagnostic)
      }
    }

    // TODO: It would be useful to model handlers as a protocol instead so that we can add a
    // `flush()` method to them. This could support handlers that need to finalize their results;
    // for example, a JSON diagnostic printer that needs to know when the stream has ended so that
    // it can terminate its root object.
  }

  /// Emits the diagnostic by passing it to the registered handlers, and tracks whether it was an
  /// error or warning diagnostic.
  private nonisolated func emit(_ diagnostic: Diagnostic) {
    continuation.yield(diagnostic)
  }

  /// Waits until the remaining diagnostics in the stream have been processed.
  ///
  /// This method must be called before program shutdown to ensure that all remaining diagnostics
  /// are handled.
  nonisolated func flush() async {
    continuation.finish()
    await self.streamTask.value
  }

  /// Emits a generic error message.
  ///
  /// - Parameters:
  ///   - message: The message associated with the error.
  ///   - location: The location in the source code associated with the error, or nil if there is no
  ///     location associated with the error.
  nonisolated func emitError(_ message: String, location: SourceLocation? = nil) {
    emit(
      Diagnostic(
        severity: .error,
        location: location.map(Diagnostic.Location.init),
        message: message))
  }

  /// Emits a generic warning message.
  ///
  /// - Parameters:
  ///   - message: The message associated with the error.
  ///   - location: The location in the source code associated with the error, or nil if there is no
  ///     location associated with the error.
  nonisolated func emitWarning(_ message: String, location: SourceLocation? = nil) {
    emit(
      Diagnostic(
        severity: .warning,
        location: location.map(Diagnostic.Location.init),
        message: message))
  }

  /// Emits a finding from the linter and any of its associated notes as diagnostics.
  ///
  /// - Parameter finding: The finding that should be emitted.
  nonisolated func consumeFinding(_ finding: Finding) {
    emit(diagnosticMessage(for: finding))

    for note in finding.notes {
      emit(
        Diagnostic(
          severity: .note,
          location: note.location.map(Diagnostic.Location.init),
          message: "\(note.message)"))
    }
  }

  /// Emits a diagnostic from the syntax parser and any of its associated notes.
  ///
  /// - Parameter diagnostic: The syntax parser diagnostic that should be emitted.
  nonisolated func consumeParserDiagnostic(
    _ diagnostic: SwiftDiagnostics.Diagnostic,
    _ location: SourceLocation
  ) {
    emit(diagnosticMessage(for: diagnostic.diagMessage, at: location))
  }

  /// Converts a diagnostic message from the syntax parser into a diagnostic message that can be
  /// used by the `TSCBasic` diagnostics engine and returns it.
  private nonisolated func diagnosticMessage(
    for message: SwiftDiagnostics.DiagnosticMessage,
    at location: SourceLocation
  ) -> Diagnostic {
    let severity: Diagnostic.Severity
    switch message.severity {
    case .error: severity = .error
    case .warning: severity = .warning
    case .note: severity = .note
    case .remark: severity = .note // should we model this?
    }
    return Diagnostic(
      severity: severity,
      location: Diagnostic.Location(location),
      category: nil,
      message: message.message)
  }

  /// Converts a lint finding into a diagnostic message that can be used by the `TSCBasic`
  /// diagnostics engine and returns it.
  private nonisolated func diagnosticMessage(for finding: Finding) -> Diagnostic {
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
      message: "\(finding.message.text)")
  }
}
