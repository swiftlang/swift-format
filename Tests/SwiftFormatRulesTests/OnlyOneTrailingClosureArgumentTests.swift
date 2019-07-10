import Foundation
import SwiftSyntax
import XCTest

@testable import SwiftFormatRules

public class OnlyOneTrailingClosureArgumentTests: DiagnosingTestCase {
  public func testInvalidTrailingClosureCall() {
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
