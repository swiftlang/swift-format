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

  func testOmitReturnInSubscript() {
      XCTAssertFormatting(
        OmitReturns.self,
        input: """
          struct Test {
            subscript(x: Int) -> Bool {
              return false
            }
          }
          """,
        expected: """
          struct Test {
            subscript(x: Int) -> Bool {
              false
            }
          }
          """)

      XCTAssertFormatting(
        OmitReturns.self,
        input: """
          struct Test {
            subscript(x: Int) -> Bool {
              get {
                return false
              }
              set { }
            }
          }
          """,
        expected: """
          struct Test {
            subscript(x: Int) -> Bool {
              get {
                false
              }
              set { }
            }
          }
          """)
  }

  func testOmitReturnInComputedVars() {
    XCTAssertFormatting(
      OmitReturns.self,
      input: """
        var x: Int {
          return 42
        }
        """,
      expected: """
        var x: Int {
          42
        }
        """)

    XCTAssertFormatting(
      OmitReturns.self,
      input: """
        struct Test {
          var x: Int {
            get {
              return 42
            }
            set { }
          }
        }
        """,
      expected: """
        struct Test {
          var x: Int {
            get {
              42
            }
            set { }
          }
        }
        """)
  }
}
