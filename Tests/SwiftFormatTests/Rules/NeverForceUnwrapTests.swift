@_spi(Rules) import SwiftFormat
import _SwiftFormatTestSupport

final class NeverForceUnwrapTests: LintOrFormatRuleTestCase {
  func testUnsafeUnwrap() {
    assertLint(
      NeverForceUnwrap.self,
      """
      func someFunc() -> Int {
        var a = getInt()
        var b = 1️⃣a as! Int
        let c = 2️⃣(someValue())!
        let d = 3️⃣String(a)!
        let regex = try! NSRegularExpression(pattern: "a*b+c?")
        let e = /*comment about stuff*/ 4️⃣[1: a, 2: b, 3: c][4]!
        var f = 5️⃣a as! /*comment about this type*/ FooBarType
        return 6️⃣a!
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: "do not force cast to 'Int'"),
        FindingSpec("2️⃣", message: "do not force unwrap '(someValue())'"),
        FindingSpec("3️⃣", message: "do not force unwrap 'String(a)'"),
        FindingSpec("4️⃣", message: "do not force unwrap '[1: a, 2: b, 3: c][4]'"),
        FindingSpec("5️⃣", message: "do not force cast to 'FooBarType'"),
        FindingSpec("6️⃣", message: "do not force unwrap 'a'"),
      ]
    )
  }

  func testIgnoreTestCode() {
    assertLint(
      NeverForceUnwrap.self,
      """
      import XCTest

      var b = a as! Int
      """,
      findings: []
    )
  }

  func testIgnoreTestAttributeFunction() {
    assertLint(
      NeverForceUnwrap.self,
      """
      @Test
      func testSomeFunc() {
        var b = a as! Int
      }
      @Test
      func testAnotherFunc() {
        func nestedFunc() {
          let c = someValue()!
        }
      }
      """,
      findings: []
    )
  }
}
