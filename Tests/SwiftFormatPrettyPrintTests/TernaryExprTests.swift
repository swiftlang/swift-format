public class TernaryExprTests: PrettyPrintTestCase {
  public func testTernaryExprs() {
    let input =
      """
      let x = a ? b : c
      let y = a ?b:c
      let z = a ? b: c
      let reallyLongName = a ? longTruePart : longFalsePart
      let reallyLongName = reallyLongCondition ? reallyLongTruePart : reallyLongFalsePart
      let reallyLongName = reallyLongCondition ? reallyReallyReallyLongTruePart : reallyLongFalsePart
      """

    let expected =
      """
      let x = a ? b : c
      let y = a ? b : c
      let z = a ? b : c
      let reallyLongName = a
        ? longTruePart : longFalsePart
      let reallyLongName = reallyLongCondition
        ? reallyLongTruePart : reallyLongFalsePart
      let reallyLongName = reallyLongCondition
        ? reallyReallyReallyLongTruePart
        : reallyLongFalsePart

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 45)
  }
}
