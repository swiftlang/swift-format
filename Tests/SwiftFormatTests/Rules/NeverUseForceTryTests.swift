import SwiftFormatRules

final class NeverUseForceTryTests: LintOrFormatRuleTestCase {
  func testInvalidTryExpression() {
    let input =
      """
      let document = try! Document(path: "important.data")
      let document = try Document(path: "important.data")
      let x = try! someThrowingFunction()
      let x = try? someThrowingFunction(
        try! someThrowingFunction()
      )
      let x = try someThrowingFunction(
        try! someThrowingFunction()
      )
      if let data = try? fetchDataFromDisk() { return data }
      """
    performLint(NeverUseForceTry.self, input: input)
    XCTAssertDiagnosed(.doNotForceTry)
    XCTAssertDiagnosed(.doNotForceTry)
    XCTAssertDiagnosed(.doNotForceTry)
    XCTAssertDiagnosed(.doNotForceTry)
    XCTAssertNotDiagnosed(.doNotForceTry)
  }

  func testAllowForceTryInTestCode() {
    let input =
      """
      import XCTest

      let document = try! Document(path: "important.data")
      """
    performLint(NeverUseForceTry.self, input: input)
    XCTAssertNotDiagnosed(.doNotForceTry)
  }
}
