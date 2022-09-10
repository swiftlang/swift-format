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
import SwiftParser

class Frontend {
  /// Represents a file to be processed by the frontend and any file-specific options associated
  /// with it.
  final class FileToProcess {
    /// An open file handle to the source code of the file.
    private let fileHandle: FileHandle

    /// A file URL representing the path to the source file being processed.
    ///
    /// It is the responsibility of the specific frontend to make guarantees about the validity of
    /// this path. For example, the formatting frontend ensures that it is a path to an existing
    /// file only when doing in-place formatting (so that the file can be replaced). In other
    /// situations, it may correspond to a different file than the underlying file handle (if
    /// standard input is used with the `--assume-filename` flag), or it may not be a valid path at
    /// all (the string `"<stdin>"`).
    let url: URL

    /// The configuration that should applied for this file.
    let configuration: Configuration

    /// Returns the string contents of the file.
    ///
    /// The contents of the file are assumed to be UTF-8 encoded. If there is an error decoding the
    /// contents, `nil` will be returned.
    lazy var sourceText: String? = {
      let sourceData = fileHandle.readDataToEndOfFile()
      defer { fileHandle.closeFile() }
      return String(data: sourceData, encoding: .utf8)
    }()

    init(fileHandle: FileHandle, url: URL, configuration: Configuration) {
      self.fileHandle = fileHandle
      self.url = url
      self.configuration = configuration
    }
  }

  /// Prints diagnostics to standard error, optionally with color.
  final let diagnosticPrinter: StderrDiagnosticPrinter

  /// The diagnostic engine to which warnings and errors will be emitted.
  final let diagnosticsEngine: UnifiedDiagnosticsEngine

  /// Options that apply during formatting or linting.
  final let lintFormatOptions: LintFormatOptions

  /// Loads formatter configuration files.
  final var configurationLoader = ConfigurationLoader()

  /// Advanced options that are useful for developing/debugging but otherwise not meant for general
  /// use.
  final var debugOptions: DebugOptions {
    [
      lintFormatOptions.debugDisablePrettyPrint ? .disablePrettyPrint : [],
      lintFormatOptions.debugDumpTokenStream ? .dumpTokenStream : [],
    ]
  }

  /// Creates a new frontend with the given options.
  ///
  /// - Parameter lintFormatOptions: Options that apply during formatting or linting.
  init(lintFormatOptions: LintFormatOptions) {
    self.lintFormatOptions = lintFormatOptions

    self.diagnosticPrinter = StderrDiagnosticPrinter(
      colorMode: lintFormatOptions.colorDiagnostics.map { $0 ? .on : .off } ?? .auto)
    self.diagnosticsEngine =
      UnifiedDiagnosticsEngine(diagnosticsHandlers: [diagnosticPrinter.printDiagnostic])
  }

  /// Runs the linter or formatter over the inputs.
  final func run() {
    if lintFormatOptions.paths.isEmpty {
      processStandardInput()
    } else {
      processURLs(
        lintFormatOptions.paths.map(URL.init(fileURLWithPath:)),
        parallel: lintFormatOptions.parallel)
    }
  }

  /// Called by the frontend to process a single file.
  ///
  /// Subclasses must override this method to provide the actual linting or formatting logic.
  ///
  /// - Parameter fileToProcess: A `FileToProcess` that contains information about the file to be
  ///   processed.
  func processFile(_ fileToProcess: FileToProcess) {
    fatalError("Must be overridden by subclasses.")
  }

  /// Processes source content from standard input.
  private func processStandardInput() {
    guard let configuration = configuration(
      at: lintFormatOptions.configurationPath.map(URL.init(fileURLWithPath:)),
      orInferredFromSwiftFileAt: nil)
    else {
      // Already diagnosed in the called method.
      return
    }

    let fileToProcess = FileToProcess(
      fileHandle: FileHandle.standardInput,
      url: URL(fileURLWithPath: lintFormatOptions.assumeFilename ?? "<stdin>"),
      configuration: configuration)
    processFile(fileToProcess)
  }

  /// Processes source content from a list of files and/or directories provided as file URLs.
  private func processURLs(_ urls: [URL], parallel: Bool) {
    precondition(
      !urls.isEmpty,
      "processURLs(_:) should only be called when 'urls' is non-empty.")

    if parallel {
      let filesToProcess = FileIterator(urls: urls).compactMap(openAndPrepareFile)
      DispatchQueue.concurrentPerform(iterations: filesToProcess.count) { index in
        processFile(filesToProcess[index])
      }
    } else {
      FileIterator(urls: urls).lazy.compactMap(openAndPrepareFile).forEach(processFile)
    }
  }

  /// Read and prepare the file at the given path for processing, optionally synchronizing
  /// diagnostic output.
  private func openAndPrepareFile(at url: URL) -> FileToProcess? {
    guard let sourceFile = try? FileHandle(forReadingFrom: url) else {
      diagnosticsEngine.emitError(
        "Unable to open \(url.relativePath): file is not readable or does not exist")
      return nil
    }

    guard
      let configuration = configuration(
        at: lintFormatOptions.configurationPath.map(URL.init(fileURLWithPath:)),
        orInferredFromSwiftFileAt: url)
    else {
      // Already diagnosed in the called method.
      return nil
    }

    return FileToProcess(fileHandle: sourceFile, url: url, configuration: configuration)
  }

  /// Returns the configuration that applies to the given `.swift` source file, when an explicit
  /// configuration path is also perhaps provided.
  ///
  /// - Parameters:
  ///   - configurationFilePath: The path to a configuration file that will be loaded, or `nil` to
  ///     try to infer it from `swiftFilePath`.
  ///   - swiftFilePath: The path to a `.swift` file, which will be used to infer the path to the
  ///     configuration file if `configurationFilePath` is nil.
  /// - Returns: If successful, the returned configuration is the one loaded from
  ///   `configurationFilePath` if it was provided, or by searching in paths inferred by
  ///   `swiftFilePath` if one exists, or the default configuration otherwise. If an error occurred
  ///   when reading the configuration, a diagnostic is emitted and `nil` is returned.
  private func configuration(
    at configurationFileURL: URL?,
    orInferredFromSwiftFileAt swiftFileURL: URL?
  ) -> Configuration? {
    // If an explicit configuration file path was given, try to load it and fail if it cannot be
    // loaded. (Do not try to fall back to a path inferred from the source file path.)
    if let configurationFileURL = configurationFileURL {
      do {
        return try configurationLoader.configuration(at: configurationFileURL)
      } catch {
        diagnosticsEngine.emitError("Unable to read configuration: \(error.localizedDescription)")
        return nil
      }
    }

    // If no explicit configuration file path was given but a `.swift` source file path was given,
    // then try to load the configuration by inferring it based on the source file path.
    if let swiftFileURL = swiftFileURL {
      do {
        if let configuration = try configurationLoader.configuration(forSwiftFileAt: swiftFileURL) {
          return configuration
        }
        // Fall through to the default return at the end of the function.
      } catch {
        diagnosticsEngine.emitError(
          "Unable to read configuration for \(swiftFileURL.path): \(error.localizedDescription)")
        return nil
      }
    }

    // If neither path was given (for example, formatting standard input with no assumed filename)
    // or if there was no configuration found by inferring it from the source file path, return the
    // default configuration.
    return Configuration()
  }
}
