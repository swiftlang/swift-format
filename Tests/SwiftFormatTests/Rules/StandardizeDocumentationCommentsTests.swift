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

@_spi(Rules) import SwiftFormat
import _SwiftFormatTestSupport

class StandardizeDocumentationCommentsTests: LintOrFormatRuleTestCase {
  static var configuration: Configuration {
    var c = Configuration()
    c.lineLength = 80
    return c
  }

  func testFunction() {
    assertFormatting(
      StandardizeDocumentationComments.self,
      input: """
        /// Returns a collection of subsequences, each with up to the specified length.
        ///
        /// If the number of elements in the 
        /// collection is evenly divided by `count`,
        /// then every chunk will have a length equal to `count`. Otherwise, every chunk but the last will have a length equal to `count`, with the
        /// remaining elements in the last chunk.
        ///
        ///     let numbers = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
        ///     for chunk in numbers.chunks(ofCount: 5) {
        ///         print(chunk)
        ///     }
        ///     // [1, 2, 3, 4, 5]
        ///     // [6, 7, 8, 9, 10]
        ///
        /// - Parameter count: The desired size of each chunk.
        /// - Parameter maxChunks: The total number of chunks that may not be exceeded, no matter how many would otherwise be produced.
        /// - Returns: A collection of consescutive, non-overlapping subseqeunces of
        ///   this collection, where each subsequence (except possibly the last) has
        ///   the length `count`.
        ///
        /// - Complexity: O(1) if the collection conforms to `RandomAccessCollection`;
        ///   otherwise, O(*k*), where *k* is equal to `count`.
        ///
        public func chunks(ofCount count: Int, maxChunks: Int) -> [[SubSequence]] {}
        """,
      expected: """
        /// Returns a collection of subsequences, each with up to the specified length.
        ///
        /// If the number of elements in the collection is evenly divided by `count`,
        /// then every chunk will have a length equal to `count`. Otherwise, every
        /// chunk but the last will have a length equal to `count`, with the remaining
        /// elements in the last chunk.
        ///
        /// ```
        /// let numbers = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
        /// for chunk in numbers.chunks(ofCount: 5) {
        ///     print(chunk)
        /// }
        /// // [1, 2, 3, 4, 5]
        /// // [6, 7, 8, 9, 10]
        /// ```
        ///
        /// - Complexity: O(1) if the collection conforms to `RandomAccessCollection`;
        ///   otherwise, O(*k*), where *k* is equal to `count`.
        ///
        /// - Parameters:
        ///   - count: The desired size of each chunk.
        ///   - maxChunks: The total number of chunks that may not be exceeded, no
        ///     matter how many would otherwise be produced.
        /// - Returns: A collection of consescutive, non-overlapping subseqeunces of
        ///   this collection, where each subsequence (except possibly the last) has
        ///   the length `count`.
        public func chunks(ofCount count: Int, maxChunks: Int) -> [[SubSequence]] {}
        """,
      findings: [],
      configuration: Self.configuration
    )
  }

  func testNestedFunction() {
    assertFormatting(
      StandardizeDocumentationComments.self,
      input: """
        // This comment helps verify that leading non-documentation trivia is preserved without changes.

        /// Provides a `chunks(ofCount:)` method, with some more information that should wrap.
        extension Sequence {
            /// Returns a collection of subsequences, each with up to the specified length.
            ///
            ///
            /// - Parameter count: The desired size of each chunk.
            /// - Returns: A collection of consescutive, non-overlapping subseqeunces of
            ///   this collection.
            ///
            public func chunks(ofCount count: Int) -> [[SubSequence]] {}
        }
        """,
      expected: """
        // This comment helps verify that leading non-documentation trivia is preserved without changes.

        /// Provides a `chunks(ofCount:)` method, with some more information that
        /// should wrap.
        extension Sequence {
            /// Returns a collection of subsequences, each with up to the specified
            /// length.
            ///
            /// - Parameter count: The desired size of each chunk.
            /// - Returns: A collection of consescutive, non-overlapping subseqeunces
            ///   of this collection.
            public func chunks(ofCount count: Int) -> [[SubSequence]] {}
        }
        """,
      findings: [],
      configuration: Self.configuration
    )
  }

  func testBlockDocumentation() {
    assertFormatting(
      StandardizeDocumentationComments.self,
      input: """
        /** Provides an initializer that isn't actually possible to implement for all sequences. */
        extension Sequence {
            /** 
            Creates a new sequence with the given element repeated the specified number of times.
            - Parameter element: The element to repeat.
            - Parameter count: The number of times to repeat `element`. `count` must be greater than or equal to zero.
            - Complexity: O(1)
            */
            public init(repeating element: Element, count: Int) {}
        }
        """,
      expected: """
        /// Provides an initializer that isn't actually possible to implement for all
        /// sequences.
        extension Sequence {
            /// Creates a new sequence with the given element repeated the specified
            /// number of times.
            ///
            /// - Complexity: O(1)
            ///
            /// - Parameters:
            ///   - element: The element to repeat.
            ///   - count: The number of times to repeat `element`. `count` must be
            ///     greater than or equal to zero.
            public init(repeating element: Element, count: Int) {}
        }
        """,
      findings: [],
      configuration: Self.configuration
    )
  }

}
