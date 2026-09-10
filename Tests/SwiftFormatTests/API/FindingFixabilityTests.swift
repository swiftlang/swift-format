//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import SwiftFormat
@_spi(Rules) import SwiftFormat
import XCTest
@_spi(Testing) import _SwiftFormatTestSupport

final class FindingFixabilityTests: XCTestCase {
  func testLintRuleFindingsAreNotFixable() throws {
    let findings = try lint(
      "let value = optional!\n",
      configuration: Configuration.forTesting(enabledRule: NeverForceUnwrap.ruleName)
    )

    let finding = try XCTUnwrap(findings.first { "\($0.category)" == NeverForceUnwrap.ruleName })
    XCTAssertFalse(finding.isFixable)
  }

  func testFormatRuleFindingsAreFixableByDefault() throws {
    let findings = try lint(
      """
      func f() {
        if (true) {}
      }
      """,
      configuration: Configuration.forTesting(enabledRule: NoParensAroundConditions.ruleName)
    )

    let finding = try XCTUnwrap(findings.first { "\($0.category)" == NoParensAroundConditions.ruleName })
    XCTAssertTrue(finding.isFixable)
  }

  func testWhitespaceFindingsAreFixable() throws {
    let findings = try lint(
      """
      struct Foo {
        var value:Int
      }
      """,
      configuration: Configuration.forTesting
    )

    let finding = try XCTUnwrap(findings.first { "\($0.category)" == "Spacing" })
    XCTAssertTrue(finding.isFixable)
  }

  func testFormatRuleCanEmitNonFixableFinding() throws {
    let findings = try lint(
      """
      struct Foo {
        var callback: () -> (/* comment */)
      }
      """,
      configuration: Configuration.forTesting(enabledRule: ReturnVoidInsteadOfEmptyTuple.ruleName)
    )

    let finding = try XCTUnwrap(findings.first { "\($0.category)" == ReturnVoidInsteadOfEmptyTuple.ruleName })
    XCTAssertFalse(finding.isFixable)
  }

  func testAssignmentExpressionFixabilityReflectsFormatterBehavior() throws {
    let findings = try lint(
      """
      func f() {
        while x = 1 {}
        return y = 2
      }
      """,
      configuration: Configuration.forTesting(enabledRule: NoAssignmentInExpressions.ruleName)
    )

    let nonFixableFinding = try XCTUnwrap(
      findings.first { "\($0.category)" == NoAssignmentInExpressions.ruleName && $0.location?.line == 2 }
    )
    XCTAssertFalse(nonFixableFinding.isFixable)

    let fixableFinding = try XCTUnwrap(
      findings.first { "\($0.category)" == NoAssignmentInExpressions.ruleName && $0.location?.line == 3 }
    )
    XCTAssertTrue(fixableFinding.isFixable)
  }

  func testInvalidMultipleVariableDeclarationFindingIsNotFixable() throws {
    let findings = try lint(
      """
      func f() {
        var a, b = 1
      }
      """,
      configuration: Configuration.forTesting(enabledRule: OneVariableDeclarationPerLine.ruleName)
    )

    let finding = try XCTUnwrap(findings.first { "\($0.category)" == OneVariableDeclarationPerLine.ruleName })
    XCTAssertFalse(finding.isFixable)
  }

  private func lint(_ source: String, configuration: Configuration) throws -> [Finding] {
    var findings = [Finding]()
    let linter = SwiftLinter(
      configuration: configuration,
      findingConsumer: { findings.append($0) }
    )
    try linter.lint(
      source: source,
      assumingFileURL: URL(fileURLWithPath: "/tmp/test.swift")
    )
    return findings
  }
}
