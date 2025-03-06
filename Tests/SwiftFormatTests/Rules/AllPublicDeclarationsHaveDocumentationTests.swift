//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2025 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

@_spi(Rules) import SwiftFormat
import _SwiftFormatTestSupport

final class AllPublicDeclarationsHaveDocumentationTests: LintOrFormatRuleTestCase {
  func testPublicDeclsWithoutDocs() {
    assertLint(
      AllPublicDeclarationsHaveDocumentation.self,
      """
      1️⃣public func lightswitchRave() {}
      /// Comment.
      public func lightswitchRave() {}
      func lightswitchRave() {}

      2️⃣public var isSblounskched: Int { return 0 }
      /// Comment.
      public var isSblounskched: Int { return 0 }
      var isSblounskched: Int { return 0 }

      3️⃣public struct Foo {}
      /// Comment.
      public struct Foo {}
      struct Foo {}

      4️⃣public actor Bar {}
      /// Comment.
      public actor Bar {}
      actor Bar {}

      5️⃣public class Baz {}
      /// Comment.
      public class Baz {}
      class Baz {}

      6️⃣public enum Qux {}
      /// Comment.
      public enum Qux {}
      enum Qux {}

      7️⃣public typealias MyType = Int
      /// Comment.
      public typealias MyType = Int
      typealias MyType = Int

      /**
       * Determines if an email was delorted.
       */
      public var isDelorted: Bool {
        return false
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: "add a documentation comment for 'lightswitchRave()'"),
        FindingSpec("2️⃣", message: "add a documentation comment for 'isSblounskched'"),
        FindingSpec("3️⃣", message: "add a documentation comment for 'Foo'"),
        FindingSpec("4️⃣", message: "add a documentation comment for 'Bar'"),
        FindingSpec("5️⃣", message: "add a documentation comment for 'Baz'"),
        FindingSpec("6️⃣", message: "add a documentation comment for 'Qux'"),
        FindingSpec("7️⃣", message: "add a documentation comment for 'MyType'"),
      ]
    )
  }

  func testNestedDecls() {
    assertLint(
      AllPublicDeclarationsHaveDocumentation.self,
      """
      /// Comment.
      public struct MyContainer {
      1️⃣public func lightswitchRave() {}
      /// Comment.
      public func lightswitchRave() {}
      func lightswitchRave() {}

      2️⃣public var isSblounskched: Int { return 0 }
      /// Comment.
      public var isSblounskched: Int { return 0 }
      var isSblounskched: Int { return 0 }

      3️⃣public struct Foo {}
      /// Comment.
      public struct Foo {}
      struct Foo {}

      4️⃣public actor Bar {}
      /// Comment.
      public actor Bar {}
      actor Bar {}

      5️⃣public class Baz {}
      /// Comment.
      public class Baz {}
      class Baz {}

      6️⃣public enum Qux {}
      /// Comment.
      public enum Qux {}
      enum Qux {}

      7️⃣public typealias MyType = Int
      /// Comment.
      public typealias MyType = Int
      typealias MyType = Int

      }
      """,
      findings: [
        FindingSpec("1️⃣", message: "add a documentation comment for 'lightswitchRave()'"),
        FindingSpec("2️⃣", message: "add a documentation comment for 'isSblounskched'"),
        FindingSpec("3️⃣", message: "add a documentation comment for 'Foo'"),
        FindingSpec("4️⃣", message: "add a documentation comment for 'Bar'"),
        FindingSpec("5️⃣", message: "add a documentation comment for 'Baz'"),
        FindingSpec("6️⃣", message: "add a documentation comment for 'Qux'"),
        FindingSpec("7️⃣", message: "add a documentation comment for 'MyType'"),
      ]
    )
  }

  func testNestedInStruct() {
    assertLint(
      AllPublicDeclarationsHaveDocumentation.self,
      """
      /// Comment.
      public struct MyContainer {
        1️⃣public typealias MyType = Int
        /// Comment.
        public typealias MyType = Int
        typealias MyType = Int
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: "add a documentation comment for 'MyType'")
      ]
    )
  }

  func testNestedInClass() {
    assertLint(
      AllPublicDeclarationsHaveDocumentation.self,
      """
      /// Comment.
      public class MyContainer {
        1️⃣public typealias MyType = Int
        /// Comment.
        public typealias MyType = Int
        typealias MyType = Int
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: "add a documentation comment for 'MyType'")
      ]
    )
  }

  func testNestedInEnum() {
    assertLint(
      AllPublicDeclarationsHaveDocumentation.self,
      """
      /// Comment.
      public enum MyContainer {
        1️⃣public typealias MyType = Int
        /// Comment.
        public typealias MyType = Int
        typealias MyType = Int
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: "add a documentation comment for 'MyType'")
      ]
    )
  }

  func testNestedInActor() {
    assertLint(
      AllPublicDeclarationsHaveDocumentation.self,
      """
      /// Comment.
      public actor MyContainer {
        1️⃣public typealias MyType = Int
        /// Comment.
        public typealias MyType = Int
        typealias MyType = Int
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: "add a documentation comment for 'MyType'")
      ]
    )
  }
}
