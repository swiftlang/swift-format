//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2022 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import Foundation
import SwiftDiagnostics
import SwiftFormatCore
import SwiftOperators
import SwiftParser
import SwiftParserDiagnostics
import SwiftSyntax

/// Parses the given source code and returns a valid `SourceFileSyntax` node.
///
/// This helper function automatically folds sequence expressions using the given operator table,
/// ignoring errors so that formatting can do something reasonable in the presence of unrecognized
/// operators.
///
/// - Parameters:
///   - source: The Swift source code to be formatted.
///   - url: A file URL denoting the filename/path that should be assumed for this syntax tree,
///     which is associated with any diagnostics emitted during formatting. If this is nil, a
///     dummy value will be used.
///   - operatorTable: The operator table to use for sequence folding.
///   - parsingDiagnosticHandler: An optional callback that will be notified if there are any
///     errors when parsing the source code.
/// - Throws: If an unrecoverable error occurs when formatting the code.
func parseAndEmitDiagnostics(
  source: String,
  operatorTable: OperatorTable,
  assumingFileURL url: URL?,
  parsingDiagnosticHandler: ((Diagnostic, SourceLocation) -> Void)? = nil
) throws -> SourceFileSyntax {
  let sourceFile =
    operatorTable.foldAll(Parser.parse(source: source)) { _ in }.as(SourceFileSyntax.self)!

  let diagnostics = ParseDiagnosticsGenerator.diagnostics(for: sourceFile)
  var hasErrors = false
  if let parsingDiagnosticHandler = parsingDiagnosticHandler {
    let expectedConverter =
      SourceLocationConverter(file: url?.path ?? "<unknown>", tree: sourceFile)
    for diagnostic in diagnostics {
      let location = diagnostic.location(converter: expectedConverter)

      // Downgrade editor placeholders to warnings, because it is useful to support formatting
      // in-progress files that contain those.
      if diagnostic.diagnosticID == StaticTokenError.editorPlaceholder.diagnosticID {
        parsingDiagnosticHandler(downgradedToWarning(diagnostic), location)
      } else {
        parsingDiagnosticHandler(diagnostic, location)
        hasErrors = true
      }
    }
  }

  guard !hasErrors else {
    throw SwiftFormatError.fileContainsInvalidSyntax
  }

  return restoringLegacyTriviaBehavior(sourceFile)
}

// Wraps a `DiagnosticMessage` but forces its severity to be that of a warning instead of an error.
struct DowngradedDiagnosticMessage: DiagnosticMessage {
  var originalDiagnostic: DiagnosticMessage

  var message: String { originalDiagnostic.message }

  var diagnosticID: SwiftDiagnostics.MessageID { originalDiagnostic.diagnosticID }

  var severity: DiagnosticSeverity { .warning }
}

/// Returns a new `Diagnostic` that is identical to the given diagnostic, except that its severity
/// has been downgraded to a warning.
func downgradedToWarning(_ diagnostic: Diagnostic) -> Diagnostic {
  // `Diagnostic` is immutable, so create a new one with the same values except for the
  // severity-downgraded message.
  return Diagnostic(
    node: diagnostic.node,
    position: diagnostic.position,
    message: DowngradedDiagnosticMessage(originalDiagnostic: diagnostic.diagMessage),
    highlights: diagnostic.highlights,
    notes: diagnostic.notes,
    fixIts: diagnostic.fixIts
  )
}
