import SwiftFormatRules

final class NoEmptyTrailingClosureParenthesesTests: LintOrFormatRuleTestCase {
  func testInvalidEmptyParenTrailingClosure() {
    XCTAssertFormatting(
      NoEmptyTrailingClosureParentheses.self,
      input: """
             func greetEnthusiastically(_ nameProvider: () -> String) {
               // ...
             }
             func greetApathetically(_ nameProvider: () -> String) {
               // ...
             }
             greetEnthusiastically() { "John" }
             greetApathetically { "not John" }
             func myfunc(cls: MyClass) {
               cls.myClosure { $0 }
             }
             func myfunc(cls: MyClass) {
               cls.myBadClosure() { $0 }
             }
             DispatchQueue.main.async() {
               greetEnthusiastically() { "John" }
               DispatchQueue.main.async() {
                 greetEnthusiastically() { "Willis" }
               }
             }
             DispatchQueue.global.async(inGroup: blah) {
               DispatchQueue.main.async() {
                 greetEnthusiastically() { "Willis" }
               }
               DispatchQueue.main.async {
                 greetEnthusiastically() { "Willis" }
               }
             }
             foo(bar() { baz })() { blah }
             """,
      expected: """
                func greetEnthusiastically(_ nameProvider: () -> String) {
                  // ...
                }
                func greetApathetically(_ nameProvider: () -> String) {
                  // ...
                }
                greetEnthusiastically { "John" }
                greetApathetically { "not John" }
                func myfunc(cls: MyClass) {
                  cls.myClosure { $0 }
                }
                func myfunc(cls: MyClass) {
                  cls.myBadClosure { $0 }
                }
                DispatchQueue.main.async {
                  greetEnthusiastically { "John" }
                  DispatchQueue.main.async {
                    greetEnthusiastically { "Willis" }
                  }
                }
                DispatchQueue.global.async(inGroup: blah) {
                  DispatchQueue.main.async {
                    greetEnthusiastically { "Willis" }
                  }
                  DispatchQueue.main.async {
                    greetEnthusiastically { "Willis" }
                  }
                }
                foo(bar { baz }) { blah }
                """,
      checkForUnassertedDiagnostics: true)
    XCTAssertDiagnosed(
      .removeEmptyTrailingParentheses(name: "greetEnthusiastically"), line: 7, column: 1)
    XCTAssertDiagnosed(.removeEmptyTrailingParentheses(name: "myBadClosure"), line: 13, column: 3)
    XCTAssertNotDiagnosed(.removeEmptyTrailingParentheses(name: "myClosure"))
    XCTAssertDiagnosed(.removeEmptyTrailingParentheses(name: "async"), line: 15, column: 1)
    XCTAssertDiagnosed(
      .removeEmptyTrailingParentheses(name: "greetEnthusiastically"), line: 16, column: 3)
    XCTAssertDiagnosed(.removeEmptyTrailingParentheses(name: "async"), line: 17, column: 3)
    XCTAssertDiagnosed(
      .removeEmptyTrailingParentheses(name: "greetEnthusiastically"), line: 18, column: 5)
    XCTAssertDiagnosed(.removeEmptyTrailingParentheses(name: "async"), line: 22, column: 3)
    XCTAssertDiagnosed(
      .removeEmptyTrailingParentheses(name: "greetEnthusiastically"), line: 23, column: 5)
    XCTAssertDiagnosed(
      .removeEmptyTrailingParentheses(name: "greetEnthusiastically"), line: 26, column: 5)
    XCTAssertDiagnosed(.removeEmptyTrailingParentheses(name: ")"), line: 29, column: 1)
    XCTAssertDiagnosed(.removeEmptyTrailingParentheses(name: "bar"), line: 29, column: 5)
  }
}
