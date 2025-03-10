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

  func testDetailedParameters() {
    assertFormatting(
      StandardizeDocumentationComments.self,
      input: """
        /// Creates an array with the specified capacity, then calls the given
        /// closure with a buffer covering the array's uninitialized memory.
        ///
        /// Inside the closure, set the `initializedCount` parameter to the number of
        /// elements that are initialized by the closure. The memory in the range
        /// 'buffer[0..<initializedCount]' must be initialized at the end of the
        /// closure's execution, and the memory in the range
        /// 'buffer[initializedCount...]' must be uninitialized. This postcondition
        /// must hold even if the `initializer` closure throws an error.
        ///
        /// - Note: While the resulting array may have a capacity larger than the
        ///   requested amount, the buffer passed to the closure will cover exactly
        ///   the requested number of elements.
        ///
        /// - Parameters:
        ///   - unsafeUninitializedCapacity: The number of elements to allocate
        ///     space for in the new array.
        ///   - initializer: A closure that initializes elements and sets the count
        ///     of the new array.
        ///     - Parameters:
        ///       - buffer: A buffer covering uninitialized memory with room for the
        ///         specified number of elements.
        ///       - initializedCount: The count of initialized elements in the array,
        ///         which begins as zero. Set `initializedCount` to the number of
        ///         elements you initialize.
        @_alwaysEmitIntoClient @inlinable
        public init(
          unsafeUninitializedCapacity: Int,
          initializingWith initializer: (
            _ buffer: inout UnsafeMutableBufferPointer<Element>,
            _ initializedCount: inout Int) throws -> Void
        ) rethrows {}
        """,
      expected: """
        /// Creates an array with the specified capacity, then calls the given closure
        /// with a buffer covering the array's uninitialized memory.
        ///
        /// Inside the closure, set the `initializedCount` parameter to the number of
        /// elements that are initialized by the closure. The memory in the range
        /// 'buffer[0..<initializedCount]' must be initialized at the end of the
        /// closure's execution, and the memory in the range
        /// 'buffer[initializedCount...]' must be uninitialized. This postcondition
        /// must hold even if the `initializer` closure throws an error.
        ///
        /// - Note: While the resulting array may have a capacity larger than the
        ///   requested amount, the buffer passed to the closure will cover exactly the
        ///   requested number of elements.
        ///
        /// - Parameters:
        ///   - unsafeUninitializedCapacity: The number of elements to allocate space
        ///     for in the new array.
        ///   - initializer: A closure that initializes elements and sets the count of
        ///     the new array.
        ///     - Parameters:
        ///       - buffer: A buffer covering uninitialized memory with room for the
        ///         specified number of elements.
        ///       - initializedCount: The count of initialized elements in the array,
        ///         which begins as zero. Set `initializedCount` to the number of
        ///         elements you initialize.
        @_alwaysEmitIntoClient @inlinable
        public init(
          unsafeUninitializedCapacity: Int,
          initializingWith initializer: (
            _ buffer: inout UnsafeMutableBufferPointer<Element>,
            _ initializedCount: inout Int) throws -> Void
        ) rethrows {}
        """,
      findings: [],
      configuration: Self.configuration
    )
  }

  // MARK: Nominal decl tests

  func testActorDecl() {
    assertFormatting(
      StandardizeDocumentationComments.self,
      input: """
        /// An actor declaration
        /// with documentation
        /// that needs to be
        /// rewrapped to 
        /// the correct width.
        package actor MyActor {}
        """,
      expected: """
        /// An actor declaration with documentation that needs to be rewrapped to the
        /// correct width.
        package actor MyActor {}
        """,
      findings: [],
      configuration: Self.configuration
    )
  }

  func testAssociatedTypeDecl() {
    assertFormatting(
      StandardizeDocumentationComments.self,
      input: """
        /// An associated type declaration
        /// with documentation
        /// that needs to be
        /// rewrapped to 
        /// the correct width.
        associatedtype MyAssociatedType = Int
        """,
      expected: """
        /// An associated type declaration with documentation that needs to be
        /// rewrapped to the correct width.
        associatedtype MyAssociatedType = Int
        """,
      findings: [],
      configuration: Self.configuration
    )
  }

  func testClassDecl() {
    assertFormatting(
      StandardizeDocumentationComments.self,
      input: """
        /// A class declaration
        /// with documentation
        /// that needs to be
        /// rewrapped to 
        /// the correct width.
        public class MyClass {}
        """,
      expected: """
        /// A class declaration with documentation that needs to be rewrapped to the
        /// correct width.
        public class MyClass {}
        """,
      findings: [],
      configuration: Self.configuration
    )
  }

  func testEnumAndEnumCaseDecl() {
    assertFormatting(
      StandardizeDocumentationComments.self,
      input: """
        /// An enum declaration
        /// with documentation
        /// that needs to be
        /// rewrapped to 
        /// the correct width.
        public enum MyEnum {
          /// An enum case declaration
          /// with documentation
          /// that needs to be
          /// rewrapped to 
          /// the correct width.
          case myCase
        }
        """,
      expected: """
        /// An enum declaration with documentation that needs to be rewrapped to the
        /// correct width.
        public enum MyEnum {
          /// An enum case declaration with documentation that needs to be rewrapped to
          /// the correct width.
          case myCase
        }
        """,
      findings: [],
      configuration: Self.configuration
    )
  }

  func testExtensionDecl() {
    assertFormatting(
      StandardizeDocumentationComments.self,
      input: """
        /// An extension
        /// with documentation
        /// that needs to be
        /// rewrapped to 
        /// the correct width.
        extension MyClass {}
        """,
      expected: """
        /// An extension with documentation that needs to be rewrapped to the correct
        /// width.
        extension MyClass {}
        """,
      findings: [],
      configuration: Self.configuration
    )
  }

  func testFunctionDecl() {
    assertFormatting(
      StandardizeDocumentationComments.self,
      input: """
        /// A function declaration
        /// with documentation
        /// that needs to be
        /// rewrapped to 
        /// the correct width.
        ///
        /// - Returns: A value.
        /// - Throws: An error.
        ///
        /// - Parameters:
        ///   - param: A single parameter.
        /// - Parameter another: A second single parameter.
        func myFunction(param: String, and another: Int) -> Value {}
        """,
      expected: """
        /// A function declaration with documentation that needs to be rewrapped to the
        /// correct width.
        ///
        /// - Parameters:
        ///   - param: A single parameter.
        ///   - another: A second single parameter.
        /// - Returns: A value.
        /// - Throws: An error.
        func myFunction(param: String, and another: Int) -> Value {}
        """,
      findings: [],
      configuration: Self.configuration
    )
  }

  func testInitializerDecl() {
    assertFormatting(
      StandardizeDocumentationComments.self,
      input: """
        /// An initializer declaration
        /// with documentation
        /// that needs to be
        /// rewrapped to 
        /// the correct width.
        ///
        /// - Throws: An error.
        ///
        /// - Parameters:
        ///   - param: A single parameter.
        /// - Parameter another: A second single parameter.
        public init(param: String, and another: Int) {}
        """,
      expected: """
        /// An initializer declaration with documentation that needs to be rewrapped to
        /// the correct width.
        ///
        /// - Parameters:
        ///   - param: A single parameter.
        ///   - another: A second single parameter.
        /// - Throws: An error.
        public init(param: String, and another: Int) {}
        """,
      findings: [],
      configuration: Self.configuration
    )
  }

  func testMacroDecl() {
    assertFormatting(
      StandardizeDocumentationComments.self,
      input: """
        /// A macro declaration
        /// with documentation
        /// that needs to be
        /// rewrapped to 
        /// the correct width.
        ///
        /// - Throws: An error.
        ///
        /// - Parameters:
        ///   - param: A single parameter.
        /// - Parameter another: A second single parameter.
        @freestanding(expression)
        public macro prohibitBinaryOperators<T>(_ param: T, another: [String]) -> T =
            #externalMacro(module: "ExampleMacros", type: "ProhibitBinaryOperators")
        """,
      expected: """
        /// A macro declaration with documentation that needs to be rewrapped to the
        /// correct width.
        ///
        /// - Parameters:
        ///   - param: A single parameter.
        ///   - another: A second single parameter.
        /// - Throws: An error.
        @freestanding(expression)
        public macro prohibitBinaryOperators<T>(_ param: T, another: [String]) -> T =
            #externalMacro(module: "ExampleMacros", type: "ProhibitBinaryOperators")
        """,
      findings: [],
      configuration: Self.configuration
    )
  }

  func testOperatorDecl() {
    assertFormatting(
      StandardizeDocumentationComments.self,
      input: """
        extension Int {
          /// An operator declaration
          /// with documentation
          /// that needs to be
          /// rewrapped to 
          /// the correct width.
          ///
          /// - Parameters:
          ///   - lhs: A single parameter.
          /// - Parameter rhs: A second single parameter.
          static func -+-(lhs: Int, rhs: Int) -> Int {}
        }
        """,
      expected: """
        extension Int {
          /// An operator declaration with documentation that needs to be rewrapped to
          /// the correct width.
          ///
          /// - Parameters:
          ///   - lhs: A single parameter.
          ///   - rhs: A second single parameter.
          static func -+-(lhs: Int, rhs: Int) -> Int {}
        }
        """,
      findings: [],
      configuration: Self.configuration
    )
  }

  func testProtocolDecl() {
    assertFormatting(
      StandardizeDocumentationComments.self,
      input: """
        /// A protocol declaration
        /// with documentation
        /// that needs to be
        /// rewrapped to 
        /// the correct width.
        protocol MyProto {}
        """,
      expected: """
        /// A protocol declaration with documentation that needs to be rewrapped to the
        /// correct width.
        protocol MyProto {}
        """,
      findings: [],
      configuration: Self.configuration
    )
  }

  func testStructDecl() {
    assertFormatting(
      StandardizeDocumentationComments.self,
      input: """
        /// A struct declaration
        /// with documentation
        /// that needs to be
        /// rewrapped to 
        /// the correct width.
        struct MyStruct {}
        """,
      expected: """
        /// A struct declaration with documentation that needs to be rewrapped to the
        /// correct width.
        struct MyStruct {}
        """,
      findings: [],
      configuration: Self.configuration
    )
  }

  func testSubscriptDecl() {
    assertFormatting(
      StandardizeDocumentationComments.self,
      input: """
        /// A subscript declaration
        /// with documentation
        /// that needs to be
        /// rewrapped to 
        /// the correct width.
        ///
        /// - Returns: A value.
        /// - Throws: An error.
        ///
        /// - Parameters:
        ///   - param: A single parameter.
        /// - Parameter another: A second single parameter.
        public subscript(param: String, and another: Int) -> Value {}
        """,
      expected: """
        /// A subscript declaration with documentation that needs to be rewrapped to
        /// the correct width.
        ///
        /// - Parameters:
        ///   - param: A single parameter.
        ///   - another: A second single parameter.
        /// - Returns: A value.
        /// - Throws: An error.
        public subscript(param: String, and another: Int) -> Value {}
        """,
      findings: [],
      configuration: Self.configuration
    )
  }

  func testTypeAliasDecl() {
    assertFormatting(
      StandardizeDocumentationComments.self,
      input: """
        /// A type alias declaration
        /// with documentation
        /// that needs to be
        /// rewrapped to 
        /// the correct width.
        typealias MyAlias {}
        """,
      expected: """
        /// A type alias declaration with documentation that needs to be rewrapped to
        /// the correct width.
        typealias MyAlias {}
        """,
      findings: [],
      configuration: Self.configuration
    )
  }

  func testVariableDecl() {
    assertFormatting(
      StandardizeDocumentationComments.self,
      input: """
        /// A variable declaration
        /// with documentation
        /// that needs to be
        /// rewrapped to 
        /// the correct width.
        var myVariable: Int = 5
        """,
      expected: """
        /// A variable declaration with documentation that needs to be rewrapped to the
        /// correct width.
        var myVariable: Int = 5
        """,
      findings: [],
      configuration: Self.configuration
    )
  }
}
