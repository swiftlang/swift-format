import SwiftFormatRules

final class NeverUseImplicitlyUnwrappedOptionalsTests: LintOrFormatRuleTestCase {
  func testInvalidVariableUnwrapping() {
    let input =
      """
      import Core
      import Foundation
      import SwiftSyntax

      var foo: Int?
      var s: String!
      var f: /*this is a Foo*/Foo!
      var c, d, e: Float
      @IBOutlet var button: UIButton!
      """
    performLint(NeverUseImplicitlyUnwrappedOptionals.self, input: input)
    XCTAssertNotDiagnosed(.doNotUseImplicitUnwrapping(identifier: "Int"))
    XCTAssertDiagnosed(.doNotUseImplicitUnwrapping(identifier: "String"))
    XCTAssertDiagnosed(.doNotUseImplicitUnwrapping(identifier: "Foo"))
    XCTAssertNotDiagnosed(.doNotUseImplicitUnwrapping(identifier: "Float"))
    XCTAssertNotDiagnosed(.doNotUseImplicitUnwrapping(identifier: "UIButton"))
  }

  func testIgnoreTestCode() {
    let input =
      """
      import XCTest

      var s: String!
      """
    performLint(NeverUseImplicitlyUnwrappedOptionals.self, input: input)
    XCTAssertNotDiagnosed(.doNotUseImplicitUnwrapping(identifier: "String"))
  }
}
