//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2019 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import Foundation
import SwiftFormat
import SwiftFormatConfiguration
import SwiftFormatCore
import SwiftSyntax
import TSCBasic

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
func lintMain(
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

/// Runs the formatting pipeline over the provided source file.
///
/// - Parameters:
///   - configuration: The `Configuration` that contains user-specific settings.
///   - sourceFile: A file handle from which to read the source code to be linted.
///   - assumingFilename: The filename of the source file, used in diagnostic output.
///   - inPlace: Whether or not to overwrite the current file when formatting.
///   - debugOptions: The set containing any debug options that were supplied on the command line.
///   - diagnosticEngine: A diagnostic collector that handles diagnostic messages.
/// - Returns: Zero if there were no format errors, otherwise a non-zero number.
func formatMain(
  configuration: Configuration, sourceFile: FileHandle, assumingFilename: String?, inPlace: Bool,
  debugOptions: DebugOptions, diagnosticEngine: DiagnosticEngine
) {
  let formatter = SwiftFormatter(configuration: configuration, diagnosticEngine: diagnosticEngine)
  formatter.debugOptions = debugOptions
  let assumingFileURL = URL(fileURLWithPath: assumingFilename ?? "<stdin>")

  guard let source = readSource(from: sourceFile) else {
    diagnosticEngine.diagnose(
      Diagnostic.Message(
        .error, "Unable to read source for formatting from \(assumingFileURL.path)."))
    return
  }

  do {
    if inPlace {
      let cwd = FileManager.default.currentDirectoryPath
      var buffer = BufferedOutputByteStream()
      try formatter.format(source: source, assumingFileURL: assumingFileURL, to: &buffer)
      buffer.flush()
      try localFileSystem.writeFileContents(
        AbsolutePath(assumingFileURL.path, relativeTo: AbsolutePath(cwd)),
        bytes: buffer.bytes
      )
    } else {
      try formatter.format(source: source, assumingFileURL: assumingFileURL, to: &stdoutStream)
      stdoutStream.flush()
    }
  } catch SwiftFormatError.fileNotReadable {
    let path = assumingFileURL.path
    diagnosticEngine.diagnose(
      Diagnostic.Message(
        .error, "Unable to format \(path): file is not readable or does not exist."))
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
    diagnosticEngine.diagnose(Diagnostic.Message(.error, "Unable to format \(path): \(error)"))
    return
  }
}

/// Reads from the given file handle until EOF is reached, then returns the contents as a UTF8
/// encoded string.
fileprivate func readSource(from fileHandle: FileHandle) -> String? {
  let sourceData = fileHandle.readDataToEndOfFile()
  return String(data: sourceData, encoding: .utf8)
}
