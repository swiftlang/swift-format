import SwiftFormatRules

final class NoLabelsInCasePatternsTests: LintOrFormatRuleTestCase {
  func testRedundantCaseLabels() {
    XCTAssertFormatting(
      NoLabelsInCasePatterns.self,
      input: """
             switch treeNode {
             case .root(let data):
               break
             case .subtree(left: let /*hello*/left, right: let right):
               break
             case .leaf(element: let element):
               break
             }
             """,
      expected: """
                switch treeNode {
                case .root(let data):
                  break
                case .subtree(let /*hello*/left, let right):
                  break
                case .leaf(let element):
                  break
                }
                """)
    XCTAssertNotDiagnosed(.removeRedundantLabel(name: "data"))
    XCTAssertDiagnosed(.removeRedundantLabel(name: "left"))
    XCTAssertDiagnosed(.removeRedundantLabel(name: "right"))
    XCTAssertDiagnosed(.removeRedundantLabel(name: "element"))
  }
}
