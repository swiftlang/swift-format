public class BinaryOperatorExprTests: PrettyPrintTestCase {
  public func testOperatorSpacing() {
    let input =
      """
      x=1+8-9  ..<  5*4/10
      """

    let expected =
      """
      x = 1 + 8 - 9..<5 * 4 / 10

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 80)
  }
}
