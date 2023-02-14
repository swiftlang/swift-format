import SwiftFormatRules

final class NoParensAroundConditionsTests: LintOrFormatRuleTestCase {
  func testParensAroundConditions() {
    XCTAssertFormatting(
      NoParensAroundConditions.self,
      input: """
             if (x) {}
             while (x) {}
             guard (x), (y), (x == 3) else {}
             if (foo { x }) {}
             repeat {} while(x)
             switch (4) { default: break }
             """,
      expected: """
                if x {}
                while x {}
                guard x, y, x == 3 else {}
                if (foo { x }) {}
                repeat {} while x
                switch 4 { default: break }
                """)
  }

  func testParensAroundNestedParenthesizedStatements() {
    XCTAssertFormatting(
      NoParensAroundConditions.self,
      input: """
             switch (a) {
               case 1:
                 switch (b) {
                   default: break
                 }
             }
             if (x) {
               if (y) {
               } else if (z) {
               } else {
               }
             } else if (w) {
             }
             while (x) {
               while (y) {}
             }
             guard (x), (y), (x == 3) else {
               guard (a), (b), (c == x) else {
                 return
               }
               return
             }
             repeat {
               repeat {
               } while (y)
             } while(x)
             if (foo.someCall({ if (x) {} })) {}
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
                """)
  }

  func testParensAroundNestedUnparenthesizedStatements() {
    XCTAssertFormatting(
      NoParensAroundConditions.self,
      input: """
             switch b {
               case 2:
                 switch (d) {
                   default: break
                 }
             }
             if x {
               if (y) {
               } else if (z) {
               } else {
               }
             } else if (w) {
             }
             while x {
               while (y) {}
             }
             repeat {
               repeat {
               } while (y)
             } while x
             if foo.someCall({ if (x) {} }) {}
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
                """)
  }
}
