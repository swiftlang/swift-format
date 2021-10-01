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

/// The frontend for formatting operations.
class FormatFrontend: Frontend {
  /// Whether or not to format the Swift file in-place.
  private let inPlace: Bool

  init(lintFormatOptions: LintFormatOptions, inPlace: Bool) {
    self.inPlace = inPlace
    super.init(lintFormatOptions: lintFormatOptions)
  }

  override func processFile(_ fileToProcess: FileToProcess) {
    // Even though `diagnosticEngine` is defined, it's use is reserved for fatal messages. Pass nil
    // to the formatter to suppress other messages since they will be fixed or can't be
    // automatically fixed anyway.
    let formatter = SwiftFormatter(
      configuration: fileToProcess.configuration, diagnosticEngine: nil)
    formatter.debugOptions = debugOptions

    let path = fileToProcess.path
    guard let source = fileToProcess.sourceText else {
      diagnosticEngine.diagnose(
        Diagnostic.Message(.error, "Unable to read source for formatting from \(path)."))
      return
    }

    var stdoutStream = FileHandle.standardOutput
    do {
      let assumingFileURL = URL(fileURLWithPath: path)
      if inPlace {
        var buffer = ""
        try formatter.format(source: source, assumingFileURL: assumingFileURL, to: &buffer)

        let bufferData = buffer.data(using: .utf8)!  // Conversion to UTF-8 cannot fail
        try bufferData.write(to: assumingFileURL, options: .atomic)
      } else {
        try formatter.format(source: source, assumingFileURL: assumingFileURL, to: &stdoutStream)
      }
    } catch SwiftFormatError.fileNotReadable {
      diagnosticEngine.diagnose(
        Diagnostic.Message(
          .error, "Unable to format \(path): file is not readable or does not exist."))
      return
    } catch SwiftFormatError.fileContainsInvalidSyntax(let position) {
      guard !lintFormatOptions.ignoreUnparsableFiles else {
        guard !inPlace else {
          // For in-place mode, nothing is expected to stdout and the file shouldn't be modified.
          return
        }
        stdoutStream.write(source)
        return
      }
      let location = SourceLocationConverter(file: path, source: source).location(for: position)
      diagnosticEngine.diagnose(
        Diagnostic.Message(.error, "file contains invalid or unrecognized Swift syntax."),
        location: location)
      return
    } catch {
      diagnosticEngine.diagnose(Diagnostic.Message(.error, "Unable to format \(path): \(error)"))
    }
  }
}
