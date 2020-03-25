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

/// A sequence that lazily computes the longest possible subsequences of a collection, in order,
/// around elements equal to a specific element.
struct LazySplitSequence<Base: Collection>: Sequence where Base.Element: Equatable {
  /// The base collection.
  private let base: Base

  /// The element around which to split.
  private let separator: Base.Element

  /// The number of subsequences, which is precomputed when the sequence is initialized.
  let count: Int

  var underestimatedCount: Int {
    return count
  }

  /// Creates a new sequence that lazily computes the longest possible subsequences of a collection,
  /// in order, around elements equal to the given element.
  fileprivate init(base: Base, separator: Base.Element) {
    self.base = base
    self.separator = separator

    // Precompute the number of subsequences.
    var count = 1
    for element in base where element == separator {
      count += 1
    }
    self.count = count
  }

  func makeIterator() -> Iterator {
    return Iterator(base: base, separator: separator)
  }

  struct Iterator: IteratorProtocol {
    private let base: Base
    private let separator: Base.Element

    /// The start index of the current subsequence being computed.
    private var subSequenceStart: Base.Index

    /// The end index of the current subsequence being computed.
    private var subSequenceEnd: Base.Index

    /// The end index of the base collection.
    private let endIndex: Base.Index

    /// Indicates whether the last subsequence has been computed.
    private var done: Bool

    init(base: Base, separator: Base.Element) {
      self.base = base
      self.separator = separator

      self.subSequenceStart = base.startIndex
      self.subSequenceEnd = self.subSequenceStart
      self.endIndex = base.endIndex
      self.done = false
    }

    mutating func next() -> Base.SubSequence? {
      while subSequenceEnd != endIndex {
        if base[subSequenceEnd] == separator {
          let next = base[subSequenceStart..<subSequenceEnd]
          base.formIndex(after: &subSequenceEnd)
          subSequenceStart = subSequenceEnd
          return next
        }
        base.formIndex(after: &subSequenceEnd)
      }

      if !done {
        done = true
        return base[subSequenceStart..<endIndex]
      }

      return nil
    }
  }
}

extension Collection where Element: Equatable {
  /// Returns a `Sequence` that lazily computes the longest possible subsequences of the collection,
  /// in order, around elements equal to the given element.
  ///
  /// - Parameter separator: The element that should be split upon.
  /// - Returns: A sequence of subsequences, split from this collection’s elements.
  func lazilySplit(separator: Element) -> LazySplitSequence<Self> {
    return LazySplitSequence(base: self, separator: separator)
  }
}
