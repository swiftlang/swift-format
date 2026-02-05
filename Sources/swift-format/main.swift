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

import _SwiftFormatCLI

import Foundation

var arguments = Array(CommandLine.arguments.dropFirst())

// If the executable name is `swift-lint`, default to the `lint` subcommand.
if CommandLine.arguments[0].hasSuffix("swift-lint") {
  arguments.insert("lint", at: 0)
}

SwiftFormatCommand.main(arguments)
