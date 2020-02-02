import SwiftFormatRules

final class NoParensAroundConditionsTests: DiagnosingTestCase {
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
}
