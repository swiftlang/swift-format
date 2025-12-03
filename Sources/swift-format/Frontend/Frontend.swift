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
@_spi(Internal) import SwiftFormat

protocol Frontend: Sendable {
  /// The diagnostic engine to which warnings and errors will be emitted.
  var diagnosticsEngine: DiagnosticsEngine { get }

  /// Options that control the tool's configuration.
  var configurationOptions: ConfigurationOptions { get }

  /// Options that apply during formatting or linting.
  var lintFormatOptions: LintFormatOptions { get }

  /// The provider for formatter configurations.
  var configurationProvider: ConfigurationProvider { get }

  /// Called by the frontend to process a single file.
  ///
  /// Subclasses must override this method to provide the actual linting or formatting logic.
  ///
  /// - Parameter fileToProcess: A `FileToProcess` that contains information about the file to be
  ///   processed.
  func processFile(_ fileToProcess: borrowing FileToProcess)
}

extension Frontend {
  /// Advanced options that are useful for developing/debugging but otherwise not meant for general
  /// use.
  var debugOptions: DebugOptions {
    [
      lintFormatOptions.debugDisablePrettyPrint ? .disablePrettyPrint : [],
      lintFormatOptions.debugDumpTokenStream ? .dumpTokenStream : [],
    ]
  }

  /// Runs the linter or formatter over the inputs.
  func run() async {
    if lintFormatOptions.paths == ["-"] {
      await processStandardInput()
    } else if lintFormatOptions.paths.isEmpty {
      diagnosticsEngine.emitWarning(
        """
        Running swift-format without input paths is deprecated and will be removed in the future.

        Please update your invocation to do either of the following:

        - Pass `-` to read from stdin (e.g., `cat MyFile.swift | swift-format -`).
        - Pass one or more paths to Swift source files or directories containing
          Swift source files. When passing directories, make sure to include the
          `--recursive` flag.

        For more information, use the `--help` option.
        """
      )
      await processStandardInput()
    } else {
      await processURLs(
        lintFormatOptions.paths.map(URL.init(fileURLWithPath:)),
        parallel: lintFormatOptions.parallel
      )
    }
  }

  /// Processes source content from standard input.
  @MainActor
  private func processStandardInput() {
    let assumedUrl = lintFormatOptions.assumeFilename.map(URL.init(fileURLWithPath:))

    guard
      let configuration = configurationProvider.provide(
        forConfigPathOrString: configurationOptions.configuration,
        orForSwiftFileAt: assumedUrl
      )
    else {
      // Already diagnosed in the called method.
      return
    }

    let fileToProcess = FileToProcess(
      fileHandle: FileHandle.standardInput,
      url: assumedUrl ?? URL(fileURLWithPath: "<stdin>"),
      configuration: configuration,
      selection: Selection(offsetRanges: lintFormatOptions.offsets)
    )
    processFile(fileToProcess)
  }

  /// Processes source content from a list of files and/or directories provided as file URLs.
  @MainActor
  private func processURLs(_ urls: [URL], parallel: Bool) async {
    precondition(
      !urls.isEmpty,
      "processURLs(_:) should only be called when 'urls' is non-empty."
    )

    let filesToProcess = FileIterator(urls: urls, followSymlinks: lintFormatOptions.followSymlinks)

    if parallel {
      await withTaskGroup(of: Void.self) { group in
        for url in filesToProcess {
          if let file = self.openAndPrepareFile(at: url) {
            group.addTask {
              self.processFile(file)
            }
          }
        }
      }
    } else {
      for url in filesToProcess {
        if let file = self.openAndPrepareFile(at: url) {
          self.processFile(file)
        }
      }
    }
  }

  /// Read and prepare the file at the given path for processing, optionally synchronizing
  /// diagnostic output.
  @MainActor
  private func openAndPrepareFile(at url: URL) -> FileToProcess? {
    guard let sourceFile = try? FileHandle(forReadingFrom: url) else {
      diagnosticsEngine.emitError(
        "Unable to open \(url.relativePath): file is not readable or does not exist"
      )
      return nil
    }

    guard
      let configuration = configurationProvider.provide(
        forConfigPathOrString: configurationOptions.configuration,
        orForSwiftFileAt: url
      )
    else {
      // Already diagnosed in the called method.
      return nil
    }

    return FileToProcess(
      fileHandle: sourceFile,
      url: url,
      configuration: configuration,
      selection: Selection(offsetRanges: lintFormatOptions.offsets)
    )
  }
}
