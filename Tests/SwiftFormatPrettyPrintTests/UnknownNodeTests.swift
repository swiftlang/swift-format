import XCTest

/// Tests for unknown/malformed nodes that ensure that they are handled as verbatim text so that
/// their internal tokens do not get squashed together.
final class UnknownNodeTests: PrettyPrintTestCase {
  func testUnknownDecl() throws {
    throw XCTSkip("This is no longer an unknown declaration")

    let input =
      """
      struct MyStruct where {
        let a = 123
      }
      """

    assertPrettyPrintEqual(input: input, expected: input + "\n", linelength: 45)
  }

  func testUnknownExpr() throws {
    throw XCTSkip("This is no longer an unknown expression")

    let input =
      """
      (foo where bar)
      """

    assertPrettyPrintEqual(input: input, expected: input + "\n", linelength: 45)
  }

  func testUnknownPattern() throws {
    let input =
      """
      if case * ! = x {
        bar()
      }
      """

    let expected =
      """
      if case
        * ! = x
      {
        bar()
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 45)
  }

  func testUnknownStmt() throws {
    throw XCTSkip("This is no longer an unknown statement")

    let input =
      """
      if foo where {
      }
      """

    assertPrettyPrintEqual(input: input, expected: input + "\n", linelength: 45)
  }

  func testUnknownType() throws {    
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

  func testNonEmptyTokenList() throws {
    // The C++ parse modeled as a non-empty list of unparsed tokens. The Swift
    // parser sees through this and treats it as an attribute with a missing
    // name and some unexpected text after `foo!` in the arguments.
    throw XCTSkip("This is no longer a non-empty token list")

    let input =
      """
      @(foo ! @ # bar)
      """

    assertPrettyPrintEqual(input: input, expected: input + "\n", linelength: 45)
  }
}
