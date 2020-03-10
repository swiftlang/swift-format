import SwiftFormatPrettyPrint
import SwiftSyntax

final class DictionaryDeclTests: PrettyPrintTestCase {
  func testBasicDictionaries() {
    let input =
      """
      let a = [1: "a", 2: "b", 3: "c",]
      let a: [Int: String] = [1: "a", 2: "b", 3: "c"]
      let a = [10000: "abc", 20000: "def", 30000: "ghi"]
      let a = [10000: "abc", 20000: "def", 30000: "ghij"]
      let a: [Int: String] = [1: "a", 2: "b", 3: "c", 4: "d"]
      let a: [Int: String] = [1: "a", 2: "b", 3: "c", 4: "d", 5: "e", 6: "f", 7: "g"]
      let a: [Int: String] = [1: "a", 2: "b", 3: "c", 4: "d", 5: "e", 6: "f", 7: "g",]
      let a: [Int: String] = [
        1: "a", 2: "b", 3: "c", 4: "d", 5: "e", 6: "f",
        7: "g", 8: "i",
      ]
      """

    let expected =
      """
      let a = [1: "a", 2: "b", 3: "c"]
      let a: [Int: String] = [1: "a", 2: "b", 3: "c"]
      let a = [10000: "abc", 20000: "def", 30000: "ghi"]
      let a = [
        10000: "abc", 20000: "def", 30000: "ghij",
      ]
      let a: [Int: String] = [
        1: "a", 2: "b", 3: "c", 4: "d",
      ]
      let a: [Int: String] = [
        1: "a", 2: "b", 3: "c", 4: "d", 5: "e", 6: "f",
        7: "g",
      ]
      let a: [Int: String] = [
        1: "a", 2: "b", 3: "c", 4: "d", 5: "e", 6: "f",
        7: "g",
      ]
      let a: [Int: String] = [
        1: "a", 2: "b", 3: "c", 4: "d", 5: "e", 6: "f",
        7: "g", 8: "i",
      ]

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 50)
  }

  func testNoTrailingCommasInTypes() {
    let input =
      """
      let a = [SomeVeryLongKeyType: SomePrettyLongValueType]()
      """

    let expected =
      """
      let a = [
        SomeVeryLongKeyType: SomePrettyLongValueType
      ]()

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 50)
  }

  func testWhitespaceOnlyDoesNotChangeTrailingComma() {
    let input =
      """
      let a = [1: "a", 2: "b", 3: "c",]
      let a: [Int: String] = [
        1: "a", 2: "b", 3: "c", 4: "d", 5: "e", 6: "f",
        7: "g", 8: "i"
      ]
      """

    assertPrettyPrintEqual(
      input: input, expected: input + "\n", linelength: 50, whitespaceOnly: true)
  }

  func testTrailingCommaDiagnostics() {
    let input =
      """
      let a = [1: "a", 2: "b", 3: "c",]
      let a: [Int: String] = [
        1: "a", 2: "b", 3: "c", 4: "d", 5: "e", 6: "f",
        7: "g", 8: "i"
      ]
      """

    assertPrettyPrintEqual(
      input: input, expected: input + "\n", linelength: 50, whitespaceOnly: true)

    XCTAssertDiagnosed(.removeTrailingComma, line: 1, column: 32)
    XCTAssertDiagnosed(.addTrailingComma, line: 4, column: 17)
  }

  func testDiscretionaryNewlineAfterColon() {
    let input =
      """
      let a = [
        "reallyLongKeySoTheValueWillWrap":
          value
      ]
      let a = [
        "shortKey":
          value
      ]
      let a = [
        "shortKey": Very.Deeply.Nested.Member
      ]
      let a = [
        "shortKey":
          Very.Deeply.Nested.Member
      ]
      let a:
        [ReallyLongKeySoTheValueWillWrap:
          Value]
      let a:
        [ShortKey:
          Value]
      """

    let expected =
      """
      let a = [
        "reallyLongKeySoTheValueWillWrap":
          value
      ]
      let a = [
        "shortKey":
          value
      ]
      let a = [
        "shortKey": Very
          .Deeply.Nested
          .Member
      ]
      let a = [
        "shortKey":
          Very.Deeply
          .Nested.Member
      ]
      let a:
        [ReallyLongKeySoTheValueWillWrap:
          Value]
      let a:
        [ShortKey:
          Value]

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 20)
  }

  func testGroupsTrailingComma() {
    let input =
      """
      let d = [
        key: cond ? firstOption : secondOption,
        key2: bar(),
      ]
      """

    let expected =
      """
      let d = [
        key: cond
          ? firstOption
          : secondOption,
        key2: bar(),
      ]

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 32)
  }
}
