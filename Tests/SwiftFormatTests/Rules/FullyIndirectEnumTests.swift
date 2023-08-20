import _SwiftFormatTestSupport

@_spi(Rules) import SwiftFormat

// FIXME: Since we're putting the finding on the `enum` decl, we should have notes pointing to each
// `indirect` that should be removed from the cases. The finding should also probably be attached to
// the `enum` keyword, not the name, since the inserted keyword will be there.
class FullyIndirectEnumTests: LintOrFormatRuleTestCase {
  func testAllIndirectCases() {
    assertFormatting(
      FullyIndirectEnum.self,
      input: """
        // Comment 1
        public enum 1️⃣DependencyGraphNode {
          internal indirect case userDefined(dependencies: [DependencyGraphNode])
          // Comment 2
          indirect case synthesized(dependencies: [DependencyGraphNode])
          indirect case other(dependencies: [DependencyGraphNode])
          var x: Int
        }
        """,
      expected: """
        // Comment 1
        public indirect enum DependencyGraphNode {
          internal case userDefined(dependencies: [DependencyGraphNode])
          // Comment 2
          case synthesized(dependencies: [DependencyGraphNode])
          case other(dependencies: [DependencyGraphNode])
          var x: Int
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "move 'indirect' before the enum declaration 'DependencyGraphNode' when all cases are indirect"),
      ]
    )
  }

  func testAllIndirectCasesWithAttributes() {
    assertFormatting(
      FullyIndirectEnum.self,
      input: """
        // Comment 1
        public enum 1️⃣DependencyGraphNode {
          @someAttr internal indirect case userDefined(dependencies: [DependencyGraphNode])
          // Comment 2
          @someAttr indirect case synthesized(dependencies: [DependencyGraphNode])
          @someAttr indirect case other(dependencies: [DependencyGraphNode])
          var x: Int
        }
        """,
      expected: """
        // Comment 1
        public indirect enum DependencyGraphNode {
          @someAttr internal case userDefined(dependencies: [DependencyGraphNode])
          // Comment 2
          @someAttr case synthesized(dependencies: [DependencyGraphNode])
          @someAttr case other(dependencies: [DependencyGraphNode])
          var x: Int
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "move 'indirect' before the enum declaration 'DependencyGraphNode' when all cases are indirect"),
      ]
    )
  }

  func testNotAllIndirectCases() {
    let input = """
      public enum CompassPoint {
        case north
        indirect case south
        case east
        case west
      }
      """
    assertFormatting(FullyIndirectEnum.self, input: input, expected: input, findings: [])
  }

  func testAlreadyIndirectEnum() {
    let input = """
      indirect enum CompassPoint {
        case north
        case south
        case east
        case west
      }
      """
    assertFormatting(FullyIndirectEnum.self, input: input, expected: input, findings: [])
  }

  func testCaselessEnum() {
    let input = """
      public enum Constants {
        public static let foo = 5
        public static let bar = "bar"
      }
      """
    assertFormatting(FullyIndirectEnum.self, input: input, expected: input, findings: [])
  }
}
