import SwiftFormat
import SwiftSyntax
import SwiftParser
import XCTest

final class SyntaxValidatingVisitorTests: XCTestCase {
  func testValidSyntax() {
    let input =
      """
      import Foo

      class Bar {}
      let c: (Int) -> Int = { [weak self, weak weakB = b] foo in
        return 0
      }
      switch a {
      case b, c, d: break
      @unknown default: break
      }
      """
    XCTAssertNil(_firstInvalidSyntaxPosition(in: createSyntax(from: input)))
  }

  /// Parses the given source into a syntax tree.
  private func createSyntax(from source: String) -> Syntax {
    return Syntax(try! Parser.parse(source: source))
  }
}
