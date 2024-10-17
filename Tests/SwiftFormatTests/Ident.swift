@_spi(Rules) import SwiftFormat
import _SwiftFormatTestSupport

final class IdentifiersMustBeASCIITests: LintOrFormatRuleTestCase {
  func testInvalidIdentifiers() {
    assertLint(
      IdentifiersMustBeASCII.self,
      """
      let Te$t = 1
      var 1️⃣fo😎o = 2
      let 2️⃣Δx = newX - previousX
      var 3️⃣🤩😆 = 20
      """,
      findings: [
        FindingSpec("1️⃣", message: "remove non-ASCII characters from 'fo😎o': 😎"),
        // TODO: It would be nice to allow Δ (among other mathematically meaningful symbols) without
        // a lot of special cases; investigate this.
        FindingSpec("2️⃣", message: "remove non-ASCII characters from 'Δx': Δ"),
        FindingSpec("3️⃣", message: "remove non-ASCII characters from '🤩😆': 🤩, 😆"),
      ]
    )
  }
}
