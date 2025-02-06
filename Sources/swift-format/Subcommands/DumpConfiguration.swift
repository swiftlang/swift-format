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
import Foundation
import SwiftFormat

extension SwiftFormatCommand {
  /// Dumps the tool's configuration in JSON format to standard output.
  struct DumpConfiguration: ParsableCommand {
    static var configuration = CommandConfiguration(
      abstract: "Dump the configuration in JSON format to standard output",
      discussion: """
        Without any options, dumps the default configuration. When '--effective' is set, dumps the configuration that \
        would be used if swift-format was executed from the current working directory (cwd), incorporating \
        configuration files found in the cwd or its parents, or input from the '--configuration' option.
        """
    )

    /// Whether or not to dump the effective configuration.
    @Flag(name: .shortAndLong, help: "Dump the effective instead of the default configuration.")
    var effective: Bool = false

    @OptionGroup()
    var configurationOptions: ConfigurationOptions

    func validate() throws {
      if configurationOptions.configuration != nil && !effective {
        throw ValidationError("'--configuration' is only valid in combination with '--effective'")
      }
    }

    func run() throws {
      if !effective {
        let configuration = try Configuration().asJsonString()
        print(configuration)
        return
      }

      // Pretend to use stdin, so that the configuration loading machinery in the Frontend base class can be used in the
      // next step. This produces the same results as if "format" or "lint" subcommands were called.
      let lintFormatOptions = try LintFormatOptions.parse(["-"])

      let frontend = DumpConfigurationFrontend(
        configurationOptions: configurationOptions,
        lintFormatOptions: lintFormatOptions
      )
      frontend.run()
      if frontend.diagnosticsEngine.hasErrors {
        throw ExitCode.failure
      }

      switch frontend.dumpedConfiguration {
      case .success(let configuration):
        print(configuration)
      case .failure(let error):
        throw error
      }
    }
  }
}
