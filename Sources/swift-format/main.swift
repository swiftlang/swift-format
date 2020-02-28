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

extension SwiftFormatCommand {
  func run() throws {
    let diagnosticEngine = makeDiagnosticEngine()
    switch mode {
    case .format:
      if paths.isEmpty {
        let configuration = try loadConfiguration(
          forSwiftFile: nil, configFilePath: configurationPath)
        formatMain(
          configuration: configuration, sourceFile: FileHandle.standardInput,
          assumingFilename: assumeFilename, inPlace: false,
          debugOptions: debugOptions, diagnosticEngine: diagnosticEngine)
      } else {
        try processSources(from: paths, configurationPath: configurationPath, diagnosticEngine: diagnosticEngine) {
          (sourceFile, path, configuration) in
          formatMain(
            configuration: configuration, sourceFile: sourceFile, assumingFilename: path,
            inPlace: inPlace, debugOptions: debugOptions, diagnosticEngine: diagnosticEngine)
        }
      }
      
    case .lint:
      if paths.isEmpty {
        let configuration = try loadConfiguration(
          forSwiftFile: nil, configFilePath: configurationPath)
        lintMain(
            configuration: configuration, sourceFile: FileHandle.standardInput,
            assumingFilename: assumeFilename, debugOptions: debugOptions, diagnosticEngine: diagnosticEngine)
      } else {
        try processSources(from: paths, configurationPath: configurationPath, diagnosticEngine: diagnosticEngine) {
          (sourceFile, path, configuration) in
          lintMain(
            configuration: configuration, sourceFile: sourceFile, assumingFilename: path,
            debugOptions: debugOptions, diagnosticEngine: diagnosticEngine)
        }
      }
      
    case .dumpConfiguration:
      try dumpDefaultConfiguration()
    }
    
    // If any of the operations have generated diagnostics, throw an error
    // to exit with the error status code.
    if !diagnosticEngine.diagnostics.isEmpty {
      throw FormatError.exitWithDiagnosticErrors
    }
  }
}

/// Processes the source code at the given file paths by performing a transformation, provided by a
/// closure.
/// - Parameters:
///   - paths: The file paths for the source files to process with a transformation.
///   - configurationPath: The file path to a swift-format configuration file.
///   - diagnosticEngine: A diagnostic collector that handles diagnostic messages.
///   - transform: A closure that performs a transformation on a specific source file.
private func processSources(
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
fileprivate func makeDiagnosticEngine() -> DiagnosticEngine {
  let engine = DiagnosticEngine()
  let consumer = PrintingDiagnosticConsumer()
  engine.addConsumer(consumer)
  return engine
}

/// Load the configuration.
fileprivate func loadConfiguration(
  forSwiftFile swiftFilePath: String?, configFilePath: String?
) throws -> Configuration {
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

/// Dumps the default configuration as JSON to standard output.
private func dumpDefaultConfiguration() throws {
  let configuration = Configuration()
  do {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted]
    if #available(macOS 10.13, *) {
      encoder.outputFormatting.insert(.sortedKeys)
    }

    let data = try encoder.encode(configuration)
    guard let jsonString = String(data: data, encoding: .utf8) else {
      // This should never happen, but let's make sure we fail more gracefully than crashing, just
      // in case.
      throw FormatError(message: "Could not dump the default configuration: the JSON was not valid UTF-8")
    }
    print(jsonString)
  } catch {
    throw FormatError(message: "Could not dump the default configuration: \(error)")
  }
}

SwiftFormatCommand.main()
