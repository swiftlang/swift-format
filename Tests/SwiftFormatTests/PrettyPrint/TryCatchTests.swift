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

final class TryCatchTests: PrettyPrintTestCase {
  func testBasicTries() {
    let input =
      """
      let a = try possiblyFailingFunc()
      let a = try? possiblyFailingFunc()
      let a = try! possiblyFailingFunc()
      """

    let expected =
      """
      let a = try possiblyFailingFunc()
      let a = try? possiblyFailingFunc()
      let a = try! possiblyFailingFunc()

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 40)
  }

  func testDoTryCatch_noBreakBeforeCatch() {
    let input =
      """
      do { try thisFuncMightFail() } catch error1 { print("Nope") }
      do { try thisFuncMightFail() } catch error1 { print("Nope") } catch error2 { print("Nope") }
      do { try thisFuncMightFail() } catch error1 { print("Nope") } catch error2(let someVar) { print("Nope") }
      do { try thisFuncMightFail() } catch error1 { print("Nope") }
      catch error2(let someVar) {
        print(someVar)
        print("Don't do it!")
      }
      do { try thisFuncMightFail() } catch is ABadError{ print("Nope") }
      """

    let expected =
      """
      do {
        try thisFuncMightFail()
      } catch error1 { print("Nope") }
      do {
        try thisFuncMightFail()
      } catch error1 {
        print("Nope")
      } catch error2 { print("Nope") }
      do {
        try thisFuncMightFail()
      } catch error1 {
        print("Nope")
      } catch error2(let someVar) {
        print("Nope")
      }
      do {
        try thisFuncMightFail()
      } catch error1 {
        print("Nope")
      } catch error2(let someVar) {
        print(someVar)
        print("Don't do it!")
      }
      do {
        try thisFuncMightFail()
      } catch is ABadError { print("Nope") }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 40)
  }

  func testDoTryCatch_breakBeforeCatch() {
    let input =
      """
      do { try thisFuncMightFail() } catch error1 { print("Nope") }
      do { try thisFuncMightFail() } catch error1 { print("Nope") } catch error2 { print("Nope") }
      do { try thisFuncMightFail() } catch error1 { print("Nope") } catch error2(let someVar) { print("Nope") }
      do { try thisFuncMightFail() } catch error1 { print("Nope") }
      catch error2(let someVar) {
        print(someVar)
        print("Don't do it!")
      }
      do { try thisFuncMightFail() } catch is ABadError{ print("Nope") }
      """

    let expected =
      """
      do { try thisFuncMightFail() }
      catch error1 { print("Nope") }
      do { try thisFuncMightFail() }
      catch error1 { print("Nope") }
      catch error2 { print("Nope") }
      do { try thisFuncMightFail() }
      catch error1 { print("Nope") }
      catch error2(let someVar) {
        print("Nope")
      }
      do { try thisFuncMightFail() }
      catch error1 { print("Nope") }
      catch error2(let someVar) {
        print(someVar)
        print("Don't do it!")
      }
      do { try thisFuncMightFail() }
      catch is ABadError { print("Nope") }

      """

    var config = Configuration.forTesting
    config.lineBreakBeforeControlFlowKeywords = true
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 40, configuration: config)
  }

  func testCatchWhere_noBreakBeforeCatch() {
    let input =
      """
      do { try thisFuncMightFail() } catch error1 where error1 is ErrorType { print("Nope") }
      do { try thisFuncMightFail() } catch error1 where error1 is LongerErrorType { print("Nope") }
      """

    let expected =
      """
      do {
        try thisFuncMightFail()
      } catch error1 where error1 is ErrorType {
        print("Nope")
      }
      do {
        try thisFuncMightFail()
      } catch error1
        where error1 is LongerErrorType
      { print("Nope") }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 42)
  }

  func testCatchWhere_breakBeforeCatch() {
    let input =
      """
      do { try thisFuncMightFail() } catch error1 where error1 is ErrorType { print("Nope") }
      do { try thisFuncMightFail() } catch error1 where error1 is LongerErrorType { print("Nope") }
      """

    let expected =
      """
      do { try thisFuncMightFail() }
      catch error1 where error1 is ErrorType {
        print("Nope")
      }
      do { try thisFuncMightFail() }
      catch error1
      where error1 is LongerErrorType {
        print("Nope")
      }

      """

    var config = Configuration.forTesting
    config.lineBreakBeforeControlFlowKeywords = true
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 42, configuration: config)
  }

  func testNestedDo() {
    // Avoid regressions in the case where a nested `do` block was getting shifted all the way left.
    let input = """
      func foo() {
        do {
          bar()
          baz()
        }
      }
      """
    assertPrettyPrintEqual(input: input, expected: input + "\n", linelength: 45)
  }

  func testMultipleCatchItems() {
    let input =
      """
      do { try thisMightFail() } catch error1, error2 { print("Nope") }
      do { try thisMightFail() } catch longErrorType, error2 { print("Nope") }
      do { try thisMightFail() } catch longErrorTypeName, longErrorType2(let someLongVariable) { print("Nope") }
      do { try thisMightFail() } catch longErrorTypeName, longErrorType2 as SomeLongErrorType { print("Nope") }
      do { try thisMightFail() } catch longErrorName where someCondition, longErrorType2 { print("Nope") }
      do { try thisMightFail() } catch longErrorTypeName, longErrorType2 as SomeLongErrorType where someCondition, longErrorType3 { print("Nope") }
      """

    let expected =
      """
      do {
        try thisMightFail()
      } catch error1, error2 {
        print("Nope")
      }
      do {
        try thisMightFail()
      } catch longErrorType,
        error2
      { print("Nope") }
      do {
        try thisMightFail()
      } catch
        longErrorTypeName,
        longErrorType2(
          let someLongVariable)
      { print("Nope") }
      do {
        try thisMightFail()
      } catch
        longErrorTypeName,
        longErrorType2
          as SomeLongErrorType
      { print("Nope") }
      do {
        try thisMightFail()
      } catch longErrorName
        where someCondition,
        longErrorType2
      { print("Nope") }
      do {
        try thisMightFail()
      } catch
        longErrorTypeName,
        longErrorType2
          as SomeLongErrorType
          where someCondition,
        longErrorType3
      { print("Nope") }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 25)
  }

  func testTryKeywordBreaking() {
    let input =
      """
      let aVeryLongArgumentName = try foo.bar()
      let aVeryLongArgumentName = try
        foo.bar()
      let aVeryLongArgumentName = try? foo.bar()
      let abc = try foo.baz().quxxe(a, b, c).bar()
      let abc = try foo
        .baz().quxxe(a, b, c).bar()
      let abc = try [1, 2, 3, 4, 5, 6, 7].baz().quxxe(a, b, c).bar()
      let abc = try [1, 2, 3, 4, 5, 6, 7]
        .baz().quxxe(a, b, c).bar()
      let abc = try foo.baz().quxxe(a, b, c).bar[0]
      let abc = try foo
        .baz().quxxe(a, b, c).bar[0]
      let abc = try
        foo
        .baz().quxxe(a, b, c).bar[0]
      """

    let expected =
      """
      let aVeryLongArgumentName =
        try foo.bar()
      let aVeryLongArgumentName =
        try foo.bar()
      let aVeryLongArgumentName =
        try? foo.bar()
      let abc = try foo.baz().quxxe(a, b, c)
        .bar()
      let abc =
        try foo
        .baz().quxxe(a, b, c).bar()
      let abc = try [1, 2, 3, 4, 5, 6, 7]
        .baz().quxxe(a, b, c).bar()
      let abc = try [1, 2, 3, 4, 5, 6, 7]
        .baz().quxxe(a, b, c).bar()
      let abc = try foo.baz().quxxe(a, b, c)
        .bar[0]
      let abc =
        try foo
        .baz().quxxe(a, b, c).bar[0]
      let abc =
        try foo
        .baz().quxxe(a, b, c).bar[0]

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 40)
  }
}
