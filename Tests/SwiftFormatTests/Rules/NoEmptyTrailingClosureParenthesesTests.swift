import _SwiftFormatTestSupport

@_spi(Rules) import SwiftFormat

// FIXME: Why not emit the finding at the very parentheses we want the user to remove?
final class NoEmptyTrailingClosureParenthesesTests: LintOrFormatRuleTestCase {
  func testInvalidEmptyParenTrailingClosure() {
    assertFormatting(
      NoEmptyTrailingClosureParentheses.self,
      input: """
        func greetEnthusiastically(_ nameProvider: () -> String) {
          // ...
        }
        func greetApathetically(_ nameProvider: () -> String) {
          // ...
        }
        0️⃣greetEnthusiastically() { "John" }
        greetApathetically { "not John" }
        func myfunc(cls: MyClass) {
          cls.myClosure { $0 }
        }
        func myfunc(cls: MyClass) {
          1️⃣cls.myBadClosure() { $0 }
        }
        2️⃣DispatchQueue.main.async() {
          3️⃣greetEnthusiastically() { "John" }
          4️⃣DispatchQueue.main.async() {
            5️⃣greetEnthusiastically() { "Willis" }
          }
        }
        DispatchQueue.global.async(inGroup: blah) {
          6️⃣DispatchQueue.main.async() {
            7️⃣greetEnthusiastically() { "Willis" }
          }
          DispatchQueue.main.async {
            8️⃣greetEnthusiastically() { "Willis" }
          }
        }
        9️⃣foo(🔟bar() { baz })() { blah }
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
      findings: [
        FindingSpec("0️⃣", message: "remove the empty parentheses following 'greetEnthusiastically'"),
        FindingSpec("1️⃣", message: "remove the empty parentheses following 'myBadClosure'"),
        FindingSpec("2️⃣", message: "remove the empty parentheses following 'async'"),
        FindingSpec("3️⃣", message: "remove the empty parentheses following 'greetEnthusiastically'"),
        FindingSpec("4️⃣", message: "remove the empty parentheses following 'async'"),
        FindingSpec("5️⃣", message: "remove the empty parentheses following 'greetEnthusiastically'"),
        FindingSpec("6️⃣", message: "remove the empty parentheses following 'async'"),
        FindingSpec("7️⃣", message: "remove the empty parentheses following 'greetEnthusiastically'"),
        FindingSpec("8️⃣", message: "remove the empty parentheses following 'greetEnthusiastically'"),
        FindingSpec("9️⃣", message: "remove the empty parentheses following ')'"),
        FindingSpec("🔟", message: "remove the empty parentheses following 'bar'"),
      ]
    )
  }
}
