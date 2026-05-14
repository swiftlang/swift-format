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

final class ThrowStmtTests: PrettyPrintTestCase {
  func testIgnoresDiscretionaryNewlineBeforeExpression() {
    let input =
      """
      func f() throws {
        throw
          SomeError
          .memberA(.optionA)
          .memberB
      }
      """

    let expected =
      """
      func f() throws {
        throw SomeError
          .memberA(.optionA)
          .memberB
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 80)
  }

  func testWrapsLongExpression() {
    let input =
      """
      func f() throws {
        throw SomeError.aReallyLongCaseName(withAnArgument: someValue)
      }
      """

    let expected =
      """
      func f() throws {
        throw
          SomeError
          .aReallyLongCaseName(
            withAnArgument:
              someValue)
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 30)
  }

  func testPreservesDiscretionaryNewlineForBareIdentifierExpression() {
    let input =
      """
      func f() throws {
        throw
          someErrorValue
      }
      """

    assertPrettyPrintEqual(input: input, expected: input + "\n", linelength: 80)
  }

  func testCollapsesDiscretionaryNewlineForShortMemberAccessExpression() {
    let input =
      """
      func f() throws {
        throw
          SomeError.singleCase
      }
      """

    let expected =
      """
      func f() throws {
        throw SomeError.singleCase
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 80)
  }

  func testCollapsesDiscretionaryNewlineForCallWithMemberAccessCallee() {
    let input =
      """
      func f() throws {
        throw
          SomeError
          .someCase(argument: someValue)
      }
      """

    let expected =
      """
      func f() throws {
        throw SomeError
          .someCase(argument: someValue)
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 80)
  }

  func testPreservesDiscretionaryNewlineWhenChainIsPrecededByLineComment() {
    let input =
      """
      func f() throws {
        throw
          // explain why this particular error
          SomeError
          .memberA
          .memberB
      }
      """

    assertPrettyPrintEqual(input: input, expected: input + "\n", linelength: 80)
  }

  func testPreservesLineCommentAfterKeyword() {
    let input =
      """
      func f() throws {
        throw  // some note
          SomeError
          .memberA
          .memberB
      }
      """

    assertPrettyPrintEqual(input: input, expected: input + "\n", linelength: 80)
  }

  func testCollapsesDiscretionaryNewlineForImplicitMemberAccess() {
    let input =
      """
      func f() throws {
        throw
          .failure(someError)
      }
      """

    let expected =
      """
      func f() throws {
        throw .failure(someError)
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 80)
  }
}
