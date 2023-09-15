final class ConstrainedSugarTypeTests: PrettyPrintTestCase {
  func testSomeTypes() {
    let input =
      """
      var body: some View
      func foo() -> some Foo
      """

    assertPrettyPrintEqual(input: input, expected: input + "\n", linelength: 25)

    let expected11 =
      """
      var body:
        some View
      func foo()
        -> some Foo

      """
    assertPrettyPrintEqual(input: input, expected: expected11, linelength: 11)
  }

  func testAnyTypes() {
    let input =
      """
      var body: any View
      func foo() -> any Foo
      """

    assertPrettyPrintEqual(input: input, expected: input + "\n", linelength: 25)

    let expected11 =
      """
      var body:
        any View
      func foo()
        -> any Foo

      """
    assertPrettyPrintEqual(input: input, expected: expected11, linelength: 11)
  }
}
