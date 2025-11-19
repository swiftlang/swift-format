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

import ArgumentParser

extension SwiftFormatCommand {
  /// Formats one or more files containing Swift code.
  struct Format: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
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
    var configurationOptions: ConfigurationOptions

    @OptionGroup()
    var formatOptions: LintFormatOptions

    @OptionGroup(visibility: .hidden)
    var performanceMeasurementOptions: PerformanceMeasurementsOptions

    func validate() throws {
      if inPlace && formatOptions.paths.isEmpty {
        throw ValidationError("'--in-place' is only valid when formatting files")
      }
    }

    func run() async throws {
      try await self.performanceMeasurementOptions.printingInstructionCountIfRequested {
        let diagnosticPrinter = StderrDiagnosticPrinter(
          colorMode: self.formatOptions.diagnosticsColorMode
        )

        let diagnosticsEngine = DiagnosticsEngine(
          diagnosticsHandlers: [diagnosticPrinter.printDiagnostic],
          treatWarningsAsErrors: false
        )

        let frontend = FormatFrontend(
          diagnosticEngine: diagnosticsEngine,
          configurationOptions: configurationOptions,
          lintFormatOptions: formatOptions,
          inPlace: inPlace
        )
        await frontend.run()
        if diagnosticsEngine.hasErrors { throw ExitCode.failure }
      }
    }
  }
}
