import Foundation
import SwiftSyntax
import XCTest

@testable import SwiftFormatRules

public class OneVariableDeclarationPerLineTests: DiagnosingTestCase {
  public func testMultipleVariableBindings() {
    XCTAssertFormatting(
      OneVariableDeclarationPerLine.self,
      input: """
             var a = 0, b = 2, (c, d) = (0, "h")
             let e = 0, f = 2, (g, h) = (0, "h")
             var x: Int { return 3 }
             """,
      expected: """
                var a = 0
                var b = 2
                var (c, d) = (0, "h")
                let e = 0
                let f = 2
                let (g, h) = (0, "h")
                var x: Int { return 3 }
                """)
  }

  public func testNestedVariableBindings() {
    XCTAssertFormatting(
      OneVariableDeclarationPerLine.self,
      input: """
             var x: Int = {
                 let y = 5, z = 10
                 return z
             }()

             foo() {
               let x = 4, y = 10
             }

             struct X {
               var x: Int {
                 let y = 5, z = 10
                 return z
               }
             }
             """,
      expected: """
                var x: Int = {
                    let y = 5
                    let z = 10
                    return z
                }()

                foo() {
                  let x = 4
                  let y = 10
                }

                struct X {
                  var x: Int {
                    let y = 5
                    let z = 10
                    return z
                  }
                }
                """
    )
  }
}
