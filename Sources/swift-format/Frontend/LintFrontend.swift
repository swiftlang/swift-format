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

import Foundation
import SwiftFormat
import SwiftSyntax

/// The frontend for linting operations.
struct LintFrontend: Frontend {
  /// The diagnostic engine to which warnings and errors will be emitted.
  let diagnosticsEngine: DiagnosticsEngine

  /// Options that control the tool's configuration.
  let configurationOptions: ConfigurationOptions

  /// Options that apply during linting.
  let lintFormatOptions: LintFormatOptions

  /// The provider for formatter configurations.
  let configurationProvider: ConfigurationProvider

  /// Creates a new frontend with the given options.
  ///
  /// - Parameter lintFormatOptions: Options that apply during linting.
  init(
    diagnosticEngine: DiagnosticsEngine,
    configurationOptions: ConfigurationOptions,
    lintFormatOptions: LintFormatOptions
  ) {
    self.diagnosticsEngine = diagnosticEngine
    self.configurationOptions = configurationOptions
    self.lintFormatOptions = lintFormatOptions
    self.configurationProvider = ConfigurationProvider(diagnosticsEngine: self.diagnosticsEngine)
  }

  nonisolated func processFile(_ fileToProcess: borrowing FileToProcess) {
    let linter = SwiftLinter(
      configuration: fileToProcess.configuration,
      findingConsumer: diagnosticsEngine.consumeFinding
    )
    linter.debugOptions = debugOptions

    let url = fileToProcess.url
    guard let source = fileToProcess.readString() else {
      diagnosticsEngine.emitError(
        "Unable to lint \(url.relativePath): file is not readable or does not exist."
      )
      return
    }

    do {
      try linter.lint(
        source: source,
        assumingFileURL: url,
        experimentalFeatures: Set(lintFormatOptions.experimentalFeatures)
      ) { (diagnostic, location) in
        guard !self.lintFormatOptions.ignoreUnparsableFiles else {
          // No diagnostics should be emitted in this mode.
          return
        }
        self.diagnosticsEngine.consumeParserDiagnostic(diagnostic, location)
      }
    } catch SwiftFormatError.fileContainsInvalidSyntax {
      guard !lintFormatOptions.ignoreUnparsableFiles else {
        // The caller wants to silently ignore this error.
        return
      }
      // Otherwise, relevant diagnostics about the problematic nodes have already been emitted; we
      // don't need to print anything else.
    } catch {
      diagnosticsEngine.emitError("Unable to lint \(url.relativePath): \(error.localizedDescription).")
    }
  }
}
