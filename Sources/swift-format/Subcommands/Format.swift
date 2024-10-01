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
  /// Formats one or more files containing Swift code.
  struct Format: ParsableCommand {
    static var configuration = CommandConfiguration(
      abstract: "Format Swift source code",
      discussion: "When no files are specified, it expects the source from standard input."
    )

    /// Whether or not to format the Swift file in-place.
    ///
    /// If specified, the current file is overwritten when formatting.
    @Flag(
      name: .shortAndLong,
      help: "Overwrite the current file when formatting."
    )
    var inPlace: Bool = false

    @OptionGroup()
    var formatOptions: LintFormatOptions

    @OptionGroup(visibility: .hidden)
    var performanceMeasurementOptions: PerformanceMeasurementsOptions

    func validate() throws {
      if inPlace && formatOptions.paths.isEmpty {
        throw ValidationError("'--in-place' is only valid when formatting files")
      }
    }

    func run() throws {
      try performanceMeasurementOptions.printingInstructionCountIfRequested() {
        let frontend = FormatFrontend(lintFormatOptions: formatOptions, inPlace: inPlace)
        frontend.run()
        if frontend.diagnosticsEngine.hasErrors { throw ExitCode.failure }
      }
    }
  }
}
