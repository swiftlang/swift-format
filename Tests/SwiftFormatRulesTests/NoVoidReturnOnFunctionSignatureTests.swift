import SwiftFormatRules

final class NoVoidReturnOnFunctionSignatureTests: LintOrFormatRuleTestCase {
  func testVoidReturns() {
    XCTAssertFormatting(
      NoVoidReturnOnFunctionSignature.self,
      input: """
             func foo() -> () {
             }

             func test() -> Void{
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
                """)
  }
}
