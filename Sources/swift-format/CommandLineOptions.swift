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
import TSCBasic
import TSCUtility

/// Collects the command line options that were passed to `swift-format`.
struct CommandLineOptions {

  /// The path to the JSON configuration file that should be loaded.
  ///
  /// If not specified, the default configuration will be used.
  var configurationPath: String? = nil

  /// The filename for the source code when reading from standard input, to include in diagnostic
  /// messages.
  ///
  /// If not specified and standard input is used, a dummy filename is used for diagnostic messages
  /// about the source from standard input.
  var assumeFilename: String? = nil

  /// The mode in which to run the tool.
  ///
  /// If not specified, the tool will be run in format mode.
  var mode: ToolMode = .format

  /// Whether or not to format the Swift file in-place
  ///
  /// If specified, the current file is overwritten when formatting
  var inPlace: Bool = false

  /// Whether or not to run the formatter/linter recursively.
  ///
  /// If set, we recursively run on all ".swift" files in any provided directories.
  var recursive: Bool = false

  /// Advanced options that are useful for developing/debugging but otherwise not meant for general
  /// use.
  var debugOptions: DebugOptions = []

  /// The list of paths to Swift source files that should be formatted or linted.
  var paths: [String] = []
}

/// Process the command line argument strings and returns an object containing their values.
///
/// - Parameters:
///   - commandName: The name of the command that this tool was invoked as.
///   - arguments: The remaining command line arguments after the command name.
/// - Returns: A `CommandLineOptions` value that contains the parsed options.
func processArguments(commandName: String, _ arguments: [String]) -> CommandLineOptions {
  let parser = ArgumentParser(
    commandName: commandName,
    usage: "[options] [filename or path ...]",
    overview:
      """
      Format or lint Swift source code.

      When no files are specified, it expects the source from standard input.
      """
  )

  let binder = ArgumentBinder<CommandLineOptions>()
  binder.bind(
    option: parser.add(
      option: "--mode",
      shortName: "-m",
      kind: ToolMode.self,
      usage: "The mode to run swift-format in. Either 'format', 'lint', or 'dump-configuration'."
    )
  ) {
    $0.mode = $1
  }
  binder.bind(
    option: parser.add(
      option: "--version",
      shortName: "-v",
      kind: Bool.self,
      usage: "Prints the version and exists"
    )
  ) { opts, _ in
    opts.mode = .version
  }
  binder.bindArray(
    positional: parser.add(
      positional: "filenames or paths",
      kind: [String].self,
      optional: true,
      strategy: .upToNextOption,
      usage: "One or more input filenames",
      completion: .filename
    )
  ) {
    $0.paths = $1
  }
  binder.bind(
    option: parser.add(
      option: "--configuration",
      kind: String.self,
      usage: "The path to a JSON file containing the configuration of the linter/formatter."
    )
  ) {
    $0.configurationPath = $1
  }
  binder.bind(
    option: parser.add(
      option: "--assume-filename",
      kind: String.self,
      usage: "When using standard input, the filename of the source to include in diagnostics."
    )
  ) {
    $0.assumeFilename = $1
  }
  binder.bind(
    option: parser.add(
      option: "--in-place",
      shortName: "-i",
      kind: Bool.self,
      usage: "Overwrite the current file when formatting ('format' mode only)."
    )
  ) {
    $0.inPlace = $1
  }
  binder.bind(
    option: parser.add(
      option: "--recursive",
      shortName: "-r",
      kind: Bool.self,
      usage: "Recursively run on '.swift' files in any provided directories."
    )
  ) {
    $0.recursive = $1
  }

  // Add advanced debug/developer options. These intentionally have no usage strings, which omits
  // them from the `--help` screen to avoid noise for the general user.
  binder.bind(
    option: parser.add(
      option: "--debug-disable-pretty-print",
      kind: Bool.self
    )
  ) {
    $0.debugOptions.set(.disablePrettyPrint, enabled: $1)
  }
  binder.bind(
    option: parser.add(
      option: "--debug-dump-token-stream",
      kind: Bool.self
    )
  ) {
    $0.debugOptions.set(.dumpTokenStream, enabled: $1)
  }

  var opts = CommandLineOptions()
  do {
    let args = try parser.parse(arguments)
    try binder.fill(parseResult: args, into: &opts)

    if opts.inPlace && (ToolMode.format != opts.mode || opts.paths.isEmpty) {
      throw ArgumentParserError.unexpectedArgument("--in-place, -i")
    }

    let modeSupportsRecursive = ToolMode.format == opts.mode || ToolMode.lint == opts.mode
    if opts.recursive && (!modeSupportsRecursive || opts.paths.isEmpty) {
      throw ArgumentParserError.unexpectedArgument("--recursive, -r")
    }

    if opts.assumeFilename != nil && !opts.paths.isEmpty {
      throw ArgumentParserError.unexpectedArgument("--assume-filename")
    }

    if !opts.paths.isEmpty && !opts.recursive {
      for path in opts.paths {
        var isDir: ObjCBool = false
        if FileManager.default.fileExists(atPath: path, isDirectory: &isDir), isDir.boolValue {
          throw ArgumentParserError.invalidValue(
            argument: "'\(path)'",
            error: ArgumentConversionError.custom("for directories, use --recursive option")
          )
        }
      }
    }
  } catch {
    stderrStream.write("error: \(error)\n\n")
    parser.printUsage(on: stderrStream)
    exit(1)
  }
  return opts
}
