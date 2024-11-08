@_spi(ExperimentalLanguageFeatures) import SwiftParser

final class ValueGenericsTests: PrettyPrintTestCase {
  func testValueGenericDeclaration() {
    let input = "struct Foo<let n: Int> { static let bar = n }"
    let expected = """
      struct Foo<
        let n: Int
      > {
        static let bar = n
      }

      """
    assertPrettyPrintEqual(
      input: input,
      expected: expected,
      linelength: 20,
      experimentalFeatures: [.valueGenerics]
    )
  }

  func testValueGenericTypeUsage() {
    let input =
      """
      let v1: Vector<100, Int>
      let v2 = Vector<100, Int>()
      """
    let expected = """
      let v1:
        Vector<
          100, Int
        >
      let v2 =
        Vector<
          100, Int
        >()

      """
    assertPrettyPrintEqual(
      input: input,
      expected: expected,
      linelength: 15,
      experimentalFeatures: [.valueGenerics]
    )
  }
}
