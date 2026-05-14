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

final class ReturnStmtTests: PrettyPrintTestCase {
  func testIgnoresDiscretionaryNewlineBeforeExpression() {
    let input =
      """
      func f() -> SomeResult {
        return
          SomeResult
          .memberA
          .memberB
      }
      """

    let expected =
      """
      func f() -> SomeResult {
        return SomeResult
          .memberA
          .memberB
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 80)
  }

  func testWrapsLongExpression() {
    let input =
      """
      func f() -> Value {
        return SomeType.someStaticFactoryMethod(withArgument: someValue)
      }
      """

    let expected =
      """
      func f() -> Value {
        return
          SomeType
          .someStaticFactoryMethod(
            withArgument: someValue)
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 30)
  }

  func testPreservesDiscretionaryNewlineForBareIdentifierExpression() {
    let input =
      """
      func f() -> Int {
        return
          someValue
      }
      """

    assertPrettyPrintEqual(input: input, expected: input + "\n", linelength: 80)
  }

  func testPreservesDiscretionaryNewlineWhenChainIsPrecededByLineComment() {
    let input =
      """
      func f() -> SomeResult {
        return
          // explanation of why we return this specific value
          SomeResult
          .memberA
          .memberB
      }
      """

    assertPrettyPrintEqual(input: input, expected: input + "\n", linelength: 80)
  }

  func testCollapsesDiscretionaryNewlineForImplicitMemberAccess() {
    let input =
      """
      func f() -> Result {
        return
          .success(value)
      }
      """

    let expected =
      """
      func f() -> Result {
        return .success(value)
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 80)
  }
}
