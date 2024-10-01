import SwiftFormat

final class DoStmtTests: PrettyPrintTestCase {
  func testBasicDoStmt() {
    let input =
      """
      do {}
      do { f() }
      do { foo() }
      do { let a = 123
      var b = "abc"
      }
      do { veryLongFunctionCallThatShouldBeBrokenOntoANewLine() }
      """

    let expected =
      """
      do {}
      do { f() }
      do { foo() }
      do {
        let a = 123
        var b = "abc"
      }
      do {
        veryLongFunctionCallThatShouldBeBrokenOntoANewLine()
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 25)
  }

  func testLabeledDoStmt() {
    let input = """
      someLabel:do {
        bar()
        baz()
      }
      somePrettyLongLabelThatTakesUpManyColumns: do {
        bar()
        baz()
      }
      """

    let expected = """
      someLabel: do {
        bar()
        baz()
      }
      somePrettyLongLabelThatTakesUpManyColumns: do
      {
        bar()
        baz()
      }

      """
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 45)
  }

  func testDoTypedThrowsStmt() {
    let input =
      """
      do throws(FooError) {
        foo()
      }
      """

    assertPrettyPrintEqual(
      input: input,
      expected:
        """
        do
        throws(FooError) {
          foo()
        }

        """,
      linelength: 18
    )
    assertPrettyPrintEqual(
      input: input,
      expected:
        """
        do throws(FooError) {
          foo()
        }

        """,
      linelength: 25
    )
  }
}
