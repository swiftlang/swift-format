import SwiftSyntax
import XCTest

@testable import SwiftFormatRules

public class AvoidInitializersForLiteralsTests: DiagnosingTestCase {
  public func testInitializersForLiterals() {
    let input =
      """
      let v1 = UInt32(76)
      let v2 = UInt8(257)
      performFunction(x: Int16(54))
      performFunction(x: Int32(54))
      performFunction(x: Int64(54))
      let c = Character("s")
      if 3 > Int(2) || someCondition {}
      let a = Int(bitPattern: 123456)
      """

    performLint(AvoidInitializersForLiterals.self, input: input)
    XCTAssertDiagnosed(.avoidInitializerStyleCast("UInt32(76)"))
    XCTAssertDiagnosed(.avoidInitializerStyleCast("UInt8(257)"))
    XCTAssertDiagnosed(.avoidInitializerStyleCast("Int16(54)"))
    XCTAssertDiagnosed(.avoidInitializerStyleCast("Int32(54)"))
    XCTAssertDiagnosed(.avoidInitializerStyleCast("Int64(54)"))
    XCTAssertDiagnosed(.avoidInitializerStyleCast("Character(\"s\")"))
    XCTAssertDiagnosed(.avoidInitializerStyleCast("Int(2) "))
    XCTAssertNotDiagnosed(.avoidInitializerStyleCast("Int(bitPattern: 123456)"))
  }
}
