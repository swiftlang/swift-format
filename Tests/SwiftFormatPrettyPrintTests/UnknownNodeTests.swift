/// Tests for unknown/malformed nodes that ensure that they are handled as verbatim text so that
/// their internal tokens do not get squashed together.
final class UnknownNodeTests: PrettyPrintTestCase {
  func testUnknownDecl() {
    let input =
      """
      struct MyStruct where {
        let a = 123
      }
      """

    assertPrettyPrintEqual(input: input, expected: input + "\n", linelength: 45)
  }

  func testUnknownExpr() {
    let input =
      """
      (foo where bar)
      """

    assertPrettyPrintEqual(input: input, expected: input + "\n", linelength: 45)
  }

  func testUnknownPattern() {
    // This one loses the space after the word `case` because the break would normally be
    // inserted before the first token in the pattern.
    let input =
      """
      if case * ! = x {
        bar()
      }
      """

    let expected =
      """
      if case* ! = x {
        bar()
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 45)
  }

  func testUnknownStmt() {
    let input =
      """
      if foo where {
        bar()
      }
      """

    assertPrettyPrintEqual(input: input, expected: input + "\n", linelength: 45)
  }

  func testUnknownType() {
    // This one loses the space after the colon because the break would normally be inserted before
    // the first token in the type name.
    let input =
      """
      let x: where
      """

    let expected =
      """
      let x:where

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 45)
  }

  func testNonEmptyTokenList() {
    let input =
      """
      @(foo ! @ # bar)
      """

    assertPrettyPrintEqual(input: input, expected: input + "\n", linelength: 45)
  }
}
