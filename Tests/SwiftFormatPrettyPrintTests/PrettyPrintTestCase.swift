import SwiftFormatConfiguration
import SwiftFormatCore
import SwiftSyntax
import XCTest

@testable import SwiftFormatPrettyPrint

public class PrettyPrintTestCase: XCTestCase {

  public func assertPrettyPrintEqual(
    input: String,
    expected: String,
    linelength: Int,
    configuration: Configuration = Configuration(),
    file: StaticString = #file,
    line: UInt = #line
  ) {
    configuration.lineLength = linelength

    let context = Context(
      configuration: configuration,
      diagnosticEngine: nil,
      fileURL: URL(fileURLWithPath: "/tmp/file.swift"),
      sourceText: input)

    // Assert that the input, when formatted, is what we expected.
    if let formatted = prettyPrintedSource(input, context: context) {
      XCTAssertEqual(
        expected, formatted,
        "Pretty-printed result was not what was expected",
        file: file, line: line)

      // Idempotency check: Running the formatter multiple times should not change the outcome.
      // Assert that running the formatter again on the previous result keeps it the same.
      if let reformatted = prettyPrintedSource(formatted, context: context) {
        XCTAssertEqual(
          formatted, reformatted, "Pretty printer is not idempotent", file: file, line: line)
      }
    }
  }

  /// Returns the given source code reformatted with the pretty printer.
  private func prettyPrintedSource(_ original: String, context: Context) -> String? {
    do {
      let syntax = try SyntaxParser.parse(source: original)
      let printer = PrettyPrinter(context: context, node: syntax, printTokenStream: false)
      return printer.prettyPrint()
    } catch {
      XCTFail("Parsing failed with error: \(error)")
      return nil
    }
  }
}
