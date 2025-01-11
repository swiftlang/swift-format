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
import Foundation

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

    func validate() throws {
      #if !os(Windows)
      let stdinIsPiped: Bool = {
        let standardInput = FileHandle.standardInput
        return isatty(standardInput.fileDescriptor) == 0
      }()
      if !stdinIsPiped, lintOptions.paths.isEmpty {
        throw ValidationError(
          """
          No input files specified. Use one of the following:
            - Provide the path to a directory along with the '--recursive' option to lint all Swift files within it.
            - Provide the path to a specific Swift source code file.
            - Or, pipe Swift code into the command (e.g., echo "let a = 1" | swift-format lint).
          """
        )
      }
      #endif
    }

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
