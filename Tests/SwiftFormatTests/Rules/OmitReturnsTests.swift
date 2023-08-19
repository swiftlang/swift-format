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

  func testOmitReturnInClosure() {
    XCTAssertFormatting(
      OmitReturns.self,
      input: """
        vals.filter {
          return $0.count == 1
        }
        """,
      expected: """
        vals.filter {
          $0.count == 1
        }
        """)
  }
}
