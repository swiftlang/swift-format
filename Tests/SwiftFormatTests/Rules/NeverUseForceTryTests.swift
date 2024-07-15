import _SwiftFormatTestSupport

@_spi(Rules) import SwiftFormat

final class NeverUseForceTryTests: LintOrFormatRuleTestCase {
  func testInvalidTryExpression() {
    assertLint(
      NeverUseForceTry.self,
      """
      let document = 1️⃣try! Document(path: "important.data")
      let document = try Document(path: "important.data")
      let x = 2️⃣try! someThrowingFunction()
      let x = try? someThrowingFunction(
        3️⃣try! someThrowingFunction()
      )
      let x = try someThrowingFunction(
        4️⃣try! someThrowingFunction()
      )
      if let data = try? fetchDataFromDisk() { return data }
      """,
      findings: [
        FindingSpec("1️⃣", message: "do not use force try"),
        FindingSpec("2️⃣", message: "do not use force try"),
        FindingSpec("3️⃣", message: "do not use force try"),
        FindingSpec("4️⃣", message: "do not use force try"),
      ]
    )
  }

  func testAllowForceTryInTestCode() {
    assertLint(
      NeverUseForceTry.self,
      """
      import XCTest

      let document = try! Document(path: "important.data")
      """,
      findings: []
    )
  }
  
  func testAllowForceTryInTestAttributeFunction() {
    assertLint(
      NeverUseForceTry.self,
      """
      @Test
      func testSomeFunc() {
        let document = try! Document(path: "important.data")
        func nestedFunc() {
          let x = try! someThrowingFunction()
        }
      }
      """,
      findings: []
    )
  }
}
