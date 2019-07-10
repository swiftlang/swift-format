import Foundation
import SwiftSyntax
import XCTest

@testable import SwiftFormatRules

public class NoVoidReturnOnFunctionSignatureTests: DiagnosingTestCase {
  public func testVoidReturns() {
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
