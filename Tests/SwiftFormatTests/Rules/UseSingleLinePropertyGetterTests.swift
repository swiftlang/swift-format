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

final class UseSingleLinePropertyGetterTests: LintOrFormatRuleTestCase {
  func testMultiLinePropertyGetter() {
    assertFormatting(
      UseSingleLinePropertyGetter.self,
      input: """
        var g: Int { return 4 }
        var h: Int {
          1️⃣get {
              return 4
          }
        }
        var i: Int {
          get { return 0 }
          set { print("no set, only get") }
        }
        var j: Int {
          mutating get { return 0 }
        }
        var k: Int {
          get async {
            return 4
          }
        }
        var l: Int {
          get throws {
            return 4
          }
        }
        var m: Int {
          get async throws {
            return 4
          }
        }
        """,
      expected: """
        var g: Int { return 4 }
        var h: Int {
              return 4
        }
        var i: Int {
          get { return 0 }
          set { print("no set, only get") }
        }
        var j: Int {
          mutating get { return 0 }
        }
        var k: Int {
          get async {
            return 4
          }
        }
        var l: Int {
          get throws {
            return 4
          }
        }
        var m: Int {
          get async throws {
            return 4
          }
        }
        """,
      findings: [
        FindingSpec(
          "1️⃣",
          message: "remove 'get {...}' around the accessor and move its body directly into the computed property"
        )
      ]
    )
  }

  func testSingleLineGetterWithInlineComments() {
    assertFormatting(
      UseSingleLinePropertyGetter.self,
      input: """
        var x: Int {
          // A comment
          1️⃣get { 1 }
        }
        var y: Int {
          2️⃣get { 1 } // A comment
        }
        var z: Int {
          3️⃣get { 1 }
          // A comment
        }
        """,
      expected: """
        var x: Int {
          // A comment
           1 
        }
        var y: Int {
           1  // A comment
        }
        var z: Int {
           1 
          // A comment
        }
        """,
      findings: [
        FindingSpec(
          "1️⃣",
          message: "remove 'get {...}' around the accessor and move its body directly into the computed property"
        ),
        FindingSpec(
          "2️⃣",
          message: "remove 'get {...}' around the accessor and move its body directly into the computed property"
        ),
        FindingSpec(
          "3️⃣",
          message: "remove 'get {...}' around the accessor and move its body directly into the computed property"
        ),
      ]
    )
  }

  func testMultiLineGetterWithCommentsInsideBody() {
    assertFormatting(
      UseSingleLinePropertyGetter.self,
      input: """
        var x: Int {
          1️⃣get {
            // A comment
            1
          }
        }
        var x: Int {
          2️⃣get {
            1 // A comment
          }
        }
        var x: Int {
          3️⃣get {
            1
            // A comment
          }
        }
        """,
      expected: """
        var x: Int {
            // A comment
            1
        }
        var x: Int {
            1 // A comment
        }
        var x: Int {
            1
            // A comment
        }
        """,
      findings: [
        FindingSpec(
          "1️⃣",
          message: "remove 'get {...}' around the accessor and move its body directly into the computed property"
        ),
        FindingSpec(
          "2️⃣",
          message: "remove 'get {...}' around the accessor and move its body directly into the computed property"
        ),
        FindingSpec(
          "3️⃣",
          message: "remove 'get {...}' around the accessor and move its body directly into the computed property"
        ),
      ]
    )
  }

  func testGetterWithCommentsAfterGetKeyword() {
    assertFormatting(
      UseSingleLinePropertyGetter.self,
      input: """
        var x: Int {
          1️⃣get // hello
          { 1 }
        }

        var x: Int {
          2️⃣get /* hello */ { 1 }
        }
        """,
      expected: """
        var x: Int {
           // hello
         1 
        }

        var x: Int {
           /* hello */ 
         1 
        }
        """,
      findings: [
        FindingSpec(
          "1️⃣",
          message: "remove 'get {...}' around the accessor and move its body directly into the computed property"
        ),
        FindingSpec(
          "2️⃣",
          message: "remove 'get {...}' around the accessor and move its body directly into the computed property"
        ),
      ]
    )
  }

  func testGetterWithCommentsAroundBracesAndBody() {
    assertFormatting(
      UseSingleLinePropertyGetter.self,
      input: """
        var x: Int { // A comment
          // B comment
          1️⃣get /* C comment */ { // D comment
            // E comment
            1 // F comment
            // G comment
          } // H comment
          // I comment
        }
        """,
      expected: """
        var x: Int { // A comment
          // B comment
           /* C comment */ 
         // D comment
            // E comment
            1 // F comment
            // G comment
           // H comment
          // I comment
        }
        """,
      findings: [
        FindingSpec(
          "1️⃣",
          message: "remove 'get {...}' around the accessor and move its body directly into the computed property"
        )
      ]
    )
  }

  func testGetterWithAttributedAccessorShouldBePreserved() {
    assertFormatting(
      UseSingleLinePropertyGetter.self,
      input: """
        struct Foo {
          var value: Int {
            @_lifetime(borrow self)
            get {
              return 1
            }
          }
        }
        """,
      expected: """
        struct Foo {
          var value: Int {
            @_lifetime(borrow self)
            get {
              return 1
            }
          }
        }
        """
    )
  }
}
