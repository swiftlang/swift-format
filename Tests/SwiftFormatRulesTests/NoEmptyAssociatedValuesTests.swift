import Foundation
import SwiftSyntax
import XCTest

@testable import SwiftFormatRules

public class NoEmptyAssociatedValuesTests: DiagnosingTestCase {
    func testEmptyAssociatedValue() {
        XCTAssertFormatting(NoEmptyAssociatedValues.self,
                            input: """
                               enum CompassPoint {
                                 case north
                                 private case east()
                                 case south(String)
                                 indirect case west
                                 case northeast()
                               }
                               """,
                            expected: """
                                  enum CompassPoint {
                                    case north
                                    private case east
                                    case south(String)
                                    indirect case west
                                    case northeast
                                  }
                                  """)
    }
}
