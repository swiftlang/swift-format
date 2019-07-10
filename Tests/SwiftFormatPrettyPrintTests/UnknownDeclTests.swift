public class UnknownDeclTests: PrettyPrintTestCase {
  public func testUnknownDecl() {
    let input =
    """
    struct MyStruct {
      let a = 123
      if a > 10 {
    """

    let expected =
    """
    struct MyStruct {
      let a = 123
      if a > 10 {

    """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 45)
  }
}
