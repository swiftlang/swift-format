//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import Foundation

extension Data {
  /// Writes the data to `url` atomically, restoring the permissions the file had before the write.
  ///
  /// An atomic write replaces the file rather than rewriting it, so the result is a new file created at the process
  /// umask and any mode the original carried is lost.
  @_spi(Internal) public func writeAtomicallyPreservingPermissions(to url: URL) throws {
    let permissions = (try? FileManager.default.attributesOfItem(atPath: url.path))?[.posixPermissions]
    try write(to: url, options: .atomic)
    if let permissions {
      try? FileManager.default.setAttributes([.posixPermissions: permissions], ofItemAtPath: url.path)
    }
  }
}
