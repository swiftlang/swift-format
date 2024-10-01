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

import Foundation
import SwiftDiagnostics
import SwiftFormat
import SwiftSyntax

/// The frontend for linting operations.
class LintFrontend: Frontend {
  override func processFile(_ fileToProcess: FileToProcess) {
    let linter = SwiftLinter(
      configuration: fileToProcess.configuration,
      findingConsumer: diagnosticsEngine.consumeFinding
    )
    linter.debugOptions = debugOptions

    let url = fileToProcess.url
    guard let source = fileToProcess.sourceText else {
      diagnosticsEngine.emitError(
        "Unable to lint \(url.relativePath): file is not readable or does not exist."
      )
      return
    }

    do {
      try linter.lint(
        source: source,
        assumingFileURL: url
      ) { (diagnostic, location) in
        guard !self.lintFormatOptions.ignoreUnparsableFiles else {
          // No diagnostics should be emitted in this mode.
          return
        }
        self.diagnosticsEngine.consumeParserDiagnostic(diagnostic, location)
      }

    } catch SwiftFormatError.fileNotReadable {
      diagnosticsEngine.emitError(
        "Unable to lint \(url.relativePath): file is not readable or does not exist."
      )
      return
    } catch SwiftFormatError.fileContainsInvalidSyntax {
      guard !lintFormatOptions.ignoreUnparsableFiles else {
        // The caller wants to silently ignore this error.
        return
      }
      // Otherwise, relevant diagnostics about the problematic nodes have been emitted.
      return
    } catch {
      diagnosticsEngine.emitError("Unable to lint \(url.relativePath): \(error)")
      return
    }
  }
}
