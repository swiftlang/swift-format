import _SwiftFormatTestSupport

@_spi(Rules) import SwiftFormat

final class AlwaysUseLiteralForEmptyCollectionInitTests: LintOrFormatRuleTestCase {
  func testArray() {
    assertFormatting(
      AlwaysUseLiteralForEmptyCollectionInit.self,
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

  func testDictionary() {
    assertFormatting(
      AlwaysUseLiteralForEmptyCollectionInit.self,
      input: """
        public struct Test {
          var value1 = 1️⃣[Int: String]()

          func test(v: [Double: Int] = [Double: Int]()) {
            let _ = 2️⃣[String: Int]()
          }
        }

        var _: [Category<Int>: String] = 3️⃣[Category<Int>: String]()
        let _ = 4️⃣[(Int, Array<String>): Int]()
        let _: [String: (String, Int, Float)] = 5️⃣[String: (String, Int, Float)]()

        let _ = [String: (1, 2, String)]()
        """,
      expected: """
        public struct Test {
          var value1: [Int: String] = [:]

          func test(v: [Double: Int] = [Double: Int]()) {
            let _: [String: Int] = [:]
          }
        }

        var _: [Category<Int>: String] = [:]
        let _: [(Int, Array<String>): Int] = [:]
        let _: [String: (String, Int, Float)] = [:]

        let _ = [String: (1, 2, String)]()
        """,
      findings: [
        FindingSpec("1️⃣", message: "replace '[Int: String]()' with ': [Int: String] = [:]'"),
        FindingSpec("2️⃣", message: "replace '[String: Int]()' with ': [String: Int] = [:]'"),
        FindingSpec("3️⃣", message: "replace '[Category<Int>: String]()' with '[:]'"),
        FindingSpec("4️⃣", message: "replace '[(Int, Array<String>): Int]()' with ': [(Int, Array<String>): Int] = [:]'"),
        FindingSpec("5️⃣", message: "replace '[String: (String, Int, Float)]()' with '[:]'"),
      ]
    )
  }
}
