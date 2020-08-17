import SwiftFormatRules

final class AlwaysUseLowerCamelCaseTests: LintOrFormatRuleTestCase {
  override func setUp() {
    super.setUp()
    shouldCheckForUnassertedDiagnostics = true
  }

  func testInvalidVariableCasing() {
    let input =
      """
      let Test = 1
      var foo = 2
      var bad_name = 20
      var _okayName = 20
      struct Foo {
        func FooFunc() {}
      }
      class UnitTests: XCTestCase {
        func test_HappyPath_Through_GoodCode() {}
      }
      """
    performLint(AlwaysUseLowerCamelCase.self, input: input)
    XCTAssertDiagnosed(.variableNameMustBeLowerCamelCase("Test"), line: 1, column: 5)
    XCTAssertNotDiagnosed(.variableNameMustBeLowerCamelCase("foo"))
    XCTAssertDiagnosed(.variableNameMustBeLowerCamelCase("bad_name"), line: 3, column: 5)
    XCTAssertNotDiagnosed(.variableNameMustBeLowerCamelCase("_okayName"))
    XCTAssertNotDiagnosed(.variableNameMustBeLowerCamelCase("Foo"))
    XCTAssertDiagnosed(.variableNameMustBeLowerCamelCase("FooFunc"), line: 6, column: 8)
    XCTAssertDiagnosed(
      .variableNameMustBeLowerCamelCase("test_HappyPath_Through_GoodCode"), line: 9, column: 8)
  }

  func testIgnoresUnderscoresInTestNames() {
    let input =
      """
      import XCTest

      let Test = 1
      class UnitTests: XCTestCase {
        static let My_Constant_Value = 0
        func test_HappyPath_Through_GoodCode() {}
        private func FooFunc() {}
        private func helperFunc_For_HappyPath_Setup() {}
        private func testLikeMethod_With_Underscores(_ arg1: ParamType) {}
        private func testLikeMethod_With_Underscores2() -> ReturnType {}
        func test_HappyPath_Through_GoodCode_ReturnsVoid() -> Void {}
        func test_HappyPath_Through_GoodCode_ReturnsShortVoid() -> () {}
        func test_HappyPath_Through_GoodCode_Throws() throws {}
      }
      """
    performLint(AlwaysUseLowerCamelCase.self, input: input)
    XCTAssertDiagnosed(.variableNameMustBeLowerCamelCase("Test"), line: 3, column: 5)
    XCTAssertDiagnosed(.variableNameMustBeLowerCamelCase("My_Constant_Value"), line: 5, column: 14)
    XCTAssertNotDiagnosed(.variableNameMustBeLowerCamelCase("test_HappyPath_Through_GoodCode"))
    XCTAssertDiagnosed(.variableNameMustBeLowerCamelCase("FooFunc"), line: 7, column: 16)
    XCTAssertDiagnosed(
      .variableNameMustBeLowerCamelCase("helperFunc_For_HappyPath_Setup"), line: 8, column: 16)
    XCTAssertDiagnosed(
      .variableNameMustBeLowerCamelCase("testLikeMethod_With_Underscores"), line: 9, column: 16)
    XCTAssertDiagnosed(
      .variableNameMustBeLowerCamelCase("testLikeMethod_With_Underscores2"), line: 10, column: 16)
    XCTAssertNotDiagnosed(
      .variableNameMustBeLowerCamelCase("test_HappyPath_Through_GoodCode_ReturnsVoid"))
    XCTAssertNotDiagnosed(
      .variableNameMustBeLowerCamelCase("test_HappyPath_Through_GoodCode_ReturnsShortVoid"))
    XCTAssertNotDiagnosed(
      .variableNameMustBeLowerCamelCase("test_HappyPath_Through_GoodCode_Throws"))
  }
}
