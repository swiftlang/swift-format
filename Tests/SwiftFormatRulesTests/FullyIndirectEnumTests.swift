import SwiftFormatRules

class FullyIndirectEnumTests: LintOrFormatRuleTestCase {
  func testAllIndirectCases() {
    XCTAssertFormatting(
      FullyIndirectEnum.self,
      input: """
        // Comment 1
        public enum DependencyGraphNode {
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
        """)
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
    XCTAssertFormatting(FullyIndirectEnum.self, input: input, expected: input)
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
    XCTAssertFormatting(FullyIndirectEnum.self, input: input, expected: input)
  }

  func testCaselessEnum() {
    let input = """
      public enum Constants {
        public static let foo = 5
        public static let bar = "bar"
      }
      """
    XCTAssertFormatting(FullyIndirectEnum.self, input: input, expected: input)
  }
}
