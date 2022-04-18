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
      enum FooBarCases {
        case UpperCamelCase
        case lowerCamelCase
      }
      if let Baz = foo { }
      guard let foo = [1, 2, 3, 4].first(where: { BadName -> Bool in
        let TerribleName = BadName
        return TerribleName != 0
      }) else { return }
      var fooVar = [1, 2, 3, 4].first(where: { BadNameInFooVar -> Bool in
        let TerribleNameInFooVar = BadName
        return TerribleName != 0
      })
      var abc = array.first(where: { (CParam1, _ CParam2: Type, cparam3) -> Bool in return true })
      func wellNamedFunc(_ BadFuncArg1: Int, BadFuncArgLabel goodFuncArg: String) {
        var PoorlyNamedVar = 0
      }
      """
    performLint(AlwaysUseLowerCamelCase.self, input: input)
    XCTAssertDiagnosed(
      .nameMustBeLowerCamelCase("Test", description: "constant"), line: 1, column: 5)
    XCTAssertNotDiagnosed(.nameMustBeLowerCamelCase("foo", description: "variable"))
    XCTAssertDiagnosed(
      .nameMustBeLowerCamelCase("bad_name", description: "variable"), line: 3, column: 5)
    XCTAssertNotDiagnosed(.nameMustBeLowerCamelCase("_okayName", description: "variable"))
    XCTAssertNotDiagnosed(.nameMustBeLowerCamelCase("Foo", description: "struct"))
    XCTAssertDiagnosed(
      .nameMustBeLowerCamelCase("FooFunc", description: "function"), line: 6, column: 8)
    XCTAssertDiagnosed(
      .nameMustBeLowerCamelCase("test_HappyPath_Through_GoodCode", description: "function"),
      line: 9, column: 8)
    XCTAssertDiagnosed(
      .nameMustBeLowerCamelCase("UpperCamelCase", description: "enum case"), line: 12, column: 8)
    XCTAssertDiagnosed(
      .nameMustBeLowerCamelCase("Baz", description: "constant"), line: 15, column: 8)
    XCTAssertDiagnosed(
      .nameMustBeLowerCamelCase("BadName", description: "closure parameter"), line: 16, column: 45)
    XCTAssertDiagnosed(
      .nameMustBeLowerCamelCase("TerribleName", description: "constant"), line: 17, column: 7)
    XCTAssertDiagnosed(
      .nameMustBeLowerCamelCase("BadNameInFooVar", description: "closure parameter"),
      line: 20, column: 42)
    XCTAssertDiagnosed(
      .nameMustBeLowerCamelCase("TerribleNameInFooVar", description: "constant"),
      line: 21, column: 7)
    XCTAssertDiagnosed(
      .nameMustBeLowerCamelCase("CParam1", description: "closure parameter"), line: 24, column: 33)
    XCTAssertDiagnosed(
      .nameMustBeLowerCamelCase("CParam2", description: "closure parameter"), line: 24, column: 44)
    XCTAssertDiagnosed(
      .nameMustBeLowerCamelCase("BadFuncArg1", description: "function parameter"),
      line: 25, column: 22)
    XCTAssertDiagnosed(
      .nameMustBeLowerCamelCase("BadFuncArgLabel", description: "argument label"),
      line: 25, column: 40)
    XCTAssertDiagnosed(
      .nameMustBeLowerCamelCase("PoorlyNamedVar", description: "variable"), line: 26, column: 7)
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
    XCTAssertDiagnosed(
      .nameMustBeLowerCamelCase("Test", description: "constant"), line: 3, column: 5)
    XCTAssertDiagnosed(
      .nameMustBeLowerCamelCase("My_Constant_Value", description: "constant"), line: 5, column: 14)
    XCTAssertNotDiagnosed(
      .nameMustBeLowerCamelCase("test_HappyPath_Through_GoodCode", description: "function"))
    XCTAssertDiagnosed(
      .nameMustBeLowerCamelCase("FooFunc", description: "function"), line: 7, column: 16)
    XCTAssertDiagnosed(
      .nameMustBeLowerCamelCase("helperFunc_For_HappyPath_Setup", description: "function"),
      line: 8, column: 16)
    XCTAssertDiagnosed(
      .nameMustBeLowerCamelCase("testLikeMethod_With_Underscores", description: "function"),
      line: 9, column: 16)
    XCTAssertDiagnosed(
      .nameMustBeLowerCamelCase("testLikeMethod_With_Underscores2", description: "function"),
      line: 10, column: 16)
    XCTAssertNotDiagnosed(
      .nameMustBeLowerCamelCase(
        "test_HappyPath_Through_GoodCode_ReturnsVoid", description: "function"))
    XCTAssertNotDiagnosed(
      .nameMustBeLowerCamelCase(
        "test_HappyPath_Through_GoodCode_ReturnsShortVoid", description: "function"))
    XCTAssertNotDiagnosed(
      .nameMustBeLowerCamelCase("test_HappyPath_Through_GoodCode_Throws", description: "function"))
  }

  func testIgnoresFunctionOverrides() {
    let input =
      """
      class ParentClass {
        var poorly_named_variable: Int = 5
        func poorly_named_method() {}
      }

      class ChildClass: ParentClass {
        override var poorly_named_variable: Int = 5
        override func poorly_named_method() {}
      }
      """

    performLint(AlwaysUseLowerCamelCase.self, input: input)
    XCTAssertDiagnosed(
      .nameMustBeLowerCamelCase("poorly_named_variable", description: "variable"), line: 2, column: 7)
    XCTAssertDiagnosed(
      .nameMustBeLowerCamelCase("poorly_named_method", description: "function"), line: 3, column: 8)
  }
}
