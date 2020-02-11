import SwiftSyntax
import XCTest

@testable import SwiftFormat

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
    XCTAssertTrue(isSyntaxValidForProcessing(createSyntax(from: input)))
  }

  func testInvalidSyntax() {
    var input =
      """
      class {TemplateName} {
        var bar = 0
      }
      """
    XCTAssertFalse(isSyntaxValidForProcessing(createSyntax(from: input)))

    input =
      """
      switch a {
      case b, c, d: break
      @unknown what_is_this default: break
      }
      """
    XCTAssertFalse(isSyntaxValidForProcessing(createSyntax(from: input)))

    input =
      """
      @unknown c class Foo {}
      """
    XCTAssertFalse(isSyntaxValidForProcessing(createSyntax(from: input)))
  }

  /// Parses the given source into a syntax tree.
  private func createSyntax(from source: String) -> Syntax {
    return Syntax(try! SyntaxParser.parse(source: source))
  }
}
