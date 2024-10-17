@_spi(Rules) import SwiftFormat
import _SwiftFormatTestSupport

final class NoLabelsInCasePatternsTests: LintOrFormatRuleTestCase {
  func testRedundantCaseLabels() {
    assertFormatting(
      NoLabelsInCasePatterns.self,
      input: """
        switch treeNode {
        case .root(let data):
          break
        case .subtree(1️⃣left: let /*hello*/left, 2️⃣right: let right):
          break
        case .leaf(3️⃣element: let element):
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
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove the label 'left' from this 'case' pattern"),
        FindingSpec("2️⃣", message: "remove the label 'right' from this 'case' pattern"),
        FindingSpec("3️⃣", message: "remove the label 'element' from this 'case' pattern"),
      ]
    )
  }
}
