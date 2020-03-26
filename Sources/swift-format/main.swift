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

/// Collects the command line options that were passed to `swift-format` and dispatches to the
/// appropriate subcommand.
struct SwiftFormatCommand: ParsableCommand {
  static var configuration = CommandConfiguration(
    commandName: "swift-format",
    abstract: "Format or lint Swift source code",
    subcommands: [
      DumpConfiguration.self,
      Format.self,
      LegacyMain.self,
      Lint.self,
    ],
    // TODO: Change the default to `Format` when we delete the legacy interface after a short
    // period of time.
    defaultSubcommand: LegacyMain.self
  )

  @OptionGroup()
  var versionOptions: VersionOptions
}

SwiftFormatCommand.main()
