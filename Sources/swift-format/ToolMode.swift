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

import TSCUtility

/// The mode in which the `swift-format` tool should run.
enum ToolMode: String, Codable, ArgumentKind {
  case format
  case lint
  case dumpConfiguration = "dump-configuration"
  case version

  static var completion: ShellCompletion {
    return .values(
      [
        ("format", "Format the provided files."),
        ("lint", "Lint the provided files."),
        ("dump-configuration", "Dump the default configuration as JSON to standard output."),
      ])
  }

  /// Creates a `ToolMode` value from the given command line argument string, throwing an error if
  /// the string is not valid.
  init(argument: String) throws {
    guard let mode = ToolMode(rawValue: argument) else {
      throw ArgumentParserError.invalidValue(argument: argument, error: .unknown(value: argument))
    }
    self = mode
  }
}
