final class BinaryOperatorExprTests: PrettyPrintTestCase {
  func testNonRangeFormationOperatorsAreSurroundedByBreaks() {
    let input =
      """
      x=1+8-9  ^*^  5*4/10
      """

    let expected80 =
      """
      x = 1 + 8 - 9 ^*^ 5 * 4 / 10

      """

    assertPrettyPrintEqual(input: input, expected: expected80, linelength: 80)

    let expected10 =
      """
      x =
        1 + 8
        - 9
        ^*^ 5
        * 4 / 10

      """

    assertPrettyPrintEqual(input: input, expected: expected10, linelength: 10)
  }

  func testRangeFormationOperatorsAreCompactedWhenPossible() {
    let input =
      """
      x = 1...100
      x = 1..<100
      x = (1++)...(-100)
      x = 1 ... 100
      x = 1 ..< 100
      x = (1++) ... (-100)
      """

    let expected =
      """
      x = 1...100
      x = 1..<100
      x = (1++)...(-100)
      x = 1...100
      x = 1..<100
      x = (1++)...(-100)

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 80)
  }

  func testRangeFormationOperatorsAreNotCompactedWhenFollowingAPostfixOperator() {
    let input =
      """
      x = 1++ ... 100
      x = 1-- ..< 100
      x = 1++   ...   100
      x = 1--   ..<   100
      """

    let expected80 =
      """
      x = 1++ ... 100
      x = 1-- ..< 100
      x = 1++ ... 100
      x = 1-- ..< 100

      """

    assertPrettyPrintEqual(input: input, expected: expected80, linelength: 80)

    let expected10 =
      """
      x =
        1++
        ... 100
      x =
        1--
        ..< 100
      x =
        1++
        ... 100
      x =
        1--
        ..< 100

      """

    assertPrettyPrintEqual(input: input, expected: expected10, linelength: 10)
  }

  func testRangeFormationOperatorsAreNotCompactedWhenPrecedingAPrefixOperator() {
    let input =
      """
      x = 1 ... -100
      x = 1 ..< -100
      x = 1   ...   √100
      x = 1   ..<   √100
      """

    let expected80 =
      """
      x = 1 ... -100
      x = 1 ..< -100
      x = 1 ... √100
      x = 1 ..< √100

      """

    assertPrettyPrintEqual(input: input, expected: expected80, linelength: 80)

    let expected10 =
      """
      x =
        1
        ... -100
      x =
        1
        ..< -100
      x =
        1
        ... √100
      x =
        1
        ..< √100

      """

    assertPrettyPrintEqual(input: input, expected: expected10, linelength: 10)
  }

  func testRangeFormationOperatorsAreNotCompactedWhenUnaryOperatorsAreOnEachSide() {
    let input =
      """
      x = 1++ ... -100
      x = 1-- ..< -100
      x = 1++   ...   √100
      x = 1--   ..<   √100
      """

    let expected80 =
      """
      x = 1++ ... -100
      x = 1-- ..< -100
      x = 1++ ... √100
      x = 1-- ..< √100

      """

    assertPrettyPrintEqual(input: input, expected: expected80, linelength: 80)

    let expected10 =
      """
      x =
        1++
        ... -100
      x =
        1--
        ..< -100
      x =
        1++
        ... √100
      x =
        1--
        ..< √100

      """

    assertPrettyPrintEqual(input: input, expected: expected10, linelength: 10)
  }

  func testRangeFormationOperatorsAreNotCompactedWhenPrecedingPrefixDot() {
    let input =
      """
      x = .first   ...   .last
      x = .first   ..<   .last
      x = .first   ...   .last
      x = .first   ..<   .last
      """

    let expected80 =
      """
      x = .first ... .last
      x = .first ..< .last
      x = .first ... .last
      x = .first ..< .last

      """

    assertPrettyPrintEqual(input: input, expected: expected80, linelength: 80)

    let expected10 =
      """
      x =
        .first
        ... .last
      x =
        .first
        ..< .last
      x =
        .first
        ... .last
      x =
        .first
        ..< .last

      """

    assertPrettyPrintEqual(input: input, expected: expected10, linelength: 10)
  }
}
