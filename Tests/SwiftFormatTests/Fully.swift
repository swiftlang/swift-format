@_spi(Rules) import SwiftFormat
import _SwiftFormatTestSupport

class FullyIndirectEnumTests: LintOrFormatRuleTestCase {
  func testAllIndirectCases() {
    assertFormatting(
      FullyIndirectEnum.self,
      input: """
        // Comment 1
        public 1️⃣enum DependencyGraphNode {
          internal 2️⃣indirect case userDefined(dependencies: [DependencyGraphNode])
          // Comment 2
          3️⃣indirect case synthesized(dependencies: [DependencyGraphNode])
          4️⃣indirect case other(dependencies: [DependencyGraphNode])
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
        FindingSpec(
          "1️⃣",
          message: "declare enum 'DependencyGraphNode' itself as indirect when all cases are indirect",
          notes: [
            NoteSpec("2️⃣", message: "remove 'indirect' here"),
            NoteSpec("3️⃣", message: "remove 'indirect' here"),
            NoteSpec("4️⃣", message: "remove 'indirect' here"),
          ]
        )
      ]
    )
  }

  func testAllIndirectCasesWithAttributes() {
    assertFormatting(
      FullyIndirectEnum.self,
      input: """
        // Comment 1
        public 1️⃣enum DependencyGraphNode {
          @someAttr internal 2️⃣indirect case userDefined(dependencies: [DependencyGraphNode])
          // Comment 2
          @someAttr 3️⃣indirect case synthesized(dependencies: [DependencyGraphNode])
          @someAttr 4️⃣indirect case other(dependencies: [DependencyGraphNode])
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
        FindingSpec(
          "1️⃣",
          message: "declare enum 'DependencyGraphNode' itself as indirect when all cases are indirect",
          notes: [
            NoteSpec("2️⃣", message: "remove 'indirect' here"),
            NoteSpec("3️⃣", message: "remove 'indirect' here"),
            NoteSpec("4️⃣", message: "remove 'indirect' here"),
          ]
        )
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
