import SwiftFormatPrettyPrint
import SwiftSyntax

final class ArrayDeclTests: PrettyPrintTestCase {
  func testBasicArrays() {
    let input =
      """
      let a = [1, 2, 3,]
      let a: [Bool] = [false, true, true, false]
      let a = [11111111, 2222222, 33333333, 444444]
      let a = [11111111, 2222222, 33333333, 4444444]
      let a: [String] = ["One", "Two", "Three", "Four"]
      let a: [String] = ["One", "Two", "Three", "Four", "Five", "Six", "Seven"]
      let a: [String] = ["One", "Two", "Three", "Four", "Five", "Six", "Seven",]
      let a: [String] = [
        "One", "Two", "Three", "Four", "Five",
        "Six", "Seven", "Eight",
      ]
      """

    let expected =
      """
      let a = [1, 2, 3]
      let a: [Bool] = [false, true, true, false]
      let a = [11111111, 2222222, 33333333, 444444]
      let a = [
        11111111, 2222222, 33333333, 4444444,
      ]
      let a: [String] = [
        "One", "Two", "Three", "Four",
      ]
      let a: [String] = [
        "One", "Two", "Three", "Four", "Five",
        "Six", "Seven",
      ]
      let a: [String] = [
        "One", "Two", "Three", "Four", "Five",
        "Six", "Seven",
      ]
      let a: [String] = [
        "One", "Two", "Three", "Four", "Five",
        "Six", "Seven", "Eight",
      ]

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 45)
  }

  func testArrayOfFunctions() {
    let input =
      """
      let A = [(Int, Double) -> Bool]()
      let A = [(Int, Double) throws -> Bool]()
      """

    let expected =
      """
      let A = [(Int, Double) -> Bool]()
      let A = [(Int, Double) throws -> Bool]()

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 45)
  }

  func testNoTrailingCommasInTypes() {
    let input =
      """
      let a = [SomeSuperMegaLongTypeName]()
      """

    let expected =
      """
      let a = [
        SomeSuperMegaLongTypeName
      ]()

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 30)
  }

  func testWhitespaceOnlyDoesNotChangeTrailingComma() {
    let input =
      """
      let a = [1, 2, 3,]
      let a: [String] = [
        "One", "Two", "Three", "Four", "Five",
        "Six", "Seven", "Eight"
      ]
      """

    assertPrettyPrintEqual(
      input: input, expected: input + "\n", linelength: 45, whitespaceOnly: true)
  }

  func testTrailingCommaDiagnostics() {
    let input =
      """
      let a = [1, 2, 3,]
      let a: [String] = [
        "One", "Two", "Three", "Four", "Five",
        "Six", "Seven", "Eight"
      ]
      """

    assertPrettyPrintEqual(
      input: input, expected: input + "\n", linelength: 45, whitespaceOnly: true)

    XCTAssertDiagnosed(.removeTrailingComma, line: 1, column: 17)
    XCTAssertDiagnosed(.addTrailingComma, line: 4, column: 26)
  }

  func testGroupsTrailingComma() {
    let input =
      """
      let a = [
        condition ? firstOption : secondOption,
        bar(),
      ]
      """

    let expected =
      """
      let a = [
        condition
          ? firstOption
          : secondOption,
        bar(),
      ]

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 32)
  }
}
