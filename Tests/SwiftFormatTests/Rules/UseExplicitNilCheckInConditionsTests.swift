import _SwiftFormatTestSupport

@_spi(Rules) import SwiftFormat

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
}
