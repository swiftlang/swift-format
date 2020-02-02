final class NewlineTests: PrettyPrintTestCase {
  func testLeadingNewlines() {
    let input =
      """


      let a = 123
      """

    let expected =
      """
      let a = 123

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 45)
  }

  func testLeadingNewlinesWithComments() {
    let input =
      """


      // Comment

      let a = 123
      """

    let expected =
      """
      // Comment

      let a = 123

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 45)
  }

  func testTrailingNewlines() {
    let input =
      """
      let a = 123


      """

    let expected =
      """
      let a = 123

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 45)
  }

  func testTrailingNewlinesWithComments() {
    let input =
      """
      let a = 123

      // Comment


      """

    let expected =
      """
      let a = 123

      // Comment

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 45)
  }
}
