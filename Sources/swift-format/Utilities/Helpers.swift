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
import SwiftFormatCore
import SwiftSyntax
import TSCBasic

/// Throws an error that causes the current command to exit the process with a failure exit code if
/// any of the preceding operations emitted diagnostics.
func failIfDiagnosticsEmitted(_ diagnosticEngine: DiagnosticEngine) throws {
  guard diagnosticEngine.diagnostics.isEmpty else {
    throw ExitCode.failure
  }
}

/// Reads from the given file handle until EOF is reached, then returns the contents as a UTF8
/// encoded string.
func readSource(from fileHandle: FileHandle) -> String? {
  let sourceData = fileHandle.readDataToEndOfFile()
  return String(data: sourceData, encoding: .utf8)
}

/// Processes the source code at the given file paths by performing a transformation, provided by a
/// closure.
/// - Parameters:
///   - paths: The file paths for the source files to process with a transformation.
///   - configurationPath: The file path to a swift-format configuration file.
///   - diagnosticEngine: A diagnostic collector that handles diagnostic messages.
///   - transform: A closure that performs a transformation on a specific source file.
func processSources(
  from paths: [String], configurationPath: String?,
  diagnosticEngine: DiagnosticEngine,
  transform: (FileHandle, String, Configuration) -> Void
) throws {
  for path in FileIterator(paths: paths) {
    guard let sourceFile = FileHandle(forReadingAtPath: path) else {
      diagnosticEngine.diagnose(
        Diagnostic.Message(.error, "Unable to create a file handle for source from \(path)."))
      return
    }
    let configuration = try loadConfiguration(forSwiftFile: path, configFilePath: configurationPath)
    transform(sourceFile, path, configuration)
  }
}

/// Makes and returns a new configured diagnostic engine.
func makeDiagnosticEngine() -> DiagnosticEngine {
  let engine = DiagnosticEngine()
  let consumer = PrintingDiagnosticConsumer()
  engine.addConsumer(consumer)
  return engine
}

/// Load the configuration.
func loadConfiguration(forSwiftFile swiftFilePath: String?, configFilePath: String?)
  throws -> Configuration
{
  if let configFilePath = configFilePath {
    return try decodedConfiguration(fromFile: URL(fileURLWithPath: configFilePath))
  }

  if let swiftFileURL = swiftFilePath.map(URL.init(fileURLWithPath:)),
    let configFileURL = Configuration.url(forConfigurationFileApplyingTo: swiftFileURL)
  {
    return try decodedConfiguration(fromFile: configFileURL)
  }

  return Configuration()
}

/// Loads and returns a `Configuration` from the given JSON file if it is found and is valid. If the
/// file does not exist or there was an error decoding it, the program exits with a non-zero exit
/// code.
fileprivate func decodedConfiguration(fromFile url: Foundation.URL) throws -> Configuration {
  do {
    return try Configuration(contentsOf: url)
  } catch {
    throw FormatError(message: "Could not load configuration at \(url): \(error)")
  }
}
