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

/// Common arguments used by the `lint`, `format` and `dump-configuration` subcommands.
struct ConfigurationOptions: ParsableArguments {
  /// The path to the JSON configuration file that should be loaded.
  ///
  /// If not specified, the default configuration will be used.
  @Option(
    name: .customLong("configuration"),
    help: """
      The path to a JSON file containing the configuration of the linter/formatter or a JSON string containing the \
      configuration directly.
      """
  )
  var configuration: String?
}
