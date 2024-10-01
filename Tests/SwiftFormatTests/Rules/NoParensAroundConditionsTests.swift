@_spi(Rules) import SwiftFormat
import _SwiftFormatTestSupport

final class NoParensAroundConditionsTests: LintOrFormatRuleTestCase {
  func testParensAroundConditions() {
    assertFormatting(
      NoParensAroundConditions.self,
      input: """
        if 1️⃣(x) {}
        while 2️⃣(x) {}
        guard 3️⃣(x), 4️⃣(y), 5️⃣(x == 3) else {}
        if (foo { x }) {}
        repeat {} while6️⃣(x)
        switch 7️⃣(4) { default: break }
        """,
      expected: """
        if x {}
        while x {}
        guard x, y, x == 3 else {}
        if (foo { x }) {}
        repeat {} while x
        switch 4 { default: break }
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove the parentheses around this expression"),
        FindingSpec("2️⃣", message: "remove the parentheses around this expression"),
        FindingSpec("3️⃣", message: "remove the parentheses around this expression"),
        FindingSpec("4️⃣", message: "remove the parentheses around this expression"),
        FindingSpec("5️⃣", message: "remove the parentheses around this expression"),
        FindingSpec("6️⃣", message: "remove the parentheses around this expression"),
        FindingSpec("7️⃣", message: "remove the parentheses around this expression"),
      ]
    )
  }

  func testParensAroundNestedParenthesizedStatements() {
    assertFormatting(
      NoParensAroundConditions.self,
      input: """
        switch 1️⃣(a) {
          case 1:
            switch 2️⃣(b) {
              default: break
            }
        }
        if 3️⃣(x) {
          if 4️⃣(y) {
          } else if 5️⃣(z) {
          } else {
          }
        } else if 6️⃣(w) {
        }
        """,
      expected: """
        switch a {
          case 1:
            switch b {
              default: break
            }
        }
        if x {
          if y {
          } else if z {
          } else {
          }
        } else if w {
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove the parentheses around this expression"),
        FindingSpec("2️⃣", message: "remove the parentheses around this expression"),
        FindingSpec("3️⃣", message: "remove the parentheses around this expression"),
        FindingSpec("4️⃣", message: "remove the parentheses around this expression"),
        FindingSpec("5️⃣", message: "remove the parentheses around this expression"),
        FindingSpec("6️⃣", message: "remove the parentheses around this expression"),
      ]
    )

    assertFormatting(
      NoParensAroundConditions.self,
      input: """
        while 1️⃣(x) {
          while 2️⃣(y) {}
        }
        guard 3️⃣(x), 4️⃣(y), 5️⃣(x == 3) else {
          guard 6️⃣(a), 7️⃣(b), 8️⃣(c == x) else {
            return
          }
          return
        }
        repeat {
          repeat {
          } while 9️⃣(y)
        } while🔟(x)
        if 0️⃣(foo.someCall({ if ℹ️(x) {} })) {}
        """,
      expected: """
        while x {
          while y {}
        }
        guard x, y, x == 3 else {
          guard a, b, c == x else {
            return
          }
          return
        }
        repeat {
          repeat {
          } while y
        } while x
        if foo.someCall({ if x {} }) {}
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove the parentheses around this expression"),
        FindingSpec("2️⃣", message: "remove the parentheses around this expression"),
        FindingSpec("3️⃣", message: "remove the parentheses around this expression"),
        FindingSpec("4️⃣", message: "remove the parentheses around this expression"),
        FindingSpec("5️⃣", message: "remove the parentheses around this expression"),
        FindingSpec("6️⃣", message: "remove the parentheses around this expression"),
        FindingSpec("7️⃣", message: "remove the parentheses around this expression"),
        FindingSpec("8️⃣", message: "remove the parentheses around this expression"),
        FindingSpec("9️⃣", message: "remove the parentheses around this expression"),
        FindingSpec("🔟", message: "remove the parentheses around this expression"),
        FindingSpec("0️⃣", message: "remove the parentheses around this expression"),
        FindingSpec("ℹ️", message: "remove the parentheses around this expression"),
      ]
    )
  }

  func testParensAroundNestedUnparenthesizedStatements() {
    assertFormatting(
      NoParensAroundConditions.self,
      input: """
        switch b {
          case 2:
            switch 1️⃣(d) {
              default: break
            }
        }
        if x {
          if 2️⃣(y) {
          } else if 3️⃣(z) {
          } else {
          }
        } else if 4️⃣(w) {
        }
        while x {
          while 5️⃣(y) {}
        }
        repeat {
          repeat {
          } while 6️⃣(y)
        } while x
        if foo.someCall({ if 7️⃣(x) {} }) {}
        """,
      expected: """
        switch b {
          case 2:
            switch d {
              default: break
            }
        }
        if x {
          if y {
          } else if z {
          } else {
          }
        } else if w {
        }
        while x {
          while y {}
        }
        repeat {
          repeat {
          } while y
        } while x
        if foo.someCall({ if x {} }) {}
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove the parentheses around this expression"),
        FindingSpec("2️⃣", message: "remove the parentheses around this expression"),
        FindingSpec("3️⃣", message: "remove the parentheses around this expression"),
        FindingSpec("4️⃣", message: "remove the parentheses around this expression"),
        FindingSpec("5️⃣", message: "remove the parentheses around this expression"),
        FindingSpec("6️⃣", message: "remove the parentheses around this expression"),
        FindingSpec("7️⃣", message: "remove the parentheses around this expression"),
      ]
    )
  }

  func testParensAroundIfAndSwitchExprs() {
    assertFormatting(
      NoParensAroundConditions.self,
      input: """
        let x = if 1️⃣(x) {}
        let y = switch 2️⃣(4) { default: break }
        func foo() {
          return if 3️⃣(x) {}
        }
        func bar() {
          return switch 4️⃣(4) { default: break }
        }
        """,
      expected: """
        let x = if x {}
        let y = switch 4 { default: break }
        func foo() {
          return if x {}
        }
        func bar() {
          return switch 4 { default: break }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove the parentheses around this expression"),
        FindingSpec("2️⃣", message: "remove the parentheses around this expression"),
        FindingSpec("3️⃣", message: "remove the parentheses around this expression"),
        FindingSpec("4️⃣", message: "remove the parentheses around this expression"),
      ]
    )
  }

  func testParensAroundAmbiguousConditions() {
    assertFormatting(
      NoParensAroundConditions.self,
      input: """
        if ({ true }()) {}
        if (functionWithTrailingClosure { 5 }) {}
        """,
      expected: """
        if ({ true }()) {}
        if (functionWithTrailingClosure { 5 }) {}
        """,
      findings: []
    )
  }

  func testKeywordAlwaysHasTrailingSpace() {
    assertFormatting(
      NoParensAroundConditions.self,
      input: """
        if1️⃣(x) {}
        while2️⃣(x) {}
        guard3️⃣(x),4️⃣(y),5️⃣(x == 3) else {}
        repeat {} while6️⃣(x)
        switch7️⃣(4) { default: break }
        """,
      expected: """
        if x {}
        while x {}
        guard x,y,x == 3 else {}
        repeat {} while x
        switch 4 { default: break }
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove the parentheses around this expression"),
        FindingSpec("2️⃣", message: "remove the parentheses around this expression"),
        FindingSpec("3️⃣", message: "remove the parentheses around this expression"),
        FindingSpec("4️⃣", message: "remove the parentheses around this expression"),
        FindingSpec("5️⃣", message: "remove the parentheses around this expression"),
        FindingSpec("6️⃣", message: "remove the parentheses around this expression"),
        FindingSpec("7️⃣", message: "remove the parentheses around this expression"),
      ]
    )
  }

  func testBlockCommentsBeforeConditionArePreserved() {
    assertFormatting(
      NoParensAroundConditions.self,
      input: """
        if/*foo*/1️⃣(x) {}
        while/*foo*/2️⃣(x) {}
        guard/*foo*/3️⃣(x), /*foo*/4️⃣(y), /*foo*/5️⃣(x == 3) else {}
        repeat {} while/*foo*/6️⃣(x)
        switch/*foo*/7️⃣(4) { default: break }
        """,
      expected: """
        if/*foo*/x {}
        while/*foo*/x {}
        guard/*foo*/x, /*foo*/y, /*foo*/x == 3 else {}
        repeat {} while/*foo*/x
        switch/*foo*/4 { default: break }
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove the parentheses around this expression"),
        FindingSpec("2️⃣", message: "remove the parentheses around this expression"),
        FindingSpec("3️⃣", message: "remove the parentheses around this expression"),
        FindingSpec("4️⃣", message: "remove the parentheses around this expression"),
        FindingSpec("5️⃣", message: "remove the parentheses around this expression"),
        FindingSpec("6️⃣", message: "remove the parentheses around this expression"),
        FindingSpec("7️⃣", message: "remove the parentheses around this expression"),
      ]
    )
  }

  func testCommentsAfterKeywordArePreserved() {
    assertFormatting(
      NoParensAroundConditions.self,
      input: """
        if /*foo*/ // bar
          1️⃣(x) {}
        while /*foo*/ // bar
          2️⃣(x) {}
        guard /*foo*/ // bar
          3️⃣(x), /*foo*/ // bar
          4️⃣(y), /*foo*/ // bar
          5️⃣(x == 3) else {}
        repeat {} while /*foo*/ // bar
          6️⃣(x)
        switch /*foo*/ // bar
          7️⃣(4) { default: break }
        """,
      expected: """
        if /*foo*/ // bar
          x {}
        while /*foo*/ // bar
          x {}
        guard /*foo*/ // bar
          x, /*foo*/ // bar
          y, /*foo*/ // bar
          x == 3 else {}
        repeat {} while /*foo*/ // bar
          x
        switch /*foo*/ // bar
          4 { default: break }
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove the parentheses around this expression"),
        FindingSpec("2️⃣", message: "remove the parentheses around this expression"),
        FindingSpec("3️⃣", message: "remove the parentheses around this expression"),
        FindingSpec("4️⃣", message: "remove the parentheses around this expression"),
        FindingSpec("5️⃣", message: "remove the parentheses around this expression"),
        FindingSpec("6️⃣", message: "remove the parentheses around this expression"),
        FindingSpec("7️⃣", message: "remove the parentheses around this expression"),
      ]
    )
  }
}
