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
  /// Delete format and lint cache
  struct DeleteCache: ParsableCommand {
    static var configuration = CommandConfiguration(
      abstract: "Delete format and lint cache"
    )

    func run() throws {
      let fileManager = FileManager.default
      let cacheDirURL = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
          .appendingPathComponent("swift-format", isDirectory: true)
      let cacheFileURL = cacheDirURL.appendingPathComponent("cache.json")
      try fileManager.removeItem(at: cacheFileURL)
    }
  }
}
