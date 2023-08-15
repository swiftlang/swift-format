import SwiftFormatRules

final class NoBlockCommentsTests: LintOrFormatRuleTestCase {
  func testDiagnoseBlockComments() {
    let input =
      """
      /*
      Lorem ipsum dolor sit amet, at nonumes adipisci sea, natum
      offendit vis ex. Audiam legendos expetenda ei quo, nonumes

          msensibus eloquentiam ex vix.
      */
      let a = /*ff*/10  /*ff*/ + 10
      var b = 0/*Block Comment inline with code*/

      /*

      Block Comment
      */
      let c = a + b
      /* This is the end
      of a file

      */
      """
    performLint(NoBlockComments.self, input: input)
    XCTAssertDiagnosed(.avoidBlockComment)
    XCTAssertDiagnosed(.avoidBlockComment)
    XCTAssertDiagnosed(.avoidBlockComment)
    XCTAssertDiagnosed(.avoidBlockComment)
    XCTAssertDiagnosed(.avoidBlockComment)
    XCTAssertDiagnosed(.avoidBlockComment)
  }
}
