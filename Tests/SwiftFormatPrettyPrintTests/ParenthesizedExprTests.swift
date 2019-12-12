class ParenthesizedExprTests: PrettyPrintTestCase {

  func testSequenceExprParens() {
    let input =
      """
      x = (firstTerm + secondTerm + thirdTerm)
      x = (firstTerm + secondTerm + thirdTerm) - (firstTerm + secondTerm + thirdTerm)
      x = (firstTerm + secondTerm + thirdTerm) - (firstTerm + secondTerm + thirdTerm) * (firstTerm + secondTerm + thirdTerm)
      x = zerothTerm + (firstTerm + secondTerm + thirdTerm)
      x = zerothTerm + (firstTerm + secondTerm + thirdTerm) - (firstTerm + secondTerm + thirdTerm)
      x = zerothTerm + (firstTerm + secondTerm + thirdTerm) - (firstTerm + secondTerm + thirdTerm) * (firstTerm + secondTerm + thirdTerm)
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
}
