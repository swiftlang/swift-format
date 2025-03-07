//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2025 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

@_spi(Testing) import SwiftFormat
import SwiftParser
import SwiftSyntax
import XCTest

final class RuleMaskTests: XCTestCase {
  /// The source converter for the text in the current test. This is implicitly unwrapped because
  /// each test case must prepare some source text before performing any assertions, otherwise
  /// there's a developer error.
  var converter: SourceLocationConverter!

  private func createMask(sourceText: String) -> RuleMask {
    let fileURL = URL(fileURLWithPath: "/tmp/test.swift")
    let syntax = Parser.parse(source: sourceText)
    converter = SourceLocationConverter(fileName: fileURL.path, tree: syntax)
    return RuleMask(syntaxNode: Syntax(syntax), sourceLocationConverter: converter)
  }

  /// Returns the source location that corresponds to the given line and column numbers.
  private func location(ofLine line: Int, column: Int = 0) -> SourceLocation {
    return converter.location(for: converter.position(ofLine: line, column: column))
  }

  func testSingleRule() {
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

  func testIgnoreTwoRules() {
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

  func testDuplicateNested() {
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

  func testSpuriousFlags() {
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

  func testNamelessDirectiveAffectsAllRules() {
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

  func testDirectiveWithRulesList() {
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

  func testAllRulesWholeFileIgnore() {
    let text =
      """
      // This file has important contents.
      // swift-format-ignore-file
      // Everything in this file is ignored.

      let a = 5
      let b = 4

      class Foo {
        let member1 = 0
        func foo() {
          baz()
        }
      }

      struct Baz {
      }
      """

    let mask = createMask(sourceText: text)

    let lineCount = text.split(separator: "\n").count
    for i in 0..<lineCount {
      XCTAssertEqual(mask.ruleState("rule1", at: location(ofLine: i)), .disabled)
    }
  }

  func testAllRulesWholeFileIgnoreNestedInNode() {
    let text =
      """
      // This file has important contents.
      // Everything in this file is ignored.

      let a = 5
      let b = 4

      class Foo {
        // swift-format-ignore-file
        let member1 = 0
        func foo() {
          baz()
        }
      }

      struct Baz {
      }
      """

    let mask = createMask(sourceText: text)

    let lineCount = text.split(separator: "\n").count
    for i in 0..<lineCount {
      XCTAssertEqual(mask.ruleState("rule1", at: location(ofLine: i)), .default)
    }
  }

  func testSingleRuleWholeFileIgnore() {
    let text =
      """
      // This file has important contents.
      // swift-format-ignore-file: rule1
      // Everything in this file is ignored.

      let a = 5
      let b = 4

      class Foo {
        let member1 = 0
        func foo() {
          baz()
        }
      }

      struct Baz {
      }
      """

    let mask = createMask(sourceText: text)

    let lineCount = text.split(separator: "\n").count
    for i in 0..<lineCount {
      XCTAssertEqual(mask.ruleState("rule1", at: location(ofLine: i)), .disabled)
      XCTAssertEqual(mask.ruleState("rule2", at: location(ofLine: i)), .default)
    }
  }

  func testMultipleRulesWholeFileIgnore() {
    let text =
      """
      // This file has important contents.
      // swift-format-ignore-file: rule1, rule2, rule3
      // Everything in this file is ignored.

      let a = 5
      let b = 4

      class Foo {
        let member1 = 0
        func foo() {
          baz()
        }
      }

      struct Baz {
      }
      """

    let mask = createMask(sourceText: text)

    let lineCount = text.split(separator: "\n").count
    for i in 0..<lineCount {
      XCTAssertEqual(mask.ruleState("rule1", at: location(ofLine: i)), .disabled)
      XCTAssertEqual(mask.ruleState("rule2", at: location(ofLine: i)), .disabled)
      XCTAssertEqual(mask.ruleState("rule3", at: location(ofLine: i)), .disabled)
      XCTAssertEqual(mask.ruleState("rule4", at: location(ofLine: i)), .default)
    }
  }

  func testFileAndLineIgnoresMixed() {
    let text =
      """
      // This file has important contents.
      // swift-format-ignore-file: rule1, rule2
      // Everything in this file is ignored.

      let a = 5
      // swift-format-ignore: rule3
      let b = 4

      class Foo {
        // swift-format-ignore: rule3, rule4
        let member1 = 0

        func foo() {
          baz()
        }
      }

      struct Baz {
      }
      """

    let mask = createMask(sourceText: text)

    let lineCount = text.split(separator: "\n").count
    for i in 0..<lineCount {
      XCTAssertEqual(mask.ruleState("rule1", at: location(ofLine: i)), .disabled)
      XCTAssertEqual(mask.ruleState("rule2", at: location(ofLine: i)), .disabled)
      if i == 7 {
        XCTAssertEqual(mask.ruleState("rule3", at: location(ofLine: i)), .disabled)
        XCTAssertEqual(mask.ruleState("rule4", at: location(ofLine: i)), .default)
      } else if i == 11 {
        XCTAssertEqual(mask.ruleState("rule3", at: location(ofLine: i, column: 3)), .disabled)
        XCTAssertEqual(mask.ruleState("rule4", at: location(ofLine: i, column: 3)), .disabled)
      } else {
        XCTAssertEqual(mask.ruleState("rule3", at: location(ofLine: i)), .default)
        XCTAssertEqual(mask.ruleState("rule4", at: location(ofLine: i)), .default)
      }
    }
  }

  func testMultipleSubsetFileIgnoreDirectives() {
    let text =
      """
      // This file has important contents.
      // swift-format-ignore-file: rule1
      // swift-format-ignore-file: rule2
      // Everything in this file is ignored.

      let a = 5
      let b = 4

      class Foo {
        let member1 = 0

        func foo() {
          baz()
        }
      }

      struct Baz {
      }
      """

    let mask = createMask(sourceText: text)

    let lineCount = text.split(separator: "\n").count
    for i in 0..<lineCount {
      XCTAssertEqual(mask.ruleState("rule1", at: location(ofLine: i)), .disabled)
      XCTAssertEqual(mask.ruleState("rule2", at: location(ofLine: i)), .disabled)
      XCTAssertEqual(mask.ruleState("rule3", at: location(ofLine: i)), .default)
    }
  }

  func testSubsetAndAllFileIgnoreDirectives() {
    let text =
      """
      // This file has important contents.
      // swift-format-ignore-file: rule1
      // swift-format-ignore-file
      // Everything in this file is ignored.

      let a = 5
      let b = 4

      class Foo {
        let member1 = 0

        func foo() {
          baz()
        }
      }

      struct Baz {
      }
      """

    let mask = createMask(sourceText: text)

    let lineCount = text.split(separator: "\n").count
    for i in 0..<lineCount {
      XCTAssertEqual(mask.ruleState("rule1", at: location(ofLine: i)), .disabled)
      XCTAssertEqual(mask.ruleState("rule2", at: location(ofLine: i)), .disabled)
      XCTAssertEqual(mask.ruleState("rule3", at: location(ofLine: i)), .disabled)
    }
  }
}
