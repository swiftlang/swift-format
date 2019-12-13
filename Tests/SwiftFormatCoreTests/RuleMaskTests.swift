import SwiftSyntax
import XCTest

@testable import SwiftFormatCore

public class RuleMaskTests: XCTestCase {

  /// The source converter for the text in the current test. This is implicitly unwrapped because
  /// each test case must prepare some source text before performing any assertions, otherwise
  /// there's a developer error.
  var converter: SourceLocationConverter!

  private func createMask(sourceText: String) -> RuleMask {
    let fileURL = URL(fileURLWithPath: "/tmp/test.swift")
    converter = SourceLocationConverter(file: fileURL.path, source: sourceText)
    let syntax = try! SyntaxParser.parse(source: sourceText)
    return RuleMask(syntaxNode: syntax, sourceLocationConverter: converter)
  }

  /// Returns the source location that corresponds to the given line and column numbers.
  private func location(ofLine line: Int, column: Int = 0) -> SourceLocation {
    return converter.location(for: converter.position(ofLine: line, column: column))
  }

  public func testSingleRule() {
    let text =
      """
      let a = 123
      // swift-format-ignore: rule1
      let b = 456
      let c = 789
      """

    let mask = createMask(sourceText: text)

    XCTAssertEqual(mask.ruleState("rule1", at: location(ofLine: 1)), .default)
    XCTAssertEqual(mask.ruleState("rule1", at: location(ofLine: 3)), .disabled)
    XCTAssertEqual(mask.ruleState("rule1", at: location(ofLine: 4)), .default)
  }

  public func testIgnoreTwoRules() {
    let text =
      """
      let a = 123
      // swift-format-ignore: rule1
      let b = 456
      // swift-format-ignore: rule2
      let c = 789
      // swift-format-ignore: rule1, rule2
      let d = "abc"
      let e = "def"
      """

    let mask = createMask(sourceText: text)

    XCTAssertEqual(mask.ruleState("rule1", at: location(ofLine: 1)), .default)
    XCTAssertEqual(mask.ruleState("rule1", at: location(ofLine: 3)), .disabled)
    XCTAssertEqual(mask.ruleState("rule1", at: location(ofLine: 5)), .default)
    XCTAssertEqual(mask.ruleState("rule1", at: location(ofLine: 7)), .disabled)
    XCTAssertEqual(mask.ruleState("rule1", at: location(ofLine: 8)), .default)

    XCTAssertEqual(mask.ruleState("rule2", at: location(ofLine: 1)), .default)
    XCTAssertEqual(mask.ruleState("rule2", at: location(ofLine: 3)), .default)
    XCTAssertEqual(mask.ruleState("rule2", at: location(ofLine: 5)), .disabled)
    XCTAssertEqual(mask.ruleState("rule2", at: location(ofLine: 7)), .disabled)
    XCTAssertEqual(mask.ruleState("rule2", at: location(ofLine: 8)), .default)
  }

  public func testDuplicateNested() {
    let text =
      """
      // swift-format-ignore: rule1
      struct Foo {
        var bar = 0

        // swift-format-ignore: rule1
        var baz = 0

        // swift-format-ignore: rule4
        var bazzle = 0

        var barzle = 0
      }
      """

    let mask = createMask(sourceText: text)

    XCTAssertEqual(mask.ruleState("rule1", at: location(ofLine: 3, column: 3)), .disabled)
    XCTAssertEqual(mask.ruleState("rule4", at: location(ofLine: 3, column: 3)), .default)

    XCTAssertEqual(mask.ruleState("rule1", at: location(ofLine: 6, column: 3)), .disabled)
    XCTAssertEqual(mask.ruleState("rule4", at: location(ofLine: 6, column: 3)), .default)

    XCTAssertEqual(mask.ruleState("rule1", at: location(ofLine: 9, column: 3)), .disabled)
    XCTAssertEqual(mask.ruleState("rule4", at: location(ofLine: 9, column: 3)), .disabled)

    XCTAssertEqual(mask.ruleState("rule4", at: location(ofLine: 11, column: 3)), .default)

  }

  public func testSpuriousFlags() {
    let text1 =
      """
      let a = 123
      let b = 456 // swift-format-ignore: rule1
      let c = 789
      /* swift-format-ignore: rule2 */
      let d = 111
      // swift-format-ignore:
      let b = 456
      """

    let mask1 = createMask(sourceText: text1)

    XCTAssertEqual(mask1.ruleState("rule1", at: location(ofLine: 1)), .default)
    XCTAssertEqual(mask1.ruleState("rule1", at: location(ofLine: 2)), .default)
    XCTAssertEqual(mask1.ruleState("rule1", at: location(ofLine: 3)), .default)
    XCTAssertEqual(mask1.ruleState("rule1", at: location(ofLine: 5)), .default)
    XCTAssertEqual(mask1.ruleState("rule1", at: location(ofLine: 7)), .default)

    let text2 =
      #"""
      let a = 123
      let b =
        """
        // swift-format-ignore: rule1
        """
      let c = 789
      // swift-format-ignore: rule1
      let d = "abc"
      """#

    let mask2 = createMask(sourceText: text2)

    XCTAssertEqual(mask2.ruleState("rule1", at: location(ofLine: 1)), .default)
    XCTAssertEqual(mask2.ruleState("rule1", at: location(ofLine: 6)), .default)
    XCTAssertEqual(mask2.ruleState("rule1", at: location(ofLine: 8)), .disabled)
  }

  public func testNamelessDirectiveAffectsAllRules() {
    let text =
      """
      let a = 123
      // swift-format-ignore
      let b = 456
      let c = 789
      """

    let mask = createMask(sourceText: text)

    XCTAssertEqual(mask.ruleState("rule1", at: location(ofLine: 1)), .default)
    XCTAssertEqual(mask.ruleState("rule1", at: location(ofLine: 3)), .disabled)
    XCTAssertEqual(mask.ruleState("TotallyMadeUpRule", at: location(ofLine: 3)), .disabled)
    XCTAssertEqual(mask.ruleState("rule1", at: location(ofLine: 4)), .default)
  }

  public func testDirectiveWithRulesList() {
    let text =
      """
      let a = 123
      // swift-format-ignore: rule1, rule2   , AnotherRule  , TheBestRule,, ,   , ,
      let b = 456
      let c = 789
      """

    let mask = createMask(sourceText: text)

    XCTAssertEqual(mask.ruleState("rule1", at: location(ofLine: 1)), .default)
    XCTAssertEqual(mask.ruleState("rule1", at: location(ofLine: 3)), .disabled)
    XCTAssertEqual(mask.ruleState("rule2", at: location(ofLine: 3)), .disabled)
    XCTAssertEqual(mask.ruleState("AnotherRule", at: location(ofLine: 3)), .disabled)
    XCTAssertEqual(mask.ruleState("TheBestRule", at: location(ofLine: 3)), .disabled)
    XCTAssertEqual(mask.ruleState("TotallyMadeUpRule", at: location(ofLine: 3)), .default)
    XCTAssertEqual(mask.ruleState("rule1", at: location(ofLine: 4)), .default)
  }
}
