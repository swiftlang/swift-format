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

/// Encapsulates `--version` flag behavior.
public struct VersionOptions: ParsableArguments {
  @Flag(name: .shortAndLong, help: "Print the version and exit")
  public var version: Bool = false
  
  public init() {}

  public func validate() throws {
    if version {
      printVersionInformation()
      throw ExitCode.success
    }
  }
}
