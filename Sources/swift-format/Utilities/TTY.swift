//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2023 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import Foundation

#if os(Android)
import Android
#endif

/// Returns a value indicating whether or not the stream is a TTY.
func isTTY(_ fileHandle: FileHandle) -> Bool {
  // The implementation of this function is adapted from `TerminalController.swift` in
  // swift-tools-support-core.
  #if os(Windows)
  // The TSC implementation of this function only returns `.file` or `.dumb` for Windows,
  // neither of which is a TTY.
  return false
  #else
  if ProcessInfo.processInfo.environment["TERM"] == "dumb" {
    return false
  }
  return isatty(fileHandle.fileDescriptor) != 0
  #endif
}
