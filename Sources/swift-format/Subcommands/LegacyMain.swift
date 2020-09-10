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

extension SwiftFormatCommand {
  /// Keep the legacy `-m/--mode` flag working temporarily when no other subcommand is specified.
  struct LegacyMain: ParsableCommand {
    static var configuration = CommandConfiguration(shouldDisplay: false)

    enum ToolMode: String, CaseIterable, ExpressibleByArgument {
      case format
      case lint
      case dumpConfiguration = "dump-configuration"
    }

    /// The mode in which to run the tool.
    ///
    /// If not specified, the tool will be run in format mode.
    @Option(
      name: .shortAndLong,
      help: "The mode to run swift-format in. Either 'format', 'lint', or 'dump-configuration'.")
    var mode: ToolMode = .format

    @OptionGroup()
    var lintFormatOptions: LintFormatOptions

    /// Whether or not to format the Swift file in-place.
    ///
    /// If specified, the current file is overwritten when formatting.
    @Flag(
      name: .shortAndLong,
      help: "Overwrite the current file when formatting ('format' mode only).")
    var inPlace: Bool = false

    mutating func validate() throws {
      if inPlace && (mode != .format || lintFormatOptions.paths.isEmpty) {
        throw ValidationError("'--in-place' is only valid when formatting files")
      }

      let modeSupportsRecursive = mode == .format || mode == .lint
      if lintFormatOptions.recursive && (!modeSupportsRecursive || lintFormatOptions.paths.isEmpty) {
        throw ValidationError("'--recursive' is only valid when formatting or linting files")
      }
    }

    func run() throws {
      switch mode {
      case .format:
        var format = Format()
        format.inPlace = inPlace
        format.formatOptions = lintFormatOptions
        try format.run()

      case .lint:
        var lint = Lint()
        lint.lintOptions = lintFormatOptions
        try lint.run()

      case .dumpConfiguration:
        try DumpConfiguration().run()
      }
    }
  }
}
