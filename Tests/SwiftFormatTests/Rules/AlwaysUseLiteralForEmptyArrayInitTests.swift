import _SwiftFormatTestSupport

@_spi(Rules) import SwiftFormat

final class AlwaysUseLiteralForEmptyArrayInitTests: LintOrFormatRuleTestCase {
  func testPatternBindings() {
    assertFormatting(
      AlwaysUseLiteralForEmptyArrayInit.self,
      input: """
        public struct Test {
          var value1 = 1️⃣[Int]()

          func test(v: [Double] = [Double]()) {
            let _ = 2️⃣[String]()
          }
        }

        var _: [Category<Int>] = 3️⃣[Category<Int>]()
        let _ = 4️⃣[(Int, Array<String>)]()
        let _: [(String, Int, Float)] = 5️⃣[(String, Int, Float)]()

        let _ = [(1, 2, String)]()
        """,
      expected: """
        public struct Test {
          var value1: [Int] = []

          func test(v: [Double] = [Double]()) {
            let _: [String] = []
          }
        }

        var _: [Category<Int>] = []
        let _: [(Int, Array<String>)] = []
        let _: [(String, Int, Float)] = []

        let _ = [(1, 2, String)]()
        """,
      findings: [
        FindingSpec("1️⃣", message: "replace '[Int]()' with ': [Int] = []'"),
        FindingSpec("2️⃣", message: "replace '[String]()' with ': [String] = []'"),
        FindingSpec("3️⃣", message: "replace '[Category<Int>]()' with '[]'"),
        FindingSpec("4️⃣", message: "replace '[(Int, Array<String>)]()' with ': [(Int, Array<String>)] = []'"),
        FindingSpec("5️⃣", message: "replace '[(String, Int, Float)]()' with '[]'"),
      ]
    )
  }
}
