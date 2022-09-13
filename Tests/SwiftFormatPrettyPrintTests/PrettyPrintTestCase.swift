import SwiftFormatConfiguration
import SwiftFormatCore
import SwiftFormatPrettyPrint
import SwiftFormatTestSupport
import SwiftSyntax
import SwiftParser
import XCTest

class PrettyPrintTestCase: DiagnosingTestCase {
  /// Asserts that the input string, when pretty printed, is equal to the expected string.
  ///
  /// - Parameters:
  ///   - input: The input text to pretty print.
  ///   - expected: The expected pretty-printed output.
  ///   - linelength: The maximum allowed line length of the output.
  ///   - configuration: The formatter configuration.
  ///   - whitespaceOnly: If true, the pretty printer should only apply whitespace changes and omit
  ///     changes that insert or remove non-whitespace characters (like trailing commas).
  ///   - file: The file in which failure occurred. Defaults to the file name of the test case in
  ///     which this function was called.
  ///   - line: The line number on which failure occurred. Defaults to the line number on which this
  ///     function was called.
  final func assertPrettyPrintEqual(
    input: String,
    expected: String,
    linelength: Int,
    configuration: Configuration = Configuration(),
    whitespaceOnly: Bool = false,
    file: StaticString = #file,
    line: UInt = #line
  ) {
    var configuration = configuration
    configuration.lineLength = linelength

    // Assert that the input, when formatted, is what we expected.
    if let formatted = prettyPrintedSource(
      input, configuration: configuration, whitespaceOnly: whitespaceOnly)
    {
      XCTAssertStringsEqualWithDiff(
        formatted, expected,
        "Pretty-printed result was not what was expected",
        file: file, line: line)

      // Idempotency check: Running the formatter multiple times should not change the outcome.
      // Assert that running the formatter again on the previous result keeps it the same.
      stopTrackingDiagnostics()
      if let reformatted = prettyPrintedSource(
        formatted, configuration: configuration, whitespaceOnly: whitespaceOnly)
      {
        XCTAssertStringsEqualWithDiff(
          reformatted, formatted, "Pretty printer is not idempotent", file: file, line: line)
      }
    }
  }

  /// Returns the given source code reformatted with the pretty printer.
  ///
  /// - Parameters:
  ///   - source: The source text to pretty print.
  ///   - configuration: The formatter configuration.
  ///   - whitespaceOnly: If true, the pretty printer should only apply whitespace changes and omit
  ///     changes that insert or remove non-whitespace characters (like trailing commas).
  /// - Returns: The pretty-printed text, or nil if an error occurred and a test failure was logged.
  private func prettyPrintedSource(
    _ source: String, configuration: Configuration, whitespaceOnly: Bool
  ) -> String? {
    let sourceFileSyntax: SourceFileSyntax
    do {
      sourceFileSyntax = try Parser.parse(source: source)
    } catch {
      XCTFail("Parsing failed with error: \(error)")
      return nil
    }

    let context = makeContext(sourceFileSyntax: sourceFileSyntax, configuration: configuration)
    let printer = PrettyPrinter(
      context: context,
      operatorContext: OperatorContext.makeBuiltinOperatorContext(),
      node: Syntax(sourceFileSyntax),
      printTokenStream: false,
      whitespaceOnly: whitespaceOnly)
    return printer.prettyPrint()
  }
}
