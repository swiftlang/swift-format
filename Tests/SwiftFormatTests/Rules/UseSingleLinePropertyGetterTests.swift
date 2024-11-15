@_spi(Rules) import SwiftFormat
import _SwiftFormatTestSupport

final class UseSingleLinePropertyGetterTests: LintOrFormatRuleTestCase {
  func testMultiLinePropertyGetter() {
    assertFormatting(
      UseSingleLinePropertyGetter.self,
      input: """
        var g: Int { return 4 }
        var h: Int {
          1️⃣get {
            return 4
          }
        }
        var i: Int {
          get { return 0 }
          set { print("no set, only get") }
        }
        var j: Int {
          mutating get { return 0 }
        }
        var k: Int {
          get async {
            return 4
          }
        }
        var l: Int {
          get throws {
            return 4
          }
        }
        var m: Int {
          get async throws {
            return 4
          }
        }
        """,
      expected: """
        var g: Int { return 4 }
        var h: Int {
            return 4
        }
        var i: Int {
          get { return 0 }
          set { print("no set, only get") }
        }
        var j: Int {
          mutating get { return 0 }
        }
        var k: Int {
          get async {
            return 4
          }
        }
        var l: Int {
          get throws {
            return 4
          }
        }
        var m: Int {
          get async throws {
            return 4
          }
        }
        """,
      findings: [
        FindingSpec(
          "1️⃣",
          message: "remove 'get {...}' around the accessor and move its body directly into the computed property"
        )
      ]
    )
  }
}
