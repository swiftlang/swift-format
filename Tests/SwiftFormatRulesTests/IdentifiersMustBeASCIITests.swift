import SwiftFormatRules

final class IdentifiersMustBeASCIITests: LintOrFormatRuleTestCase {
  func testInvalidIdentifiers() {
    let input =
    """
      let Te$t = 1
      var fo😎o = 2
      let Δx = newX - previousX
      var 🤩😆 = 20
      """
    performLint(IdentifiersMustBeASCII.self, input: input)
    XCTAssertDiagnosed(.nonASCIICharsNotAllowed(["😎"],"fo😎o"))
    // TODO: It would be nice to allow Δ (among other mathematically meaningful symbols) without
    // a lot of special cases; investigate this.
    XCTAssertDiagnosed(.nonASCIICharsNotAllowed(["Δ"],"Δx"))
    XCTAssertDiagnosed(.nonASCIICharsNotAllowed(["🤩", "😆"], "🤩😆"))
  }
}
