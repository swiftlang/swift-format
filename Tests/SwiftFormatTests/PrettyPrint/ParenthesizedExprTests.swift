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

final class ParenthesizedExprTests: PrettyPrintTestCase {
  func testSequenceExprParens() {
    let input =
      """
      x = (firstTerm + secondTerm + thirdTerm)
      x = (firstTerm + secondTerm + thirdTerm) - (firstTerm + secondTerm + thirdTerm)
      x = (firstTerm + secondTerm + thirdTerm) - (firstTerm + secondTerm + thirdTerm) * (firstTerm + secondTerm + thirdTerm)
      x = zerothTerm + (firstTerm + secondTerm + thirdTerm)
      x = zerothTerm + (firstTerm + secondTerm + thirdTerm) - (firstTerm + secondTerm + thirdTerm)
      x = zerothTerm + (firstTerm + secondTerm + thirdTerm) - (firstTerm + secondTerm + thirdTerm) * (firstTerm + secondTerm + thirdTerm)
      x = zerothTerm + (
          firstTerm + secondTerm + thirdTerm
        ) -
        (
          firstTerm + secondTerm + thirdTerm
        )
      x = zerothTerm + (
        firstTerm + secondTerm + (
            nestedFirstTerm + nestedSecondTerm + (
              doubleNestedFirstTerm + doubleNestedSecondTerm
            )
        )
      ) + thirdTerm
      x = zerothTerm + (
      firstTerm + secondTerm && thirdTerm + (
          nestedFirstTerm || nestedSecondTerm + (
            doubleNestedFirstTerm + doubleNestedSecondTerm
          )
        )
      )
      """

    let expected =
      """
      x =
        (firstTerm + secondTerm
          + thirdTerm)
      x =
        (firstTerm + secondTerm
          + thirdTerm)
        - (firstTerm + secondTerm
          + thirdTerm)
      x =
        (firstTerm + secondTerm
          + thirdTerm)
        - (firstTerm + secondTerm
          + thirdTerm)
        * (firstTerm + secondTerm
          + thirdTerm)
      x =
        zerothTerm
        + (firstTerm + secondTerm
          + thirdTerm)
      x =
        zerothTerm
        + (firstTerm + secondTerm
          + thirdTerm)
        - (firstTerm + secondTerm
          + thirdTerm)
      x =
        zerothTerm
        + (firstTerm + secondTerm
          + thirdTerm)
        - (firstTerm + secondTerm
          + thirdTerm)
        * (firstTerm + secondTerm
          + thirdTerm)
      x =
        zerothTerm
        + (firstTerm + secondTerm
          + thirdTerm)
        - (firstTerm + secondTerm
          + thirdTerm)
      x =
        zerothTerm
        + (firstTerm + secondTerm
          + (nestedFirstTerm
            + nestedSecondTerm
            + (doubleNestedFirstTerm
              + doubleNestedSecondTerm)))
        + thirdTerm
      x =
        zerothTerm
        + (firstTerm + secondTerm
          && thirdTerm
            + (nestedFirstTerm
              || nestedSecondTerm
                + (doubleNestedFirstTerm
                  + doubleNestedSecondTerm)))

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 30)
  }

  func testInitializerClauseParens() {
    let input =
      """
      let x = (firstTerm + secondTerm + thirdTerm)
      let y = (firstTerm + secondTerm + thirdTerm) - (firstTerm + secondTerm + thirdTerm)
      let x = zerothTerm + (firstTerm + secondTerm + thirdTerm)
      let y = zerothTerm + (firstTerm + secondTerm + thirdTerm) - (firstTerm + secondTerm + thirdTerm)
      """

    let expected =
      """
      let x =
        (firstTerm + secondTerm
          + thirdTerm)
      let y =
        (firstTerm + secondTerm
          + thirdTerm)
        - (firstTerm + secondTerm
          + thirdTerm)
      let x =
        zerothTerm
        + (firstTerm + secondTerm
          + thirdTerm)
      let y =
        zerothTerm
        + (firstTerm + secondTerm
          + thirdTerm)
        - (firstTerm + secondTerm
          + thirdTerm)

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 30)
  }

  func testNestedParentheses() {
    let input =
      """
      theFirstTerm + secondTerm * (nestedThing - (moreNesting + anotherTerm)) / andThatsAll
      theFirstTerm + secondTerm * (nestedThing - (moreNesting + anotherTerm) + yetAnother) / andThatsAll
      """

    let expected =
      """
      theFirstTerm
        + secondTerm
        * (nestedThing
          - (moreNesting
            + anotherTerm))
        / andThatsAll
      theFirstTerm
        + secondTerm
        * (nestedThing
          - (moreNesting
            + anotherTerm)
          + yetAnother)
        / andThatsAll

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 23)
  }

  func testExpressionStartsWithParentheses() {
    let input =
      """
      (firstTerm + secondTerm + thirdTerm)(firstArg, secondArg, thirdArg)
      """

    let expected =
      """
      (firstTerm
        + secondTerm
        + thirdTerm)(
          firstArg,
          secondArg,
          thirdArg)

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 20)
  }

  func testComplexConditionalWithParens() {
    let input =
      """
      if (someNumericValue > NumericConstants.someConstant || (otherValue.n) > NumericConstants.otherValueToCheck) && (otherValue.n) > -NumericConstants.otherValueToCheck {
        openMenu()
      }
      """

    let expected =
      """
      if (someNumericValue > NumericConstants.someConstant
        || (otherValue.n) > NumericConstants.otherValueToCheck)
        && (otherValue.n) > -NumericConstants.otherValueToCheck
      {
        openMenu()
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 80)
  }

  func testTupleSequenceExprs() {
    let input =
      """
      let x = (
        (
          firstTupleElem,
          secondTupleElem,
          thirdTupleElem
        ) == (
          firstTupleElem,
          secondTupleElem,
          thirdTupleElem
        ) && (
          firstTupleElem,
          secondTupleElem,
          thirdTupleElem
        ) || (
          firstTupleElem,
          secondTupleElem,
          thirdTupleElem
        )
      )
      let x = (
        (
          firstTupleElem,
          secondTupleElem,
          thirdTupleElem
        ) && (
          foo(firstFuncCallArg, second: secondFuncCallArg, third: thirdFuncCallArg, fourth: fourthFuncCallArg)
        ) || (
          firstTupleElem,
          secondTupleElem,
          thirdTupleElem
        ) == (
          foo(firstFuncCallArg, second: secondFuncCallArg, third: thirdFuncCallArg, fourth: fourthFuncCallArg
        )
        )
      )
      let x = (
        foo(firstFuncCallArg, second: secondFuncCallArg, third: thirdFuncCallArg, fourth: fourthFuncCallArg
        ) && (
          firstTupleElem,
          secondTupleElem,
          thirdTupleElem
        ) || (
          firstTupleElem,
          secondTupleElem,
          thirdTupleElem
        )
      )
      """

    let expected =
      """
      let x =
        ((
          firstTupleElem,
          secondTupleElem,
          thirdTupleElem
        ) == (
          firstTupleElem,
          secondTupleElem,
          thirdTupleElem
        )
          && (
            firstTupleElem,
            secondTupleElem,
            thirdTupleElem
          )
          || (
            firstTupleElem,
            secondTupleElem,
            thirdTupleElem
          ))
      let x =
        ((
          firstTupleElem,
          secondTupleElem,
          thirdTupleElem
        )
          && (foo(
            firstFuncCallArg, second: secondFuncCallArg,
            third: thirdFuncCallArg,
            fourth: fourthFuncCallArg))
          || (
            firstTupleElem,
            secondTupleElem,
            thirdTupleElem
          )
            == (foo(
              firstFuncCallArg,
              second: secondFuncCallArg,
              third: thirdFuncCallArg,
              fourth: fourthFuncCallArg
            )))
      let x =
        (foo(
          firstFuncCallArg, second: secondFuncCallArg,
          third: thirdFuncCallArg,
          fourth: fourthFuncCallArg
        )
          && (
            firstTupleElem,
            secondTupleElem,
            thirdTupleElem
          )
          || (
            firstTupleElem,
            secondTupleElem,
            thirdTupleElem
          ))

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 50)
  }
}
