public class StringTests: PrettyPrintTestCase {
  public func testStrings() {
    let input =
      """
      let a = "abc"
      myFun("Some string \\(a + b)")
      let b = "A really long string that should not wrap"
      let c = "A really long string with \\(a + b) some expressions \\(c + d)"
      """

    let expected =
      """
      let a = "abc"
      myFun("Some string \\(a + b)")
      let b
        = "A really long string that should not wrap"
      let c
        = "A really long string with \\(a + b) some expressions \\(c + d)"

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 35)
  }
}
