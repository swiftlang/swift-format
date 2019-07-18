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

    XCTAssertFalse(mask.isDisabled("rule1", line: 1))
    XCTAssertTrue(mask.isDisabled("rule1", line: 3))
    XCTAssertFalse(mask.isDisabled("rule1", line: 5))
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

    XCTAssertFalse(mask.isDisabled("rule1", line: 1))
    XCTAssertTrue(mask.isDisabled("rule1", line: 3))
    XCTAssertTrue(mask.isDisabled("rule1", line: 5))
    XCTAssertFalse(mask.isDisabled("rule1", line: 7))
    XCTAssertFalse(mask.isDisabled("rule1", line: 9))

    XCTAssertFalse(mask.isDisabled("rule2", line: 1))
    XCTAssertFalse(mask.isDisabled("rule2", line: 3))
    XCTAssertTrue(mask.isDisabled("rule2", line: 5))
    XCTAssertTrue(mask.isDisabled("rule2", line: 7))
    XCTAssertFalse(mask.isDisabled("rule2", line: 9))
  }

  public func testWrongOrderFlags() {
    let text =
      """
      let a = 123
      // swift-format-enable: rule1
      let b = 456
      // swift-format-disable: rule1
      let c = 789
      """

    let mask = createMask(sourceText: text)

    XCTAssertFalse(mask.isDisabled("rule1", line: 1))
    XCTAssertFalse(mask.isDisabled("rule1", line: 3))
    XCTAssertFalse(mask.isDisabled("rule1", line: 5))
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

    XCTAssertFalse(mask.isDisabled("rule1", line: 1))
    XCTAssertTrue(mask.isDisabled("rule1", line: 3))
    XCTAssertTrue(mask.isDisabled("rule1", line: 5))
    XCTAssertFalse(mask.isDisabled("rule1", line: 7))
    XCTAssertFalse(mask.isDisabled("rule1", line: 9))
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

    XCTAssertFalse(mask1.isDisabled("rule1", line: 1))
    XCTAssertFalse(mask1.isDisabled("rule1", line: 6))

    let text2 =
      """
      let a = 123
      let b = 456
      // swift-format-enable: rule1
      let c = 789
      let d = "abc"
      """

    let mask2 = createMask(sourceText: text2)

    XCTAssertFalse(mask2.isDisabled("rule1", line: 1))
    XCTAssertFalse(mask2.isDisabled("rule1", line: 6))
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

    XCTAssertFalse(mask1.isDisabled("rule1", line: 1))
    XCTAssertFalse(mask1.isDisabled("rule1", line: 3))
    XCTAssertFalse(mask1.isDisabled("rule1", line: 5))

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

    XCTAssertFalse(mask2.isDisabled("rule1", line: 1))
    XCTAssertFalse(mask2.isDisabled("rule1", line: 6))
    XCTAssertFalse(mask2.isDisabled("rule1", line: 8))
  }
}
