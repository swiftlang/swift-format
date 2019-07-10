import Foundation
import SwiftSyntax
import XCTest

@testable import SwiftFormatRules

public class ReturnVoidInsteadOfEmptyTupleTests: DiagnosingTestCase {
  public func testEmptyTupleReturns() {
    XCTAssertFormatting(
      ReturnVoidInsteadOfEmptyTuple.self,
      input: """
             let callback: () -> ()
             typealias x = Int -> ()
             func y() -> Int -> () { return }
             func z(d: Bool -> ()) {}
             """,
      expected: """
                let callback: () -> Void
                typealias x = Int -> Void
                func y() -> Int -> Void { return }
                func z(d: Bool -> Void) {}
                """)
  }
}
