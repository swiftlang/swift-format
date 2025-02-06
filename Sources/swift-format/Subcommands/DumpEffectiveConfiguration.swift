//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2025 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import ArgumentParser
import Foundation
import SwiftFormat

extension SwiftFormatCommand {
  /// Dumps the tool's effective configuration in JSON format to standard output.
  struct DumpEffectiveConfiguration: ParsableCommand {
    static var configuration = CommandConfiguration(
      abstract: "Dump the effective configuration in JSON format to standard output",
      discussion: """
        Dumps the configuration that would be used if swift-format was executed from the current working \
        directory (cwd), incorporating configuration files found in the cwd or its parents, or input from the \
        --configuration option.
        """
    )

    @OptionGroup()
    var configurationOptions: ConfigurationOptions

    func run() throws {
      // Pretend to use stdin, so that the configuration loading machinery in the Frontend base class can be used in the
      // next step. This produces the same results as if "format" or "lint" subcommands were called.
      let lintFormatOptions = try LintFormatOptions.parse(["-"])

      let frontend = DumpEffectiveConfigurationFrontend(
        configurationOptions: configurationOptions,
        lintFormatOptions: lintFormatOptions
      )
      frontend.run()
      if frontend.diagnosticsEngine.hasErrors {
        throw ExitCode.failure
      }

      switch frontend.dumpResult {
      case .success(let configuration):
        print(configuration)
      case .failure(let error):
        throw error
      }
    }
  }
}
