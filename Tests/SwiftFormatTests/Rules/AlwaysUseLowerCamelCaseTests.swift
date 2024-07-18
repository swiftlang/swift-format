import _SwiftFormatTestSupport

@_spi(Rules) import SwiftFormat

final class AlwaysUseLowerCamelCaseTests: LintOrFormatRuleTestCase {
  func testInvalidVariableCasing() {
    assertLint(
      AlwaysUseLowerCamelCase.self,
      """
      let 1️⃣Test = 1
      var foo = 2
      var 2️⃣bad_name = 20
      var _okayName = 20
      if let 3️⃣Baz = foo { }
      """,
      findings: [
        FindingSpec("1️⃣", message: "rename the constant 'Test' using lowerCamelCase"),
        FindingSpec("2️⃣", message: "rename the variable 'bad_name' using lowerCamelCase"),
        FindingSpec("3️⃣", message: "rename the constant 'Baz' using lowerCamelCase"),
      ]
    )
  }

  func testInvalidFunctionCasing() {
    assertLint(
      AlwaysUseLowerCamelCase.self,
      """
      struct Foo {
        func 1️⃣FooFunc() {}
      }
      class UnitTests: XCTestCase {
        // This is flagged because XCTest is not imported.
        func 2️⃣test_HappyPath_Through_GoodCode() {}
      }
      func wellNamedFunc(_ 3️⃣BadFuncArg1: Int, 4️⃣BadFuncArgLabel goodFuncArg: String) {
        var 5️⃣PoorlyNamedVar = 0
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: "rename the function 'FooFunc' using lowerCamelCase"),
        FindingSpec("2️⃣", message: "rename the function 'test_HappyPath_Through_GoodCode' using lowerCamelCase"),
        FindingSpec("3️⃣", message: "rename the function parameter 'BadFuncArg1' using lowerCamelCase"),
        FindingSpec("4️⃣", message: "rename the argument label 'BadFuncArgLabel' using lowerCamelCase"),
        FindingSpec("5️⃣", message: "rename the variable 'PoorlyNamedVar' using lowerCamelCase"),
      ]
    )

  }

  func testInvalidEnumCaseCasing() {
    assertLint(
      AlwaysUseLowerCamelCase.self,
      """
      enum FooBarCases {
        case 1️⃣UpperCamelCase
        case lowerCamelCase
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: "rename the enum case 'UpperCamelCase' using lowerCamelCase"),
      ]
    )

  }

  func testInvalidClosureCasing() {
    assertLint(
      AlwaysUseLowerCamelCase.self,
      """
      var fooVar = [1, 2, 3, 4].first(where: { 1️⃣BadNameInFooVar -> Bool in
        let 2️⃣TerribleNameInFooVar = BadName
        return TerribleName != 0
      })
      var abc = array.first(where: { (3️⃣CParam1, _ 4️⃣CParam2: Type, cparam3) -> Bool in return true })
      guard let foo = [1, 2, 3, 4].first(where: { 5️⃣BadName -> Bool in
        let 6️⃣TerribleName = BadName
        return TerribleName != 0
      }) else { return }
      """,
      findings: [
        FindingSpec("1️⃣", message: "rename the closure parameter 'BadNameInFooVar' using lowerCamelCase"),
        FindingSpec("2️⃣", message: "rename the constant 'TerribleNameInFooVar' using lowerCamelCase"),
        FindingSpec("3️⃣", message: "rename the closure parameter 'CParam1' using lowerCamelCase"),
        FindingSpec("4️⃣", message: "rename the closure parameter 'CParam2' using lowerCamelCase"),
        FindingSpec("5️⃣", message: "rename the closure parameter 'BadName' using lowerCamelCase"),
        FindingSpec("6️⃣", message: "rename the constant 'TerribleName' using lowerCamelCase"),
      ]
    )
  }

  func testIgnoresUnderscoresInTestNames() {
    assertLint(
      AlwaysUseLowerCamelCase.self,
      """
      import XCTest

      let 1️⃣Test = 1
      class UnitTests: XCTestCase {
        static let 2️⃣My_Constant_Value = 0
        func test_HappyPath_Through_GoodCode() {}
        private func 3️⃣FooFunc() {}
        private func 4️⃣helperFunc_For_HappyPath_Setup() {}
        private func 5️⃣testLikeMethod_With_Underscores(_ arg1: ParamType) {}
        private func 6️⃣testLikeMethod_With_Underscores2() -> ReturnType {}
        func test_HappyPath_Through_GoodCode_ReturnsVoid() -> Void {}
        func test_HappyPath_Through_GoodCode_ReturnsShortVoid() -> () {}
        func test_HappyPath_Through_GoodCode_Throws() throws {}
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: "rename the constant 'Test' using lowerCamelCase"),
        FindingSpec("2️⃣", message: "rename the constant 'My_Constant_Value' using lowerCamelCase"),
        FindingSpec("3️⃣", message: "rename the function 'FooFunc' using lowerCamelCase"),
        FindingSpec("4️⃣", message: "rename the function 'helperFunc_For_HappyPath_Setup' using lowerCamelCase"),
        FindingSpec("5️⃣", message: "rename the function 'testLikeMethod_With_Underscores' using lowerCamelCase"),
        FindingSpec("6️⃣", message: "rename the function 'testLikeMethod_With_Underscores2' using lowerCamelCase"),
      ]
    )
  }

  func testIgnoresUnderscoresInTestNamesWhenImportedConditionally() {
    assertLint(
      AlwaysUseLowerCamelCase.self,
      """
      #if SOME_FEATURE_FLAG
        import XCTest

        let 1️⃣Test = 1
        class UnitTests: XCTestCase {
          static let 2️⃣My_Constant_Value = 0
          func test_HappyPath_Through_GoodCode() {}
          private func 3️⃣FooFunc() {}
          private func 4️⃣helperFunc_For_HappyPath_Setup() {}
          private func 5️⃣testLikeMethod_With_Underscores(_ arg1: ParamType) {}
          private func 6️⃣testLikeMethod_With_Underscores2() -> ReturnType {}
          func test_HappyPath_Through_GoodCode_ReturnsVoid() -> Void {}
          func test_HappyPath_Through_GoodCode_ReturnsShortVoid() -> () {}
          func test_HappyPath_Through_GoodCode_Throws() throws {}
        }
      #endif
      """,
      findings: [
        FindingSpec("1️⃣", message: "rename the constant 'Test' using lowerCamelCase"),
        FindingSpec("2️⃣", message: "rename the constant 'My_Constant_Value' using lowerCamelCase"),
        FindingSpec("3️⃣", message: "rename the function 'FooFunc' using lowerCamelCase"),
        FindingSpec("4️⃣", message: "rename the function 'helperFunc_For_HappyPath_Setup' using lowerCamelCase"),
        FindingSpec("5️⃣", message: "rename the function 'testLikeMethod_With_Underscores' using lowerCamelCase"),
        FindingSpec("6️⃣", message: "rename the function 'testLikeMethod_With_Underscores2' using lowerCamelCase"),
      ]
    )
  }

  func testIgnoresUnderscoresInConditionalTestNames() {
    assertLint(
      AlwaysUseLowerCamelCase.self,
      """
      import XCTest

      class UnitTests: XCTestCase {
        #if SOME_FEATURE_FLAG
          static let 1️⃣My_Constant_Value = 0
          func test_HappyPath_Through_GoodCode() {}
          private func 2️⃣FooFunc() {}
          private func 3️⃣helperFunc_For_HappyPath_Setup() {}
          private func 4️⃣testLikeMethod_With_Underscores(_ arg1: ParamType) {}
          private func 5️⃣testLikeMethod_With_Underscores2() -> ReturnType {}
          func test_HappyPath_Through_GoodCode_ReturnsVoid() -> Void {}
          func test_HappyPath_Through_GoodCode_ReturnsShortVoid() -> () {}
          func test_HappyPath_Through_GoodCode_Throws() throws {}
        #else
          func 6️⃣testBadMethod_HasNonVoidReturn() -> ReturnType {}
          func testGoodMethod_HasVoidReturn() {}
          #if SOME_OTHER_FEATURE_FLAG
            func 7️⃣testBadMethod_HasNonVoidReturn2() -> ReturnType {}
            func testGoodMethod_HasVoidReturn2() {}
          #endif
        #endif
      }
      #endif
      """,
      findings: [
        FindingSpec("1️⃣", message: "rename the constant 'My_Constant_Value' using lowerCamelCase"),
        FindingSpec("2️⃣", message: "rename the function 'FooFunc' using lowerCamelCase"),
        FindingSpec("3️⃣", message: "rename the function 'helperFunc_For_HappyPath_Setup' using lowerCamelCase"),
        FindingSpec("4️⃣", message: "rename the function 'testLikeMethod_With_Underscores' using lowerCamelCase"),
        FindingSpec("5️⃣", message: "rename the function 'testLikeMethod_With_Underscores2' using lowerCamelCase"),
        FindingSpec("6️⃣", message: "rename the function 'testBadMethod_HasNonVoidReturn' using lowerCamelCase"),
        FindingSpec("7️⃣", message: "rename the function 'testBadMethod_HasNonVoidReturn2' using lowerCamelCase"),
      ]
    )
  }

  func testIgnoresFunctionOverrides() {
    assertLint(
      AlwaysUseLowerCamelCase.self,
      """
      class ParentClass {
        var 1️⃣poorly_named_variable: Int = 5
        func 2️⃣poorly_named_method() {}
      }

      class ChildClass: ParentClass {
        override var poorly_named_variable: Int = 5
        override func poorly_named_method() {}
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: "rename the variable 'poorly_named_variable' using lowerCamelCase"),
        FindingSpec("2️⃣", message: "rename the function 'poorly_named_method' using lowerCamelCase"),
      ]
    )
  }

  func testIgnoresFunctionsWithTestAttributes() {
    assertLint(
      AlwaysUseLowerCamelCase.self,
      """
      @Test
      func function_With_Test_Attribute() {}
      @Testing.Test("Description for test functions",
            .tags(.testTag))
      func function_With_Test_Attribute_And_Args() {}
      func 1️⃣function_Without_Test_Attribute() {}
      @objc
      func 2️⃣function_With_Non_Test_Attribute() {}
      @Foo.Test
      func 3️⃣function_With_Test_Attribute_From_Foo_Module() {}
      """,
      findings: [
        FindingSpec("1️⃣", message: "rename the function 'function_Without_Test_Attribute' using lowerCamelCase"),
        FindingSpec("2️⃣", message: "rename the function 'function_With_Non_Test_Attribute' using lowerCamelCase"),
        FindingSpec("3️⃣", message: "rename the function 'function_With_Test_Attribute_From_Foo_Module' using lowerCamelCase"),
      ]
    )
  }
}
