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

import Foundation

/// Common behavior used to generate source files.
protocol FileGenerator {
  /// Types conforming to this protocol must implement this method to write their content into the
  /// given file handle.
  func write(into handle: FileHandle) throws
}

private struct FailedToCreateFileError: Error {
  let url: URL
}

extension FileGenerator {
  /// Generates a file at the given URL, overwriting it if it already exists.
  func generateFile(at url: URL) throws {
    let fm = FileManager.default
    if fm.fileExists(atPath: url.path) {
      try fm.removeItem(at: url)
    }

    if !fm.createFile(atPath: url.path, contents: nil, attributes: nil) {
      throw FailedToCreateFileError(url: url)
    }
    let handle = try FileHandle(forWritingTo: url)
    defer { handle.closeFile() }

    try write(into: handle)
  }
}

extension FileHandle {
  /// Writes the provided string as data to a file output stream.
  public func write(_ string: String) {
    guard let data = string.data(using: .utf8) else { return }
    write(data)
  }
}
