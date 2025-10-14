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

@_spi(Rules) import SwiftFormat
import _SwiftFormatTestSupport

final class UseExplicitNilCheckInConditionsTests: LintOrFormatRuleTestCase {
  func testIfExpressions() {
    assertFormatting(
      UseExplicitNilCheckInConditions.self,
      input: """
        if 1️⃣let _ = x {}
        if let x = y, 2️⃣let _ = x.m {}
        if let x = y {} else if 3️⃣let _ = z {}
        """,
      expected: """
        if x != nil {}
        if let x = y, x.m != nil {}
        if let x = y {} else if z != nil {}
        """,
      findings: [
        FindingSpec("1️⃣", message: "compare this value using `!= nil` instead of binding and discarding it"),
        FindingSpec("2️⃣", message: "compare this value using `!= nil` instead of binding and discarding it"),
        FindingSpec("3️⃣", message: "compare this value using `!= nil` instead of binding and discarding it"),
      ]
    )
  }

  func testGuardStatements() {
    assertFormatting(
      UseExplicitNilCheckInConditions.self,
      input: """
        guard 1️⃣let _ = x else {}
        guard let x = y, 2️⃣let _ = x.m else {}
        """,
      expected: """
        guard x != nil else {}
        guard let x = y, x.m != nil else {}
        """,
      findings: [
        FindingSpec("1️⃣", message: "compare this value using `!= nil` instead of binding and discarding it"),
        FindingSpec("2️⃣", message: "compare this value using `!= nil` instead of binding and discarding it"),
      ]
    )
  }

  func testWhileStatements() {
    assertFormatting(
      UseExplicitNilCheckInConditions.self,
      input: """
        while 1️⃣let _ = x {}
        while let x = y, 2️⃣let _ = x.m {}
        """,
      expected: """
        while x != nil {}
        while let x = y, x.m != nil {}
        """,
      findings: [
        FindingSpec("1️⃣", message: "compare this value using `!= nil` instead of binding and discarding it"),
        FindingSpec("2️⃣", message: "compare this value using `!= nil` instead of binding and discarding it"),
      ]
    )
  }

  func testTriviaPreservation() {
    assertFormatting(
      UseExplicitNilCheckInConditions.self,
      input: """
        if /*comment*/ 1️⃣let _ = x /*comment*/ {}
        if 2️⃣let _ = x // comment
        {}
        """,
      expected: """
        if /*comment*/ x != nil /*comment*/ {}
        if x != nil // comment
        {}
        """,
      findings: [
        FindingSpec("1️⃣", message: "compare this value using `!= nil` instead of binding and discarding it"),
        FindingSpec("2️⃣", message: "compare this value using `!= nil` instead of binding and discarding it"),
      ]
    )
  }

  func testDoNotDropTrailingCommaInConditionList() {
    assertFormatting(
      UseExplicitNilCheckInConditions.self,
      input: """
        if 1️⃣let _ = x, 2️⃣let _ = y {}
        """,
      expected: """
        if x != nil, y != nil {}
        """,
      findings: [
        FindingSpec("1️⃣", message: "compare this value using `!= nil` instead of binding and discarding it"),
        FindingSpec("2️⃣", message: "compare this value using `!= nil` instead of binding and discarding it"),
      ]
    )
  }

  func testAddNecessaryParenthesesAroundTryExpr() {
    assertFormatting(
      UseExplicitNilCheckInConditions.self,
      input: """
        if 1️⃣let _ = try? x {}
        if 2️⃣let _ = try x {}
        """,
      expected: """
        if (try? x) != nil {}
        if (try x) != nil {}
        """,
      findings: [
        FindingSpec("1️⃣", message: "compare this value using `!= nil` instead of binding and discarding it"),
        FindingSpec("2️⃣", message: "compare this value using `!= nil` instead of binding and discarding it"),
      ]
    )
  }

  func testAddNecessaryParenthesesAroundTernaryExpr() {
    assertFormatting(
      UseExplicitNilCheckInConditions.self,
      input: """
        if 1️⃣let _ = x ? y : z {}
        """,
      expected: """
        if (x ? y : z) != nil {}
        """,
      findings: [
        FindingSpec("1️⃣", message: "compare this value using `!= nil` instead of binding and discarding it")
      ]
    )
  }

  func testAddNecessaryParenthesesAroundSameOrLowerPrecedenceOperator() {
    // The use of `&&` and `==` are semantically meaningless here because they don't return
    // optionals. We just need them to stand in for any potential custom operator with lower or same
    // precedence, respectively.
    assertFormatting(
      UseExplicitNilCheckInConditions.self,
      input: """
        if 1️⃣let _ = x && y {}
        if 2️⃣let _ = x == y {}
        """,
      expected: """
        if (x && y) != nil {}
        if (x == y) != nil {}
        """,
      findings: [
        FindingSpec("1️⃣", message: "compare this value using `!= nil` instead of binding and discarding it"),
        FindingSpec("2️⃣", message: "compare this value using `!= nil` instead of binding and discarding it"),
      ]
    )
  }

  func testTypeAnnotations() {
    assertFormatting(
      UseExplicitNilCheckInConditions.self,
      input: """
        if let _: F = foo() {}
        if let _: S? = foo() {}
        """,
      expected: """
        if let _: F = foo() {}
        if let _: S? = foo() {}
        """
    )
  }
}
