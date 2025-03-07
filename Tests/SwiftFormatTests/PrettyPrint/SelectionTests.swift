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

import SwiftFormat
import XCTest

final class SelectionTests: PrettyPrintTestCase {
  func testSelectAll() {
    let input =
      """
      ⏩func foo() {
      if let SomeReallyLongVar = Some.More.Stuff(), let a = myfunc() {
        // do stuff
      }
      }⏪
      """

    let expected =
      """
      func foo() {
        if let SomeReallyLongVar = Some.More.Stuff(), let a = myfunc() {
          // do stuff
        }
      }
      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 80)
  }

  func testSelectComment() {
    let input =
      """
      func foo() {
      if let SomeReallyLongVar = Some.More.Stuff(), let a = myfunc() {
      ⏩// do stuff⏪
      }
      }
      """

    let expected =
      """
      func foo() {
      if let SomeReallyLongVar = Some.More.Stuff(), let a = myfunc() {
          // do stuff
      }
      }
      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 80)
  }

  func testInsertionPointBeforeComment() {
    let input =
      """
      func foo() {
      if let SomeReallyLongVar = Some.More.Stuff(), let a = myfunc() {
      ⏩⏪// do stuff
      }
      }
      """

    let expected =
      """
      func foo() {
      if let SomeReallyLongVar = Some.More.Stuff(), let a = myfunc() {
          // do stuff
      }
      }
      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 80)
  }

  func testSpacesInline() {
    let input =
      """
      func foo() {
      if let SomeReallyLongVar ⏩ =   ⏪Some.More.Stuff(), let a = myfunc() {
      // do stuff
      }
      }
      """

    let expected =
      """
      func foo() {
      if let SomeReallyLongVar = Some.More.Stuff(), let a = myfunc() {
      // do stuff
      }
      }
      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 80)
  }

  func testSpacesFullLine() {
    let input =
      """
      func foo() {
      ⏩if let SomeReallyLongVar  =   Some.More.Stuff(), let a = myfunc() {⏪
      // do stuff
      }
      }
      """

    let expected =
      """
      func foo() {
        if let SomeReallyLongVar = Some.More.Stuff(), let a = myfunc() {
      // do stuff
      }
      }
      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 80)
  }

  func testWrapInline() {
    let input =
      """
      func foo() {
      if let SomeReallyLongVar = ⏩Some.More.Stuff(), let a = myfunc()⏪ {
      // do stuff
      }
      }
      """

    let expected =
      """
      func foo() {
      if let SomeReallyLongVar = Some.More
          .Stuff(), let a = myfunc() {
      // do stuff
      }
      }
      """

    // The line length ends on the last paren of .Stuff()
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 44)
  }

  func testCommentsOnly() {
    let input =
      """
      func foo() {
      if let SomeReallyLongVar = Some.More.Stuff(), let a = myfunc() {
      ⏩// do stuff
      // do more stuff⏪
      var i = 0
      }
      }
      """

    let expected =
      """
      func foo() {
      if let SomeReallyLongVar = Some.More.Stuff(), let a = myfunc() {
          // do stuff
          // do more stuff
      var i = 0
      }
      }
      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 80)
  }

  func testVarOnly() {
    let input =
      """
      func foo() {
      if let SomeReallyLongVar = Some.More.Stuff(), let a = myfunc() {
      // do stuff
      // do more stuff
      ⏩⏪var i = 0
      }
      }
      """

    let expected =
      """
      func foo() {
      if let SomeReallyLongVar = Some.More.Stuff(), let a = myfunc() {
      // do stuff
      // do more stuff
          var i = 0
      }
      }
      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 80)
  }

  func testSingleLineFunc() {
    let input =
      """
      func foo()   ⏩{}⏪
      """

    let expected =
      """
      func foo() {}
      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 80)
  }

  func testSingleLineFunc2() {
    let input =
      """
      func foo() /**/ ⏩{}⏪
      """

    let expected =
      """
      func foo() /**/ {}
      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 80)
  }

  func testSimpleFunc() {
    let input =
      """
      func foo() /**/
        ⏩{}⏪
      """

    let expected =
      """
      func foo() /**/
      {}
      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 80)
  }

  // MARK: - multiple selection ranges
  func testFirstCommentAndVar() {
    let input =
      """
      func foo() {
      if let SomeReallyLongVar = Some.More.Stuff(), let a = myfunc() {
      ⏩⏪// do stuff
      // do more stuff
      ⏩⏪var i = 0
      }
      }
      """

    let expected =
      """
      func foo() {
      if let SomeReallyLongVar = Some.More.Stuff(), let a = myfunc() {
          // do stuff
      // do more stuff
          var i = 0
      }
      }
      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 80)
  }

  // from AccessorTests (but with some Selection ranges)
  func testBasicAccessors() {
    let input =
      """
      ⏩struct MyStruct {
        var memberValue: Int
        var someValue: Int { get { return memberValue + 2 } set(newValue) { memberValue = newValue } }
      }⏪
      struct MyStruct {
        var memberValue: Int
        var someValue: Int { @objc get { return memberValue + 2 } @objc(isEnabled) set(newValue) { memberValue = newValue } }
      }
      struct MyStruct {
        var memberValue: Int
        var memberValue2: Int
        var someValue: Int {
          get {
            let A = 123
            return A
          }
          set(newValue) {
            memberValue = newValue && otherValue
            ⏩memberValue2 = newValue / 2 && andableValue⏪
          }
        }
      }
      struct MyStruct {
        var memberValue: Int
        var SomeValue: Int { return 123 }
        var AnotherValue: Double {
          let out = 1.23
          return out
        }
      }
      """

    let expected =
      """
      struct MyStruct {
        var memberValue: Int
        var someValue: Int {
          get { return memberValue + 2 }
          set(newValue) { memberValue = newValue }
        }
      }
      struct MyStruct {
        var memberValue: Int
        var someValue: Int { @objc get { return memberValue + 2 } @objc(isEnabled) set(newValue) { memberValue = newValue } }
      }
      struct MyStruct {
        var memberValue: Int
        var memberValue2: Int
        var someValue: Int {
          get {
            let A = 123
            return A
          }
          set(newValue) {
            memberValue = newValue && otherValue
            memberValue2 =
              newValue / 2 && andableValue
          }
        }
      }
      struct MyStruct {
        var memberValue: Int
        var SomeValue: Int { return 123 }
        var AnotherValue: Double {
          let out = 1.23
          return out
        }
      }
      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 45)
  }

  // from CommentTests (but with some Selection ranges)
  func testContainerLineComments() {
    let input =
      """
      // Array comment
      let a = [⏩4⏪56, // small comment
        789]

      // Dictionary comment
      let b = ["abc": ⏩456, // small comment
        "def": 789]⏪

      // Trailing comment
      let c = [123, 456  // small comment
      ]

      ⏩/* Array comment */
      let a = [456, /* small comment */
        789]

       /* Dictionary comment */
      let b = ["abc": 456,        /* small comment */
        "def": 789]⏪
      """

    let expected =
      """
      // Array comment
      let a = [
        456, // small comment
        789]

      // Dictionary comment
      let b = ["abc": 456,  // small comment
        "def": 789,
      ]

      // Trailing comment
      let c = [123, 456  // small comment
      ]

      /* Array comment */
      let a = [
        456, /* small comment */
        789,
      ]

      /* Dictionary comment */
      let b = [
        "abc": 456, /* small comment */
        "def": 789,
      ]
      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 80)
  }
}
