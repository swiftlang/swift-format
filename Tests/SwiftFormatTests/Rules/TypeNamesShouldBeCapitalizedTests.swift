@_spi(Rules) import SwiftFormat
import _SwiftFormatTestSupport

final class TypeNamesShouldBeCapitalizedTests: LintOrFormatRuleTestCase {
  func testConstruction() {
    assertLint(
      TypeNamesShouldBeCapitalized.self,
      """
      struct 1️⃣a {}
      class 2️⃣klassName {
        struct 3️⃣subType {}
      }
      protocol 4️⃣myProtocol {}

      extension myType {
        struct 5️⃣innerType {}
      }
      """,
      findings: [
        FindingSpec(
          "1️⃣",
          message: "rename the struct 'a' using UpperCamelCase; for example, 'A'",
          severity: .convention
        ),
        FindingSpec(
          "2️⃣",
          message: "rename the class 'klassName' using UpperCamelCase; for example, 'KlassName'",
          severity: .convention
        ),
        FindingSpec(
          "3️⃣",
          message: "rename the struct 'subType' using UpperCamelCase; for example, 'SubType'",
          severity: .convention
        ),
        FindingSpec(
          "4️⃣",
          message: "rename the protocol 'myProtocol' using UpperCamelCase; for example, 'MyProtocol'",
          severity: .convention
        ),
        FindingSpec(
          "5️⃣",
          message: "rename the struct 'innerType' using UpperCamelCase; for example, 'InnerType'",
          severity: .convention
        ),
      ]
    )
  }

  func testActors() {
    assertLint(
      TypeNamesShouldBeCapitalized.self,
      """
      actor 1️⃣myActor {}
      actor OtherActor {}
      distributed actor 2️⃣greeter {}
      distributed actor DistGreeter {}
      """,
      findings: [
        FindingSpec(
          "1️⃣",
          message: "rename the actor 'myActor' using UpperCamelCase; for example, 'MyActor'",
          severity: .convention
        ),
        FindingSpec(
          "2️⃣",
          message: "rename the actor 'greeter' using UpperCamelCase; for example, 'Greeter'",
          severity: .convention
        ),
      ]
    )
  }

  func testAssociatedTypeandTypeAlias() {
    assertLint(
      TypeNamesShouldBeCapitalized.self,
      """
      protocol P {
        associatedtype 1️⃣kind
        associatedtype OtherKind
      }

      typealias 2️⃣x = Int
      typealias Y = String

      struct MyType {
        typealias 3️⃣data<T> = Y

        func test() {
          typealias Value<T> = Y
        }
      }
      """,
      findings: [
        FindingSpec(
          "1️⃣",
          message: "rename the associated type 'kind' using UpperCamelCase; for example, 'Kind'",
          severity: .convention
        ),
        FindingSpec(
          "2️⃣",
          message: "rename the type alias 'x' using UpperCamelCase; for example, 'X'",
          severity: .convention
        ),
        FindingSpec(
          "3️⃣",
          message: "rename the type alias 'data' using UpperCamelCase; for example, 'Data'",
          severity: .convention
        ),
      ]
    )
  }

  func testThatUnderscoredNamesAreDiagnosed() {
    assertLint(
      TypeNamesShouldBeCapitalized.self,
      """
      protocol 1️⃣_p {
        associatedtype 2️⃣_value
        associatedtype __Value
      }

      protocol ___Q {
      }

      struct 3️⃣_data {
        typealias 4️⃣_x = Int
      }

      struct _Data {}

      actor 5️⃣_internalActor {}

      enum 6️⃣__e {
      }

      enum _OtherE {
      }

      func test() {
        class 7️⃣_myClass {}
        do {
          class _MyClass {}
        }
      }

      distributed actor 8️⃣__greeter {}
      distributed actor __InternalGreeter {}
      """,
      findings: [
        FindingSpec(
          "1️⃣",
          message: "rename the protocol '_p' using UpperCamelCase; for example, '_P'",
          severity: .convention
        ),
        FindingSpec(
          "2️⃣",
          message: "rename the associated type '_value' using UpperCamelCase; for example, '_Value'",
          severity: .convention
        ),
        FindingSpec(
          "3️⃣",
          message: "rename the struct '_data' using UpperCamelCase; for example, '_Data'",
          severity: .convention
        ),
        FindingSpec(
          "4️⃣",
          message: "rename the type alias '_x' using UpperCamelCase; for example, '_X'",
          severity: .convention
        ),
        FindingSpec(
          "5️⃣",
          message: "rename the actor '_internalActor' using UpperCamelCase; for example, '_InternalActor'",
          severity: .convention
        ),
        FindingSpec(
          "6️⃣",
          message: "rename the enum '__e' using UpperCamelCase; for example, '__E'",
          severity: .convention
        ),
        FindingSpec(
          "7️⃣",
          message: "rename the class '_myClass' using UpperCamelCase; for example, '_MyClass'",
          severity: .convention
        ),
        FindingSpec(
          "8️⃣",
          message: "rename the actor '__greeter' using UpperCamelCase; for example, '__Greeter'",
          severity: .convention
        ),
      ]
    )
  }
}
