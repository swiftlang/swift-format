import SwiftFormatConfiguration
import SwiftFormatCore
import SwiftFormatPrettyPrint
import SwiftSyntax
import XCTest

class PrettyPrintTestCase: XCTestCase {
  /// A helper that will keep track of which diagnostics have been emitted, and their locations.
  private var consumer: DiagnosticTrackingConsumer? = nil

  /// Implements `DiagnosticConsumer` to keep track which diagnostics have been raised and their
  /// locations.
  private class DiagnosticTrackingConsumer: DiagnosticConsumer {
    var registeredDiagnostics = [(String, line: Int?, column: Int?)]()

    func handle(_ diagnostic: Diagnostic) {
      let loc = diagnostic.location
      registeredDiagnostics.append((diagnostic.message.text, line: loc?.line, column: loc?.column))
    }

    func finalize() {}
  }

  /// Asserts that a specific diagnostic message was emitted. This should be called to check for
  /// diagnostics after `assertPrettyPrintEqual`.
  ///
  /// - Parameters:
  ///   - message: The diagnostic message to check for.
  ///   - line: The line number of the diagnotic message within the ueser's input text.
  ///   - column: The column number of the diagnostic message within the user's input text.
  ///   - file: The file the test resides in (defaults to the current caller's file).
  ///   - sourceLine: The line the test resides in (defaults to the current caller's file).
  final func XCTAssertDiagnosed(
    _ message: Diagnostic.Message,
    line: Int? = nil,
    column: Int? = nil,
    file: StaticString = #file,
    sourceLine: UInt = #line
  ) {
    let maybeIdx = consumer?.registeredDiagnostics.firstIndex {
      $0 == (message.text, line: line, column: column)
    }

    guard let idx = maybeIdx else {
      XCTFail("diagnostic '\(message.text)' not raised", file: file, line: sourceLine)
      return
    }

    consumer?.registeredDiagnostics.remove(at: idx)
  }

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
    let firstPassConsumer = DiagnosticTrackingConsumer()
    consumer = firstPassConsumer

    // Assert that the input, when formatted, is what we expected.
    if let formatted = prettyPrintedSource(
      input, configuration: configuration, whitespaceOnly: whitespaceOnly,
      consumer: firstPassConsumer)
    {
      XCTAssertEqual(
        expected, formatted,
        "Pretty-printed result was not what was expected",
        file: file, line: line)

      // Idempotency check: Running the formatter multiple times should not change the outcome.
      // Assert that running the formatter again on the previous result keeps it the same.
      if let reformatted = prettyPrintedSource(
        formatted, configuration: configuration, whitespaceOnly: whitespaceOnly)
      {
        XCTAssertEqual(
          formatted, reformatted, "Pretty printer is not idempotent", file: file, line: line)
      }
    }
  }

  /// Returns the given source code reformatted with the pretty printer.
  private func prettyPrintedSource(
    _ source: String, configuration: Configuration, whitespaceOnly: Bool,
    consumer: DiagnosticConsumer? = nil
  ) -> String? {
    let sourceFileSyntax: SourceFileSyntax
    do {
      sourceFileSyntax = try SyntaxParser.parse(source: source)
    } catch {
      XCTFail("Parsing failed with error: \(error)")
      return nil
    }

    let context = Context(
      configuration: configuration,
      diagnosticEngine: DiagnosticEngine(),
      fileURL: URL(fileURLWithPath: "/tmp/file.swift"),
      sourceFileSyntax: sourceFileSyntax)
    if let consumer = consumer {
      context.diagnosticEngine?.addConsumer(consumer)
    }

    let printer = PrettyPrinter(
      context: context,
      operatorContext: OperatorContext.makeBuiltinOperatorContext(),
      node: Syntax(sourceFileSyntax),
      printTokenStream: false,
      whitespaceOnly: whitespaceOnly)
    return printer.prettyPrint()
  }
}
