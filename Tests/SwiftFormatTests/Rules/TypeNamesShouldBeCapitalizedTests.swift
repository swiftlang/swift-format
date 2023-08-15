import SwiftFormat

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

  func testThatUnderscoredNamesAreDiagnosed() {
    let input =
      """
      protocol _p {
        associatedtype _value
        associatedtype __Value
      }

      protocol ___Q {
      }

      struct _data {
        typealias _x = Int
      }

      struct _Data {}

      actor _internalActor {}

      enum __e {
      }

      enum _OtherE {
      }

      func test() {
        class _myClass {}
        do {
          class _MyClass {}
        }
      }

      distributed actor __greeter {}
      distributed actor __InternalGreeter {}
      """

    performLint(TypeNamesShouldBeCapitalized.self, input: input)

    XCTAssertDiagnosed(.capitalizeTypeName(name: "_p"))
    XCTAssertNotDiagnosed(.capitalizeTypeName(name: "___Q"))
    XCTAssertDiagnosed(.capitalizeTypeName(name: "_value"))
    XCTAssertNotDiagnosed(.capitalizeTypeName(name: "__Value"))
    XCTAssertDiagnosed(.capitalizeTypeName(name: "_data"))
    XCTAssertNotDiagnosed(.capitalizeTypeName(name: "_Data"))
    XCTAssertDiagnosed(.capitalizeTypeName(name: "_x"))
    XCTAssertDiagnosed(.capitalizeTypeName(name: "_internalActor"))
    XCTAssertDiagnosed(.capitalizeTypeName(name: "__e"))
    XCTAssertNotDiagnosed(.capitalizeTypeName(name: "__OtherE"))
    XCTAssertDiagnosed(.capitalizeTypeName(name: "_myClass"))
    XCTAssertNotDiagnosed(.capitalizeTypeName(name: "_MyClass"))
    XCTAssertDiagnosed(.capitalizeTypeName(name: "__greeter"))
    XCTAssertNotDiagnosed(.capitalizeTypeName(name: "__InternalGreeter"))
  }
}
