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

import ArgumentParser
import Foundation
import SwiftFormat
import SwiftFormatConfiguration
import SwiftSyntax

extension SwiftFormatCommand {
  /// Emits style diagnostics for one or more files containing Swift code.
  struct Lint: ParsableCommand {
    static var configuration = CommandConfiguration(
      abstract: "Diagnose style issues in Swift source code",
      discussion: "When no files are specified, it expects the source from standard input.")

    @OptionGroup()
    var lintOptions: LintFormatOptions

    func run() throws {
      let diagnosticEngine = makeDiagnosticEngine()

      if lintOptions.paths.isEmpty {
        let configuration = try loadConfiguration(
          forSwiftFile: nil, configFilePath: lintOptions.configurationPath)
        lintMain(
            configuration: configuration, sourceFile: FileHandle.standardInput,
            assumingFilename: lintOptions.assumeFilename, debugOptions: lintOptions.debugOptions,
            diagnosticEngine: diagnosticEngine)
      } else {
        try processSources(
          from: lintOptions.paths, configurationPath: lintOptions.configurationPath,
          diagnosticEngine: diagnosticEngine
        ) { sourceFile, path, configuration in
          lintMain(
            configuration: configuration, sourceFile: sourceFile, assumingFilename: path,
            debugOptions: lintOptions.debugOptions, diagnosticEngine: diagnosticEngine)
        }
      }

      try failIfDiagnosticsEmitted(diagnosticEngine)
    }
  }
}

/// Runs the linting pipeline over the provided source file.
///
/// If there were any lint diagnostics emitted, this function returns a non-zero exit code.
/// - Parameters:
///   - configuration: The `Configuration` that contains user-specific settings.
///   - sourceFile: A file handle from which to read the source code to be linted.
///   - assumingFilename: The filename of the source file, used in diagnostic output.
///   - debugOptions: The set containing any debug options that were supplied on the command line.
///   - diagnosticEngine: A diagnostic collector that handles diagnostic messages.
/// - Returns: Zero if there were no lint errors, otherwise a non-zero number.
private func lintMain(
  configuration: Configuration, sourceFile: FileHandle, assumingFilename: String?,
  debugOptions: DebugOptions, diagnosticEngine: DiagnosticEngine
) {
  let linter = SwiftLinter(configuration: configuration, diagnosticEngine: diagnosticEngine)
  linter.debugOptions = debugOptions
  let assumingFileURL = URL(fileURLWithPath: assumingFilename ?? "<stdin>")

  guard let source = readSource(from: sourceFile) else {
    diagnosticEngine.diagnose(
      Diagnostic.Message(.error, "Unable to read source for linting from \(assumingFileURL.path)."))
    return
  }

  do {
    try linter.lint(source: source, assumingFileURL: assumingFileURL)
  } catch SwiftFormatError.fileNotReadable {
    let path = assumingFileURL.path
    diagnosticEngine.diagnose(
      Diagnostic.Message(.error, "Unable to lint \(path): file is not readable or does not exist."))
    return
  } catch SwiftFormatError.fileContainsInvalidSyntax(let position) {
    let path = assumingFileURL.path
    let location = SourceLocationConverter(file: path, source: source).location(for: position)
    diagnosticEngine.diagnose(
      Diagnostic.Message(.error, "file contains invalid or unrecognized Swift syntax."),
      location: location)
    return
  } catch {
    let path = assumingFileURL.path
    diagnosticEngine.diagnose(Diagnostic.Message(.error, "Unable to lint \(path): \(error)"))
    return
  }
}
