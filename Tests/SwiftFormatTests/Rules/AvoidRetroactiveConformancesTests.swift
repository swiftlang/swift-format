import _SwiftFormatTestSupport

@_spi(Rules) import SwiftFormat

final class AvoidRetroactiveConformancesTests: LintOrFormatRuleTestCase {
  func testRetroactiveConformanceIsDiagnosed() {
    assertLint(
      AvoidRetroactiveConformances.self,
      """
      extension Int: 1️⃣@retroactive Identifiable {}
      """,
      findings: [
        FindingSpec("1️⃣", message: "do not declare retroactive conformances"),
      ]
    )
  }
}
