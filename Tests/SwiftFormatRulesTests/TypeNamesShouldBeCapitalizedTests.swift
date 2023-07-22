import SwiftFormatRules

final class TypeNamesShouldBeCapitalizedTests: LintOrFormatRuleTestCase {
  func testConstruction() {
    let input =
      """
      struct a {}
      class klassName {
        struct subType {}
      }
      protocol myProtocol {}

      extension myType {
        struct innerType {}
      }
      """

    performLint(TypeNamesShouldBeCapitalized.self, input: input)

    XCTAssertDiagnosed(.capitalizeTypeName(name: "a"))
    XCTAssertDiagnosed(.capitalizeTypeName(name: "klassName"))
    XCTAssertDiagnosed(.capitalizeTypeName(name: "subType"))
    XCTAssertDiagnosed(.capitalizeTypeName(name: "myProtocol"))
    XCTAssertNotDiagnosed(.capitalizeTypeName(name: "myType"))
    XCTAssertDiagnosed(.capitalizeTypeName(name: "innerType"))
  }
}
