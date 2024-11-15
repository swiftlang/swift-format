@_spi(Rules) import SwiftFormat
import _SwiftFormatTestSupport

final class NoVoidReturnOnFunctionSignatureTests: LintOrFormatRuleTestCase {
  func testVoidReturns() {
    assertFormatting(
      NoVoidReturnOnFunctionSignature.self,
      input: """
        func foo() -> 1️⃣() {
        }

        func test() -> 2️⃣Void{
        }

        func x() -> Int { return 2 }

        let x = { () -> Void in
          print("Hello, world!")
        }
        """,
      expected: """
        func foo() {
        }

        func test() {
        }

        func x() -> Int { return 2 }

        let x = { () -> Void in
          print("Hello, world!")
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove the explicit return type '()' from this function"),
        FindingSpec("2️⃣", message: "remove the explicit return type 'Void' from this function"),
      ]
    )
  }
}
