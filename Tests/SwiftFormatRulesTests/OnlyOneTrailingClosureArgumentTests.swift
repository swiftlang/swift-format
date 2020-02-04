import SwiftFormatRules

final class OnlyOneTrailingClosureArgumentTests: LintOrFormatRuleTestCase {
  func testInvalidTrailingClosureCall() {
    let input =
      """
      callWithBoth(someClosure: {}) {
        // ...
      }
      callWithClosure(someClosure: {})
      callWithTrailingClosure {
        // ...
      }
      """
    performLint(OnlyOneTrailingClosureArgument.self, input: input)
    XCTAssertDiagnosed(.removeTrailingClosure)
    XCTAssertNotDiagnosed(.removeTrailingClosure)
    XCTAssertNotDiagnosed(.removeTrailingClosure)
  }
}
