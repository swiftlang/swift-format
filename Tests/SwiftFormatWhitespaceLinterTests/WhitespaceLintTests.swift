@testable import SwiftFormatWhitespaceLinter

public class WhitespaceLintTests: WhitespaceTestCase {
  public func testSpacing() {
    let input =
      """
      let a : Int = 123
      let b =456

      """

    let expected =
      """
      let a: Int = 123
      let b = 456

      """

    performWhitespaceLint(input: input, expected: expected)
    XCTAssertDiagnosed(.spacingError(0), line: 1, column: 6)
    XCTAssertDiagnosed(.spacingError(1), line: 2, column: 8)
  }

  public func testIndentation() {
    let input =
      """
        let a = 123
      let b = 456
       let c = "abc"

      """

    let expected =
      """
      let a = 123
        let b = 456
      let c = "abc"

      """

    performWhitespaceLint(input: input, expected: expected)
    XCTAssertDiagnosed(.indentationError(0), line: 1, column: 1)
    XCTAssertDiagnosed(.indentationError(2), line: 2, column: 1)
    XCTAssertDiagnosed(.indentationError(0), line: 3, column: 1)
  }

  public func testTrailingWhitespace() {
    let input =
      """
      let a = 123\u{20}\u{20}
      let b = "abc"\u{20}
      let c = "def"
      \u{20}\u{20}
      let d = 456\u{20}\u{20}\u{20}

      """

    let expected =
      """
      let a = 123
      let b = "abc"
      let c = "def"

      let d = 456

      """

    performWhitespaceLint(input: input, expected: expected)
    XCTAssertDiagnosed(.trailingWhitespaceError, line: 1, column: 12)
    XCTAssertDiagnosed(.trailingWhitespaceError, line: 2, column: 14)
    XCTAssertDiagnosed(.trailingWhitespaceError, line: 4, column: 1)
    XCTAssertDiagnosed(.trailingWhitespaceError, line: 5, column: 12)
  }

  public func testAddLines() {
    let input =
      """
      let a = 123
      let b = "abc"
      func myfun() { return }

      """

    let expected =
      """
      let a = 123

      let b = "abc"
      func myfun() {
        return
      }

      """

    performWhitespaceLint(input: input, expected: expected)
    XCTAssertDiagnosed(.addLinesError(1), line: 2, column: 0)
    XCTAssertDiagnosed(.addLinesError(1), line: 3, column: 15)
    XCTAssertDiagnosed(.addLinesError(1), line: 3, column: 22)
  }

  public func testRemoveLines() {
    let input =
      """
      let a = 123

      let b = "abc"


      let c = 456
      func myFun() {
        return someValue
      }

      """

    let expected =
      """
      let a = 123
      let b = "abc"
      let c = 456
      func myFun() { return someValue }

      """

    performWhitespaceLint(input: input, expected: expected)
    XCTAssertDiagnosed(.removeLineError, line: 2, column: 0)
    XCTAssertDiagnosed(.removeLineError, line: 4, column: 0)
    XCTAssertDiagnosed(.removeLineError, line: 5, column: 0)
    XCTAssertDiagnosed(.removeLineError, line: 8, column: 0)
    XCTAssertDiagnosed(.removeLineError, line: 9, column: 0)
  }

  public func testLineLength() {
    let input =
      """
      func myFunc(longVar1: Bool, longVar2: Bool, longVar3: Bool, longVar4: Bool) {
        // do stuff
      }

      func myFunc(longVar1: Bool, longVar2: Bool,
        longVar3: Bool,
        longVar4: Bool) {
        // do stuff
      }

      """

    let expected =
      """
      func myFunc(
        longVar1: Bool,
        longVar2: Bool,
        longVar3: Bool,
        longVar4: Bool
      ) {
        // do stuff
      }

      func myFunc(
        longVar1: Bool,
        longVar2: Bool,
        longVar3: Bool,
        longVar4: Bool
      ) {
        // do stuff
      }

      """

    performWhitespaceLint(input: input, expected: expected, linelength: 30)
    XCTAssertDiagnosed(.lineLengthError, line: 1, column: 1)
    XCTAssertDiagnosed(.lineLengthError, line: 5, column: 1)
    XCTAssertDiagnosed(.addLinesError(1), line: 7, column: 17)
  }
}
