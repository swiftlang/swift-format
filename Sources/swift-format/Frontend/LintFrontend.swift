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
import SwiftFormat
import SwiftFormatConfiguration
import SwiftSyntax
import SwiftSyntaxParser

/// The frontend for linting operations.
class LintFrontend: Frontend {
  override func processFile(_ fileToProcess: FileToProcess) {
    let linter = SwiftLinter(
      configuration: fileToProcess.configuration, diagnosticEngine: diagnosticEngine)
    linter.debugOptions = debugOptions

    let path = fileToProcess.path
    guard let source = fileToProcess.sourceText else {
      diagnosticEngine.diagnose(
        Diagnostic.Message(
          .error, "Unable to read source for linting from \(path)."))
      return
    }

    do {
      let assumingFileURL = URL(fileURLWithPath: path)
      try linter.lint(source: source, assumingFileURL: assumingFileURL)
    } catch SwiftFormatError.fileNotReadable {
      diagnosticEngine.diagnose(
        Diagnostic.Message(
          .error, "Unable to lint \(path): file is not readable or does not exist."))
      return
    } catch SwiftFormatError.fileContainsInvalidSyntax(let position) {
      guard !lintFormatOptions.ignoreUnparsableFiles else {
        // The caller wants to silently ignore this error.
        return
      }
      let location = SourceLocationConverter(file: path, source: source).location(for: position)
      diagnosticEngine.diagnose(
        Diagnostic.Message(.error, "file contains invalid or unrecognized Swift syntax."),
        location: location)
      return
    } catch {
      diagnosticEngine.diagnose(Diagnostic.Message(.error, "Unable to lint \(path): \(error)"))
      return
    }
  }
}
