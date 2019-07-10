import Foundation
import SwiftSyntax
import XCTest

@testable import SwiftFormatRules

public class UseLetInEveryBoundCaseVariableTests: DiagnosingTestCase {
  public func testInvalidLetBoundCase() {
    let input =
      """
      switch DataPoint.labeled("hello", 100) {
      case let .labeled(label, value):
        break
      }

      switch DataPoint.labeled("hello", 100) {
      case .labeled(label, let value):
        break
      }

      switch DataPoint.labeled("hello", 100) {
      case .labeled(let label, let value):
        break
      }
      """
    performLint(UseLetInEveryBoundCaseVariable.self, input: input)
    XCTAssertDiagnosed(.useLetInBoundCaseVariables)
    XCTAssertNotDiagnosed(.useLetInBoundCaseVariables)
  }
}
