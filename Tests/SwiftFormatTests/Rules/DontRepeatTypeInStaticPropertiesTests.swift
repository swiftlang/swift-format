import _SwiftFormatTestSupport

@_spi(Rules) import SwiftFormat

// FIXME: These diagnostics should be on the variable name, not at the beginning of the declaration.
final class DontRepeatTypeInStaticPropertiesTests: LintOrFormatRuleTestCase {
  func testRepetitiveProperties() {
    assertLint(
      DontRepeatTypeInStaticProperties.self,
      """
      public class UIColor {
        1️⃣static let redColor: UIColor
        2️⃣public class var blueColor: UIColor
        var yellowColor: UIColor
        static let green: UIColor
        public class var purple: UIColor
      }
      enum Sandwich {
        3️⃣static let bolognaSandwich: Sandwich
        4️⃣static var hamSandwich: Sandwich
        static var turkey: Sandwich
      }
      protocol RANDPerson {
        var oldPerson: Person
        5️⃣static let youngPerson: Person
      }
      struct TVGame {
        6️⃣static var basketballGame: TVGame
        7️⃣static var baseballGame: TVGame
        static let soccer: TVGame
        let hockey: TVGame
      }
      extension URLSession {
        8️⃣class var sharedSession: URLSession
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: "remove the suffix 'Color' from the name of the variable 'redColor'"),
        FindingSpec("2️⃣", message: "remove the suffix 'Color' from the name of the variable 'blueColor'"),
        FindingSpec("3️⃣", message: "remove the suffix 'Sandwich' from the name of the variable 'bolognaSandwich'"),
        FindingSpec("4️⃣", message: "remove the suffix 'Sandwich' from the name of the variable 'hamSandwich'"),
        FindingSpec("5️⃣", message: "remove the suffix 'Person' from the name of the variable 'youngPerson'"),
        FindingSpec("6️⃣", message: "remove the suffix 'Game' from the name of the variable 'basketballGame'"),
        FindingSpec("7️⃣", message: "remove the suffix 'Game' from the name of the variable 'baseballGame'"),
        FindingSpec("8️⃣", message: "remove the suffix 'Session' from the name of the variable 'sharedSession'"),
      ]
    )
  }

  func testDoNotDiagnoseUnrelatedType() {
    assertLint(
      DontRepeatTypeInStaticProperties.self,
      """
      extension A {
        static let b = C()
      }
      """,
      findings: []
    )
  }

  func testDottedExtendedType() {
    assertLint(
      DontRepeatTypeInStaticProperties.self,
      """
      extension Dotted.Thing {
        1️⃣static let defaultThing: Dotted.Thing
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: "remove the suffix 'Thing' from the name of the variable 'defaultThing'"),
      ]
    )
  }
}
