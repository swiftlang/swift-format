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

/// An iterator that persistently remembers the most recent element returned by `next()`.
struct RememberingIterator<Base: IteratorProtocol>: IteratorProtocol {
  /// The wrapped iterator.
  private var base: Base

  /// The element most recently returned by the `next()` method.
  ///
  /// This value will always remain equal to the last non-nil element returned by `next()`, even if
  /// multiple calls to `next()` are made that return nil after the iterator has been exhausted.
  /// Therefore, this property only evaluates to `nil` if the iterator had no elements in the first
  /// place.
  private(set) var latestElement: Base.Element?

  /// Creates a new remembering iterator that wraps the specified iterator.
  init(_ base: Base) {
    self.base = base
    self.latestElement = nil
  }

  mutating func next() -> Base.Element? {
    let element = base.next()
    if element != nil {
      latestElement = element
    }
    return element
  }
}
