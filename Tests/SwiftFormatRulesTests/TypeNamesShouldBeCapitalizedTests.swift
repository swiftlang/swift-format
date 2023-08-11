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

  func testActors() {
    let input =
      """
      actor myActor {}
      actor OtherActor {}
      distributed actor greeter {}
      distributed actor DistGreeter {}
      """

    performLint(TypeNamesShouldBeCapitalized.self, input: input)

    XCTAssertDiagnosed(.capitalizeTypeName(name: "myActor"))
    XCTAssertNotDiagnosed(.capitalizeTypeName(name: "OtherActor"))
    XCTAssertDiagnosed(.capitalizeTypeName(name: "greeter"))
    XCTAssertNotDiagnosed(.capitalizeTypeName(name: "DistGreeter"))
  }

  func testAssociatedTypeandTypeAlias() {
    let input =
      """
      protocol P {
        associatedtype kind
        associatedtype OtherKind
      }

      typealias x = Int
      typealias Y = String

      struct MyType {
        typealias data<T> = Y

        func test() {
          typealias Value<T> = Y
        }
      }
      """

    performLint(TypeNamesShouldBeCapitalized.self, input: input)

    XCTAssertDiagnosed(.capitalizeTypeName(name: "kind"))
    XCTAssertNotDiagnosed(.capitalizeTypeName(name: "OtherKind"))
    XCTAssertDiagnosed(.capitalizeTypeName(name: "x"))
    XCTAssertNotDiagnosed(.capitalizeTypeName(name: "Y"))
    XCTAssertDiagnosed(.capitalizeTypeName(name: "data"))
    XCTAssertNotDiagnosed(.capitalizeTypeName(name: "Value"))
  }
}
