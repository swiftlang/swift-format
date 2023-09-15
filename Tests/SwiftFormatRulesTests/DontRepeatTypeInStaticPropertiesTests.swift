import SwiftFormatRules

final class DontRepeatTypeInStaticPropertiesTests: LintOrFormatRuleTestCase {
  func testRepetitiveProperties() {
    let input =
      """
      public class UIColor {
        static let redColor: UIColor
        public class var blueColor: UIColor
        var yellowColor: UIColor
        static let green: UIColor
        public class var purple: UIColor
      }
      enum Sandwich {
        static let bolognaSandwich: Sandwich
        static var hamSandwich: Sandwich
        static var turkey: Sandwich
      }
      protocol RANDPerson {
        var oldPerson: Person
        static let youngPerson: Person
      }
      struct TVGame {
        static var basketballGame: TVGame
        static var baseballGame: TVGame
        static let soccer: TVGame
        let hockey: TVGame
      }
      extension URLSession {
        class var sharedSession: URLSession
      }
      """

    performLint(DontRepeatTypeInStaticProperties.self, input: input)
    XCTAssertDiagnosed(.removeTypeFromName(name: "redColor", type: "Color"))
    XCTAssertDiagnosed(.removeTypeFromName(name: "blueColor", type: "Color"))
    XCTAssertNotDiagnosed(.removeTypeFromName(name: "yellowColor", type: "Color"))
    XCTAssertNotDiagnosed(.removeTypeFromName(name: "green", type: "Color"))
    XCTAssertNotDiagnosed(.removeTypeFromName(name: "purple", type: "Color"))
    
    XCTAssertDiagnosed(.removeTypeFromName(name: "bolognaSandwich", type: "Sandwich"))
    XCTAssertDiagnosed(.removeTypeFromName(name: "hamSandwich", type: "Sandwich"))
    XCTAssertNotDiagnosed(.removeTypeFromName(name: "turkey", type: "Sandwich"))
    
    XCTAssertNotDiagnosed(.removeTypeFromName(name: "oldPerson", type: "Person"))
    XCTAssertDiagnosed(.removeTypeFromName(name: "youngPerson", type: "Person"))
    
    XCTAssertDiagnosed(.removeTypeFromName(name: "basketballGame", type: "Game"))
    XCTAssertDiagnosed(.removeTypeFromName(name: "baseballGame", type: "Game"))
    XCTAssertNotDiagnosed(.removeTypeFromName(name: "soccer", type: "Game"))
    XCTAssertNotDiagnosed(.removeTypeFromName(name: "hockey", type: "Game"))
    
    XCTAssertDiagnosed(.removeTypeFromName(name: "sharedSession", type: "Session"))
  }

  func testSR11123() {
    let input =
      """
      extension A {
        static let b = C()
      }
      """

    performLint(DontRepeatTypeInStaticProperties.self, input: input)
    XCTAssertNotDiagnosed(.removeTypeFromName(name: "b", type: "A"))
  }

  func testDottedExtendedType() {
    let input =
      """
      extension Dotted.Thing {
        static let defaultThing: Dotted.Thing
      }
      """

    performLint(DontRepeatTypeInStaticProperties.self, input: input)
    XCTAssertDiagnosed(.removeTypeFromName(name: "defaultThing", type: "Thing"))
  }
}
