//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import struct Foundation.URL

extension String {
  /// Writes the contents of the `String` to the specified URL, using atomic writing when supported.
  public func writeAtomicallyIfPossible(to url: URL, encoding: String.Encoding = .utf8) throws {
    #if os(WASI)
    let supportsAtomicWriting = false
    #else
    let supportsAtomicWriting = true
    #endif

    try self.write(to: url, atomically: supportsAtomicWriting, encoding: encoding)
  }
}
