import Foundation
import SwiftSyntax
import XCTest

@testable import SwiftFormatRules

public class AlwaysUseLowerCamelCaseTests: DiagnosingTestCase {
  public func testInvalidVariableCasing() {
    let input =
      """
      let Test = 1
      var foo = 2
      var bad_name = 20
      var _okayName = 20
      struct Foo {
        func FooFunc() {}
      }
      """
    performLint(AlwaysUseLowerCamelCase.self, input: input)
    XCTAssertDiagnosed(.variableNameMustBeLowerCamelCase("Test"))
    XCTAssertNotDiagnosed(.variableNameMustBeLowerCamelCase("foo"))
    XCTAssertDiagnosed(.variableNameMustBeLowerCamelCase("bad_name"))
    XCTAssertNotDiagnosed(.variableNameMustBeLowerCamelCase("_okayName"))
    XCTAssertNotDiagnosed(.variableNameMustBeLowerCamelCase("Foo"))
    XCTAssertDiagnosed(.variableNameMustBeLowerCamelCase("FooFunc"))
  }
}
