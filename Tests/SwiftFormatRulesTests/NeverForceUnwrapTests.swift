import Foundation
import SwiftSyntax
import XCTest

@testable import SwiftFormatRules

public class NeverForceUnwrapTests: DiagnosingTestCase {
  public func testUnsafeUnwrap() {
    let input =
    """
    func someFunc() -> Int {
      var a = getInt()
      var b = a as! Int
      let c = (someValue())!
      let d = String(a)!
      let regex = try! NSRegularExpression(pattern: "a*b+c?")
      return a!
    }
    """
    performLint(NeverForceUnwrap.self, input: input)
    XCTAssertDiagnosed(.doNotForceCast(name: "Int"))
    XCTAssertDiagnosed(.doNotForceUnwrap(name: "(someValue())"))
    XCTAssertDiagnosed(.doNotForceUnwrap(name: "String(a)"))
    XCTAssertNotDiagnosed(.doNotForceCast(name: "try"))
    XCTAssertNotDiagnosed(.doNotForceUnwrap(name: "try"))
    XCTAssertDiagnosed(.doNotForceUnwrap(name: "a"))
  }
  public func testIgnoreTestCode() {
    let input =
    """
      import XCTest

      var b = a as! Int
      """
    performLint(NeverUseImplicitlyUnwrappedOptionals.self, input: input)
    XCTAssertNotDiagnosed(.doNotForceCast(name: "Int"))
  }
}
