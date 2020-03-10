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

import ArgumentParser
import Foundation
import SwiftFormat
import TSCBasic
import TSCUtility

/// Collects the command line options that were passed to `swift-format`.
struct SwiftFormatCommand: ParsableCommand {
  static var configuration = CommandConfiguration(
    commandName: "swift-format",
    abstract: "Format or lint Swift source code.",
    discussion: "When no files are specified, it expects the source from standard input."
  )
  
  /// The path to the JSON configuration file that should be loaded.
  ///
  /// If not specified, the default configuration will be used.
  @Option(
    name: .customLong("configuration"),
    help: "The path to a JSON file containing the configuration of the linter/formatter.")
  var configurationPath: String?

  /// The filename for the source code when reading from standard input, to include in diagnostic
  /// messages.
  ///
  /// If not specified and standard input is used, a dummy filename is used for diagnostic messages
  /// about the source from standard input.
  @Option(help: "When using standard input, the filename of the source to include in diagnostics.")
  var assumeFilename: String?

  enum ToolMode: String, CaseIterable, ExpressibleByArgument {
    case format
    case lint
    case dumpConfiguration = "dump-configuration"
  }
  
  /// The mode in which to run the tool.
  ///
  /// If not specified, the tool will be run in format mode.
  @Option(
    default: .format,
    help: "The mode to run swift-format in. Either 'format', 'lint', or 'dump-configuration'.")
  var mode: ToolMode

  /// Whether or not to format the Swift file in-place
  ///
  /// If specified, the current file is overwritten when formatting
  @Flag(
    name: .shortAndLong,
    help: "Overwrite the current file when formatting ('format' mode only).")
  var inPlace: Bool

  /// Whether or not to run the formatter/linter recursively.
  ///
  /// If set, we recursively run on all ".swift" files in any provided directories.
  @Flag(
    name: .shortAndLong,
    help: "Recursively run on '.swift' files in any provided directories.")
  var recursive: Bool

  /// The list of paths to Swift source files that should be formatted or linted.
  @Argument(help: "One or more input filenames")
  var paths: [String]
  
  @Flag(help: "Print the version and exit")
  var version: Bool
  
  @Flag(help: .hidden) var debugDisablePrettyPrint: Bool
  @Flag(help: .hidden) var debugDumpTokenStream: Bool
  
  /// Advanced options that are useful for developing/debugging but otherwise not meant for general
  /// use.
  var debugOptions: DebugOptions {
    [
      debugDisablePrettyPrint ? .disablePrettyPrint : [],
      debugDumpTokenStream ? .dumpTokenStream : [],
    ]
  }

  mutating func validate() throws {
    if version {
      throw CleanExit.message("0.0.1")
    }
    
    if inPlace && (mode != .format || paths.isEmpty) {
      throw ValidationError("'--in-place' is only valid when formatting files")
    }

    let modeSupportsRecursive = mode == .format || mode == .lint
    if recursive && (!modeSupportsRecursive || paths.isEmpty) {
      throw ValidationError("'--recursive' is only valid when formatting or linting files")
    }

    if assumeFilename != nil && !paths.isEmpty {
      throw ValidationError("'--assume-filename' is only valid when reading from stdin")
    }

    if !paths.isEmpty && !recursive {
      for path in paths {
        var isDir: ObjCBool = false
        if FileManager.default.fileExists(atPath: path, isDirectory: &isDir), isDir.boolValue {
          throw ValidationError(
            """
            '\(path)' is a path to a directory, not a Swift source file.
            Use the '--recursive' option to handle directories.
            """
          )
        }
      }
    }
  }
}
