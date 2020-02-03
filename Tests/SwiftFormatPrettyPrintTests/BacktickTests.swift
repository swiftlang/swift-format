final class BacktickTests: PrettyPrintTestCase {
  func testBackticks() {
    let input =
      """
      let `case` = 123
      enum MyEnum {
        case `break`
        case `continue`
        case `case`(var1: Int, Double)
      }

      """

    let expected =
      """
      let `case` = 123
      enum MyEnum {
        case `break`
        case `continue`
        case `case`(var1: Int, Double)
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 45)
  }
}
