import Foundation
import SwiftSyntax
import XCTest

@testable import SwiftFormatRules

public class DoNotUseSemicolonsTests: DiagnosingTestCase {
  public func testSemicolonUse() {
    XCTAssertFormatting(
      DoNotUseSemicolons.self,
      input: """
             print("hello"); print("goodbye");
             print("3")
             """,
      expected: """
                print("hello")
                print("goodbye")
                print("3")
                """)
  }
}
