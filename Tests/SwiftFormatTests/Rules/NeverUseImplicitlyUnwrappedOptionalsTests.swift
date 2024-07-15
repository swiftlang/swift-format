import _SwiftFormatTestSupport

@_spi(Rules) import SwiftFormat

final class NeverUseImplicitlyUnwrappedOptionalsTests: LintOrFormatRuleTestCase {
  func testInvalidVariableUnwrapping() {
    assertLint(
      NeverUseImplicitlyUnwrappedOptionals.self,
      """
      import Core
      import Foundation
      import SwiftSyntax

      var foo: Int?
      var s: 1️⃣String!
      var f: /*this is a Foo*/2️⃣Foo!
      var c, d, e: Float
      @IBOutlet var button: UIButton!
      """,
      findings: [
        FindingSpec("1️⃣", message: "use 'String' or 'String?' instead of 'String!'"),
        FindingSpec("2️⃣", message: "use 'Foo' or 'Foo?' instead of 'Foo!'"),
      ]
    )
  }

  func testIgnoreTestCode() {
    assertLint(
      NeverUseImplicitlyUnwrappedOptionals.self,
      """
      import XCTest

      var s: String!
      """,
      findings: []
    )
  }

  func testIgnoreTestAttrinuteFunction() {
    assertLint(
      NeverUseImplicitlyUnwrappedOptionals.self,
      """
      @Test
      func testSomeFunc() {
        var s: String!
        func nestedFunc() {
          var f: Foo!
        }
      }
      """,
      findings: []
    )
  }
}
