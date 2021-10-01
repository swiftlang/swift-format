import SwiftFormat
import SwiftSyntax
import SwiftSyntaxParser
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

  func testInvalidSyntax() {
    var input =
      """
      class {TemplateName} {
        var bar = 0
      }
      """
    assertInvalidSyntax(in: input, atLine: 1, column: 1)

    input =
      """
      switch a {
      @unknown what_is_this default: break
      }
      """
    assertInvalidSyntax(in: input, atLine: 1, column: 1)
  }

  /// Parses the given source into a syntax tree.
  private func createSyntax(from source: String) -> Syntax {
    return Syntax(try! SyntaxParser.parse(source: source))
  }

  /// Asserts that `SyntaxValidatingVisitor` finds invalid syntax in the given source code at the
  /// given line and column.
  private func assertInvalidSyntax(
    in source: String, atLine: Int, column: Int, file: StaticString = #file, line: UInt = #line
  ) {
    guard let position = _firstInvalidSyntaxPosition(in: createSyntax(from: source)) else {
      XCTFail("No invalid syntax was found", file: file, line: line)
      return
    }
    let location = SourceLocationConverter(file: "", source: source).location(for: position)
    XCTAssertEqual(location.line, atLine, file: file, line: line)
    XCTAssertEqual(location.column, column, file: file, line: line)
  }
}
