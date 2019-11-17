import SwiftFormatConfiguration
import SwiftFormatCore
import SwiftSyntax
import XCTest

@testable import SwiftFormatWhitespaceLinter

/// This test class allows us to check for specific diagnostics emitted by the DiagnosticEngine. It
/// is similar to SwiftFormatRulesTests/DiagnosingTestCase, except that this class also tests for
/// the specific line and column numbers of the diagnostic location.
public class WhitespaceTestCase: XCTestCase {

  /// The context in which to run the test.
  public private(set) var context: Context?

  /// Keeps track of the linter errors queued up in the DiagnosticEngine.
  private var consumer = DiagnosticTrackingConsumer()

  /// Used to indicate that a test should fail if we don't have test assertions for all diagnotics
  /// emmitted.
  private var shouldCheckForUnassertedDiagnostics = false

  private class DiagnosticTrackingConsumer: DiagnosticConsumer {
    var registeredDiagnostics = [(String, line: Int?, column: Int?)]()

    func handle(_ diagnostic: Diagnostic) {
      let loc = diagnostic.location
      registeredDiagnostics.append((diagnostic.message.text, line: loc?.line, column: loc?.column))
    }

    func finalize() {}
  }

  public override func tearDown() {
    guard shouldCheckForUnassertedDiagnostics else { return }

    for diag in consumer.registeredDiagnostics {
      XCTFail("unexpected diagnostic '\(diag)' emitted")
    }
  }

  /// Perform whitespace linting by comparing the input text from the user with the expected
  /// formatted text.
  ///
  /// - Parameters:
  ///  - input: The user's input text.
  ///  - expected: The formatted text.
  func performWhitespaceLint(
    input: String,
    expected: String,
    linelength: Int? = nil
  ) {
    let sourceFileSyntax: SourceFileSyntax
    do {
      sourceFileSyntax = try SyntaxParser.parse(source: input)
    } catch {
      XCTFail("Parsing failed with error: \(error)")
      return
    }

    var configuration = Configuration()
    if let linelength = linelength {
      configuration.lineLength = linelength
    }

    context = Context(
      configuration: configuration,
      diagnosticEngine: DiagnosticEngine(),
      fileURL: URL(fileURLWithPath: "/tmp/test.swift"),
      sourceFileSyntax: sourceFileSyntax
    )
    consumer = DiagnosticTrackingConsumer()
    context?.diagnosticEngine?.addConsumer(consumer)

    shouldCheckForUnassertedDiagnostics = true
    if let ctx = self.context {
      let ws = WhitespaceLinter(user: input, formatted: expected, context: ctx)
      ws.lint()
    }
  }

  /// Asserts that a specific diagnostic message was emitted.
  ///
  /// - Parameters:
  ///   - message: The diagnostic message to check for.
  ///   - line: The line number of the diagnotic message within the ueser's input text.
  ///   - column: The column number of the diagnostic message within the user's input text.
  ///   - file: The file the test resides in (defaults to the current caller's file).
  ///   - sourceLine: The line the test resides in (defaults to the current caller's file).
  func XCTAssertDiagnosed(
    _ message: Diagnostic.Message,
    line: Int? = nil,
    column: Int? = nil,
    file: StaticString = #file,
    sourceLine: UInt = #line
  ) {
    let maybeIdx = consumer.registeredDiagnostics.firstIndex {
      $0 == (message.text, line: line, column: column)
    }

    guard let idx = maybeIdx else {
      XCTFail("diagnostic '\(message.text)' not raised", file: file, line: sourceLine)
      return
    }

    consumer.registeredDiagnostics.remove(at: idx)
  }
}
