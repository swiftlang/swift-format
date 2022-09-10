import SwiftFormatRules

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
    XCTAssertDiagnosed(.doNotForceUnwrap(name: "(someValue())"))
    XCTAssertDiagnosed(.doNotForceUnwrap(name: "String(a)"))
    XCTAssertNotDiagnosed(.doNotForceCast(name: "try"))
    XCTAssertNotDiagnosed(.doNotForceUnwrap(name: "try"))
    XCTAssertDiagnosed(.doNotForceUnwrap(name: "a"))
    XCTAssertDiagnosed(.doNotForceUnwrap(name: "[1: a, 2: b, 3: c][4]"))
    // FIXME: These diagnostics will be emitted once NeverForceUnwrap is taught
    // how to interpret Unresolved* components in sequence expressions.
//    XCTAssertDiagnosed(.doNotForceCast(name: "Int"))
//    XCTAssertDiagnosed(.doNotForceCast(name: "FooBarType"))
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
