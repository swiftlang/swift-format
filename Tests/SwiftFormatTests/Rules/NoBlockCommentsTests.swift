@_spi(Rules) import SwiftFormat
import _SwiftFormatTestSupport

final class NoBlockCommentsTests: LintOrFormatRuleTestCase {
  func testDiagnoseBlockComments() {
    assertLint(
      NoBlockComments.self,
      """
      1️⃣/*
      Lorem ipsum dolor sit amet, at nonumes adipisci sea, natum
      offendit vis ex. Audiam legendos expetenda ei quo, nonumes

          msensibus eloquentiam ex vix.
      */
      let a = 2️⃣/*ff*/10  3️⃣/*ff*/ + 10
      var b = 04️⃣/*Block Comment inline with code*/

      5️⃣/*

      Block Comment
      */
      let c = a + b
      6️⃣/* This is the end
      of a file

      */
      """,
      findings: [
        FindingSpec("1️⃣", message: "replace this block comment with line comments"),
        FindingSpec("2️⃣", message: "replace this block comment with line comments"),
        FindingSpec("3️⃣", message: "replace this block comment with line comments"),
        FindingSpec("4️⃣", message: "replace this block comment with line comments"),
        FindingSpec("5️⃣", message: "replace this block comment with line comments"),
        FindingSpec("6️⃣", message: "replace this block comment with line comments"),
      ]
    )
  }
}
