import Foundation
import SwiftSyntax
import XCTest

@testable import SwiftFormatRules

public class UseShorthandTypeNamesTests: DiagnosingTestCase {
  public func testLongFormNames() {
    XCTAssertFormatting(
      UseShorthandTypeNames.self,
      input: """
             func enumeratedDictionary<Element>(
               from values: Array<Element>,
               start: Optional<Array<Element>.Index> = nil
             ) -> Dictionary<Int, Array<Element>> {
               // Specializer syntax
               Array<Array<Optional<Int>>.Index>.init()
               // More specializer syntax
               Array<[Int]>.init()
             }
             func nestedLongForms(
               x: Array<Dictionary<String, Int>>,
               y: Dictionary<Array<Optional<String>>, Optional<Int>>) {
               Dictionary<Array<Int>.Index, String>.init()
               Dictionary<String, Optional<Float>>.init()
               UnsafePointer<UInt8>.init()
               UnsafeMutablePointer<UInt8>.init()
             }
             """,
      expected: """
                func enumeratedDictionary<Element>(
                  from values: [Element],
                  start: Array<Element>.Index? = nil
                ) -> [Int: [Element]] {
                  // Specializer syntax
                  [Array<Int?>.Index].init()
                  // More specializer syntax
                  [[Int]].init()
                }
                func nestedLongForms(
                  x: [[String: Int]],
                  y: [[String?]: Int?]) {
                  [Array<Int>.Index: String].init()
                  [String: Float?].init()
                  UnsafePointer<UInt8>.init()
                  UnsafeMutablePointer<UInt8>.init()
                }
                """)
    XCTAssertDiagnosed(.useTypeShorthand(type: "Array"))
    XCTAssertDiagnosed(.useTypeShorthand(type: "Dictionary"))
    XCTAssertDiagnosed(.useTypeShorthand(type: "Optional"))
    XCTAssertNotDiagnosed(.useTypeShorthand(type: "UnsafePointer"))
    XCTAssertNotDiagnosed(.useTypeShorthand(type: "UnsafeMutablePointer"))
  }
}
