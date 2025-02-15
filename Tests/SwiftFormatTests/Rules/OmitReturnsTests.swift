@_spi(Rules) import SwiftFormat
import _SwiftFormatTestSupport

final class OmitReturnsTests: LintOrFormatRuleTestCase {
  func testOmitReturnInFunction() {
    assertFormatting(
      OmitExplicitReturns.self,
      input: """
          func test() -> Bool {
            1️⃣return false
          }
        """,
      expected: """
          func test() -> Bool {
            false
          }
        """,
      findings: [
        FindingSpec(
          "1️⃣",
          message: "'return' can be omitted because body consists of a single expression",
          severity: .refactoring
        )
      ]
    )
  }

  func testOmitReturnInClosure() {
    assertFormatting(
      OmitExplicitReturns.self,
      input: """
          vals.filter {
            1️⃣return $0.count == 1
          }
        """,
      expected: """
          vals.filter {
            $0.count == 1
          }
        """,
      findings: [
        FindingSpec(
          "1️⃣",
          message: "'return' can be omitted because body consists of a single expression",
          severity: .refactoring
        )
      ]
    )
  }

  func testOmitReturnInSubscript() {
    assertFormatting(
      OmitExplicitReturns.self,
      input: """
          struct Test {
            subscript(x: Int) -> Bool {
              1️⃣return false
            }
          }

          struct Test {
            subscript(x: Int) -> Bool {
              get {
                2️⃣return false
              }
              set { }
            }
          }
        """,
      expected: """
          struct Test {
            subscript(x: Int) -> Bool {
              false
            }
          }

          struct Test {
            subscript(x: Int) -> Bool {
              get {
                false
              }
              set { }
            }
          }
        """,
      findings: [
        FindingSpec(
          "1️⃣",
          message: "'return' can be omitted because body consists of a single expression",
          severity: .refactoring
        ),
        FindingSpec(
          "2️⃣",
          message: "'return' can be omitted because body consists of a single expression",
          severity: .refactoring
        ),
      ]
    )
  }

  func testOmitReturnInComputedVars() {
    assertFormatting(
      OmitExplicitReturns.self,
      input: """
          var x: Int {
            1️⃣return 42
          }

          struct Test {
            var x: Int {
              get {
                2️⃣return 42
              }
              set { }
            }
          }
        """,
      expected: """
          var x: Int {
            42
          }

          struct Test {
            var x: Int {
              get {
                42
              }
              set { }
            }
          }
        """,
      findings: [
        FindingSpec(
          "1️⃣",
          message: "'return' can be omitted because body consists of a single expression",
          severity: .refactoring
        ),
        FindingSpec(
          "2️⃣",
          message: "'return' can be omitted because body consists of a single expression",
          severity: .refactoring
        ),
      ]
    )
  }
}
