import _SwiftFormatTestSupport

@_spi(Rules) import SwiftFormat

final class AllPublicDeclarationsHaveDocumentationTests: LintOrFormatRuleTestCase {
  func testPublicDeclsWithoutDocs() {
    assertLint(
      AllPublicDeclarationsHaveDocumentation.self,
      """
      1️⃣public func lightswitchRave() {
      }

      2️⃣public var isSblounskched: Int {
        return 0
      }

      /// Everybody to the limit.
      public func fhqwhgads() {
      }

      /**
       * Determines if an email was delorted.
       */
      public var isDelorted: Bool {
        return false
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: "add a documentation comment for 'lightswitchRave()'"),
        FindingSpec("2️⃣", message: "add a documentation comment for 'isSblounskched'"),
      ]
    )
  }
}
