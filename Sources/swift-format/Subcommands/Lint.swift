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
  /// Emits style diagnostics for one or more files containing Swift code.
  struct Lint: ParsableCommand {
    static var configuration = CommandConfiguration(
      abstract: "Diagnose style issues in Swift source code",
      discussion: "When no files are specified, it expects the source from standard input."
    )

    @OptionGroup()
    var lintOptions: LintFormatOptions

    @Flag(
      name: .shortAndLong,
      help: "Fail on warnings."
    )
    var strict: Bool = false

    @OptionGroup(visibility: .hidden)
    var performanceMeasurementOptions: PerformanceMeasurementsOptions

    func run() throws {
      try performanceMeasurementOptions.printingInstructionCountIfRequested {
        let frontend = LintFrontend(lintFormatOptions: lintOptions)
        frontend.run()

        if frontend.diagnosticsEngine.hasErrors || strict && frontend.diagnosticsEngine.hasWarnings {
          throw ExitCode.failure
        }
      }
    }
  }
}
