final class SomeTypeTests: PrettyPrintTestCase {
  func testSomeTypes() {
    let input =
      """
      var body: some View
      func foo() -> some Foo
      """

    assertPrettyPrintEqual(input: input, expected: input + "\n", linelength: 25)
  }
}
