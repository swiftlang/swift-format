import _SwiftFormatTestSupport

@_spi(Rules) import SwiftFormat

// FIXME: Diagnostics should be emitted at the identifier, not at the start of the declaration.
final class TypeNamesShouldBeCapitalizedTests: LintOrFormatRuleTestCase {
  func testConstruction() {
    assertLint(
      TypeNamesShouldBeCapitalized.self,
      """
      1️⃣struct a {}
      2️⃣class klassName {
        3️⃣struct subType {}
      }
      4️⃣protocol myProtocol {}

      extension myType {
        5️⃣struct innerType {}
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: "type names should be capitalized: a -> A"),
        FindingSpec("2️⃣", message: "type names should be capitalized: klassName -> KlassName"),
        FindingSpec("3️⃣", message: "type names should be capitalized: subType -> SubType"),
        FindingSpec("4️⃣", message: "type names should be capitalized: myProtocol -> MyProtocol"),
        FindingSpec("5️⃣", message: "type names should be capitalized: innerType -> InnerType"),
      ]
    )
  }

  func testActors() {
    assertLint(
      TypeNamesShouldBeCapitalized.self,
      """
      1️⃣actor myActor {}
      actor OtherActor {}
      2️⃣distributed actor greeter {}
      distributed actor DistGreeter {}
      """,
      findings: [
        FindingSpec("1️⃣", message: "type names should be capitalized: myActor -> MyActor"),
        FindingSpec("2️⃣", message: "type names should be capitalized: greeter -> Greeter"),
      ]
    )
  }

  func testAssociatedTypeandTypeAlias() {
    assertLint(
      TypeNamesShouldBeCapitalized.self,
      """
      protocol P {
        1️⃣associatedtype kind
        associatedtype OtherKind
      }

      2️⃣typealias x = Int
      typealias Y = String

      struct MyType {
        3️⃣typealias data<T> = Y

        func test() {
          typealias Value<T> = Y
        }
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: "type names should be capitalized: kind -> Kind"),
        FindingSpec("2️⃣", message: "type names should be capitalized: x -> X"),
        FindingSpec("3️⃣", message: "type names should be capitalized: data -> Data"),
      ]
    )
  }

  func testThatUnderscoredNamesAreDiagnosed() {
    assertLint(
      TypeNamesShouldBeCapitalized.self,
      """
      1️⃣protocol _p {
        2️⃣associatedtype _value
        associatedtype __Value
      }

      protocol ___Q {
      }

      3️⃣struct _data {
        4️⃣typealias _x = Int
      }

      struct _Data {}

      5️⃣actor _internalActor {}

      6️⃣enum __e {
      }

      enum _OtherE {
      }

      func test() {
        7️⃣class _myClass {}
        do {
          class _MyClass {}
        }
      }

      8️⃣distributed actor __greeter {}
      distributed actor __InternalGreeter {}
      """,
      findings: [
        FindingSpec("1️⃣", message: "type names should be capitalized: _p -> _P"),
        FindingSpec("2️⃣", message: "type names should be capitalized: _value -> _Value"),
        FindingSpec("3️⃣", message: "type names should be capitalized: _data -> _Data"),
        FindingSpec("4️⃣", message: "type names should be capitalized: _x -> _X"),
        FindingSpec("5️⃣", message: "type names should be capitalized: _internalActor -> _InternalActor"),
        FindingSpec("6️⃣", message: "type names should be capitalized: __e -> __E"),
        FindingSpec("7️⃣", message: "type names should be capitalized: _myClass -> _MyClass"),
        FindingSpec("8️⃣", message: "type names should be capitalized: __greeter -> __Greeter"),
      ]
    )
  }
}
