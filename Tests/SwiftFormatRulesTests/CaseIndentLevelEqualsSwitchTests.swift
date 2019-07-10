import XCTest

@testable import SwiftFormatRules

public class CaseIndentLevelEqualsSwitchTests: DiagnosingTestCase {
  public func testsInvalidCaseIndent() {
    let input =
      """
      switch order {

      case .ascending:
        print("Ascending")
                   case .descending:
        print("Descending")
         case .same:
        print("Same")
      }
      """

    performLint(CaseIndentLevelEqualsSwitch.self, input: input)
    XCTAssertDiagnosed(.adjustCaseIndentation(by: -13))
    XCTAssertDiagnosed(.adjustCaseIndentation(by: -3))
  }
  
  public func testInvalidNestedCaseIndent() {
    let input =
      """
      if true {
        switch order {
      case .ascending:
          print("Ascending")
                   case .descending:
          print("Descending")
         case .same:
          print("Same")
        }
      }
      """

    performLint(CaseIndentLevelEqualsSwitch.self, input: input)
    XCTAssertDiagnosed(.adjustCaseIndentation(by: 2))
    XCTAssertDiagnosed(.adjustCaseIndentation(by: -11))
    XCTAssertDiagnosed(.adjustCaseIndentation(by: -1))
  }
  
  public func testInvalidNestedSwitchIndent() {
    let input =
      """
      switch foo {
        case .bar:
        switch order {
      case .ascending:
          print("Ascending")
                   case .descending:
          print("Descending")
         case .same:
          print("Same")
        }
      }
      """

    performLint(CaseIndentLevelEqualsSwitch.self, input: input)
    XCTAssertDiagnosed(.adjustCaseIndentation(by: -2))
    XCTAssertDiagnosed(.adjustCaseIndentation(by: 2))
    XCTAssertDiagnosed(.adjustCaseIndentation(by: -11))
    XCTAssertDiagnosed(.adjustCaseIndentation(by: -1))
  }
}
