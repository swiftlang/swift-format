@_spi(Rules) import SwiftFormat

final class OmitReturnsTests: LintOrFormatRuleTestCase {
  func testOmitReturnInFunction() {
    XCTAssertFormatting(
      OmitReturns.self,
      input: """
        func test() -> Bool {
          return false
        }
        """,
      expected: """
        func test() -> Bool {
          false
        }
        """)
  }
}
