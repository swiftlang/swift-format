import SwiftSyntax
import XCTest

@testable import SwiftFormatCore

public class RuleMaskTests: XCTestCase {

  private func createMask(sourceText: String) -> RuleMask {
    let fileURL = URL(fileURLWithPath: "/tmp/test.swift")
    let converter = SourceLocationConverter(file: fileURL.path, source: sourceText)
    let syntax = try! SyntaxParser.parse(source: sourceText)
    return RuleMask(syntaxNode: syntax, sourceLocationConverter: converter)
  }

  public func testSingleRule() {
    let text =
      """
      let a = 123
      // swift-format-disable: rule1
      let b = 456
      // swift-format-enable: rule1
      let c = 789
      """

    let mask = createMask(sourceText: text)

    XCTAssertEqual(mask.ruleState("rule1", atLine: 1), .default)
    XCTAssertEqual(mask.ruleState("rule1", atLine: 3), .disabled)
    XCTAssertEqual(mask.ruleState("rule1", atLine: 5), .enabled)
  }

  public func testTwoRules() {
    let text =
      """
      let a = 123
      // swift-format-disable: rule1
      let b = 456
      // swift-format-disable: rule2
      let c = 789
      // swift-format-enable: rule1
      let d = "abc"
      // swift-format-enable: rule2
      let e = "def"
      """

    let mask = createMask(sourceText: text)

    XCTAssertEqual(mask.ruleState("rule1", atLine: 1), .default)
    XCTAssertEqual(mask.ruleState("rule1", atLine: 3), .disabled)
    XCTAssertEqual(mask.ruleState("rule1", atLine: 5), .disabled)
    XCTAssertEqual(mask.ruleState("rule1", atLine: 7), .enabled)
    XCTAssertEqual(mask.ruleState("rule1", atLine: 9), .enabled)

    XCTAssertEqual(mask.ruleState("rule2", atLine: 1), .default)
    XCTAssertEqual(mask.ruleState("rule2", atLine: 3), .default)
    XCTAssertEqual(mask.ruleState("rule2", atLine: 5), .disabled)
    XCTAssertEqual(mask.ruleState("rule2", atLine: 7), .disabled)
    XCTAssertEqual(mask.ruleState("rule2", atLine: 9), .enabled)
  }

  public func testEnableBeforeDisable() {
    let text =
      """
      let a = 123
      // swift-format-enable: rule1
      let b = 456
      // swift-format-disable: rule1
      let c = 789
      """

    let mask = createMask(sourceText: text)

    XCTAssertEqual(mask.ruleState("rule1", atLine: 1), .default)
    XCTAssertEqual(mask.ruleState("rule1", atLine: 3), .enabled)
    XCTAssertEqual(mask.ruleState("rule1", atLine: 5), .disabled)
  }

  public func testDuplicateNested() {
    let text =
      """
      let a = 123
      // swift-format-disable: rule1
      let b = 456
      // swift-format-disable: rule1
      let c = 789
      // swift-format-enable: rule1
      let d = "abc"
      // swift-format-enable: rule1
      let e = "def"
      """

    let mask = createMask(sourceText: text)

    XCTAssertEqual(mask.ruleState("rule1", atLine: 1), .default)
    XCTAssertEqual(mask.ruleState("rule1", atLine: 3), .disabled)
    XCTAssertEqual(mask.ruleState("rule1", atLine: 5), .disabled)
    XCTAssertEqual(mask.ruleState("rule1", atLine: 7), .enabled)
    XCTAssertEqual(mask.ruleState("rule1", atLine: 9), .enabled)
  }

  public func testSingleFlags() {
    let text1 =
      """
      let a = 123
      let b = 456
      // swift-format-disable: rule1
      let c = 789
      let d = "abc"
      """

    let mask1 = createMask(sourceText: text1)

    XCTAssertEqual(mask1.ruleState("rule1", atLine: 1), .default)
    XCTAssertEqual(mask1.ruleState("rule1", atLine: 5), .disabled)

    let text2 =
      """
      let a = 123
      let b = 456
      // swift-format-enable: rule1
      let c = 789
      let d = "abc"
      """

    let mask2 = createMask(sourceText: text2)

    XCTAssertEqual(mask2.ruleState("rule1", atLine: 1), .default)
    XCTAssertEqual(mask2.ruleState("rule1", atLine: 5), .enabled)
  }

  public func testSpuriousFlags() {
    let text1 =
      """
      let a = 123
      let b = 456 // swift-format-disable: rule1
      let c = 789
      // swift-format-enable: rule1
      let d = "abc"
      """

    let mask1 = createMask(sourceText: text1)

    XCTAssertEqual(mask1.ruleState("rule1", atLine: 1), .default)
    XCTAssertEqual(mask1.ruleState("rule1", atLine: 3), .default)
    XCTAssertEqual(mask1.ruleState("rule1", atLine: 5), .enabled)

    let text2 =
      #"""
      let a = 123
      let b =
        """
        // swift-format-disable: rule1
        """
      let c = 789
      // swift-format-enable: rule1
      let d = "abc"
      """#

    let mask2 = createMask(sourceText: text2)

    XCTAssertEqual(mask2.ruleState("rule1", atLine: 1), .default)
    XCTAssertEqual(mask2.ruleState("rule1", atLine: 6), .default)
    XCTAssertEqual(mask2.ruleState("rule1", atLine: 8), .enabled)
  }
}
