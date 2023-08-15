import SwiftFormat

final class NeverForceUnwrapTests: LintOrFormatRuleTestCase {
  func testUnsafeUnwrap() {
    let input =
    """
    func someFunc() -> Int {
      var a = getInt()
      var b = a as! Int
      let c = (someValue())!
      let d = String(a)!
      let regex = try! NSRegularExpression(pattern: "a*b+c?")
      let e = /*comment about stuff*/ [1: a, 2: b, 3: c][4]!
      var f = a as! /*comment about this type*/ FooBarType
      return a!
    }
    """
    performLint(NeverForceUnwrap.self, input: input)
    XCTAssertDiagnosed(.doNotForceCast(name: "Int"), line: 3, column: 11)
    XCTAssertDiagnosed(.doNotForceUnwrap(name: "(someValue())"), line: 4, column: 11)
    XCTAssertDiagnosed(.doNotForceUnwrap(name: "String(a)"), line: 5, column: 11)
    XCTAssertNotDiagnosed(.doNotForceCast(name: "try"))
    XCTAssertNotDiagnosed(.doNotForceUnwrap(name: "try"))
    XCTAssertDiagnosed(.doNotForceUnwrap(name: "[1: a, 2: b, 3: c][4]"), line: 7, column: 35)
    XCTAssertDiagnosed(.doNotForceCast(name: "FooBarType"), line: 8, column: 11)
    XCTAssertDiagnosed(.doNotForceUnwrap(name: "a"), line: 9, column: 10)
  }

  func testIgnoreTestCode() {
    let input =
    """
      import XCTest

      var b = a as! Int
      """
    performLint(NeverUseImplicitlyUnwrappedOptionals.self, input: input)
    XCTAssertNotDiagnosed(.doNotForceCast(name: "Int"))
  }
}
