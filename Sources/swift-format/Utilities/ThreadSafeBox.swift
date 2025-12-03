//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2025 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import class Foundation.NSLock

/// A thread safe container that contains a mutable value of type `T`.
///
/// - Note: Unchecked sendable conformance because value is guarded by a lock.
// TODO: This can be replaced with Synchronization.Mutex once deployment target >= macOS 15.0
class ThreadSafeBox<Value: Sendable>: @unchecked Sendable {
  /// Lock guarding `_value`.
  private let lock = NSLock()

  private var _value: Value

  init(_ value: Value) {
    _value = value
  }

  var value: Value {
    _read {
      lock.lock()
      defer { lock.unlock() }
      yield _value
    }
    _modify {
      lock.lock()
      defer { lock.unlock() }
      yield &_value
    }
  }

  func withLock<Result>(_ body: (inout Value) throws -> Result) rethrows -> Result {
    try self.lock.withLock {
      try body(&self.value)
    }
  }
}
