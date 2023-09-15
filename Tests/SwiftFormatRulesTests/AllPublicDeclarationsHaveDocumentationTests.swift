import SwiftFormatRules

final class AllPublicDeclarationsHaveDocumentationTests: LintOrFormatRuleTestCase {
  func testPublicDeclsWithoutDocs() {
    let input =
      """
      public func lightswitchRave() {
      }

      public var isSblounskched: Int {
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
      """
    performLint(AllPublicDeclarationsHaveDocumentation.self, input: input)
    XCTAssertDiagnosed(.declRequiresComment("lightswitchRave()"))
    XCTAssertDiagnosed(.declRequiresComment("isSblounskched"))
    XCTAssertNotDiagnosed(.declRequiresComment("fhqwhgads()"))
    XCTAssertNotDiagnosed(.declRequiresComment("isDelorted"))
  }
}
