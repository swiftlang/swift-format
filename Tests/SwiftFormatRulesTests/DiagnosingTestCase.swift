import SwiftFormatConfiguration
import SwiftFormatCore
import SwiftSyntax
import XCTest

/// DiagnosingTestCase is an XCTestCase subclass meant to inject diagnostic-specific testing
/// routines into specific formatting test cases.
public class DiagnosingTestCase: XCTestCase {
  /// The context each test runs in.
  public private(set) var context: Context?

  /// A helper that will keep track of the number of times a specific diagnostic was emitted.
  private var consumer = DiagnosticTrackingConsumer()

  /// Set during lint tests to indicate that we should check for any unasserted diagnostics when the
  /// test is torn down.
  private var shouldCheckForUnassertedDiagnostics = false

  private class DiagnosticTrackingConsumer: DiagnosticConsumer {
    var registeredDiagnostics = [String]()
    func handle(_ diagnostic: Diagnostic) {
      registeredDiagnostics.append(diagnostic.message.text)
      for note in diagnostic.notes {
        registeredDiagnostics.append(note.message.text)
      }
    }
    func finalize() {}
  }

  public override func tearDown() {
    guard shouldCheckForUnassertedDiagnostics else { return }

    // This will emit a test failure if a diagnostic is thrown but we don't explicitly call
    // XCTAssertDiagnosed for it.
    for diag in consumer.registeredDiagnostics {
      XCTFail("unexpected diagnostic '\(diag)' emitted")
    }
  }

  /// Creates and returns a new `Context` from the given syntax tree.
  private func makeContext(sourceFileSyntax: SourceFileSyntax, configuration: Configuration? = nil)
    -> Context
  {
    let context = Context(
      configuration: configuration ?? Configuration(),
      diagnosticEngine: DiagnosticEngine(),
      fileURL: URL(fileURLWithPath: "/tmp/test.swift"),
      sourceFileSyntax: sourceFileSyntax)
    consumer = DiagnosticTrackingConsumer()
    context.diagnosticEngine?.addConsumer(consumer)
    return context
  }

  /// Performs a lint using the provided linter rule on the provided input.
  ///
  /// - Parameters:
  ///   - type: The metatype of the lint rule you wish to perform.
  ///   - input: The input code.
  ///   - file: The file the test resides in (defaults to the current caller's file)
  ///   - line:  The line the test resides in (defaults to the current caller's line)
  func performLint<LintRule: SyntaxLintRule>(
    _ type: LintRule.Type,
    input: String,
    file: StaticString = #file,
    line: UInt = #line
  ) {
    let sourceFileSyntax: SourceFileSyntax
    do {
      sourceFileSyntax = try SyntaxParser.parse(source: input)
    } catch {
      XCTFail("\(error)", file: file, line: line)
      return
    }

    // Force the rule to be enabled while we test it.
    var configuration = Configuration()
    configuration.rules[type.ruleName] = true
    self.context = makeContext(sourceFileSyntax: sourceFileSyntax, configuration: configuration)

    // If we're linting, then indicate that we want to fail for unasserted diagnostics when the test
    // is torn down.
    shouldCheckForUnassertedDiagnostics = true

    var linter = type.init(context: context!)
    sourceFileSyntax.walk(&linter)
  }

  /// Asserts that the result of applying a formatter to the provided input code yields the output.
  ///
  /// This method should be called by each test of each rule.
  ///
  /// - Parameters:
  ///   - formatType: The metatype of the format rule you wish to apply.
  ///   - input: The unformatted input code.
  ///   - expected: The expected result of formatting the input code.
  ///   - file: The file the test resides in (defaults to the current caller's file)
  ///   - line:  The line the test resides in (defaults to the current caller's line)
  ///   - checkForUnassertedDiagnostics: Fail the test if there are any unasserted linter
  ///     diagnostics.
  func XCTAssertFormatting(
    _ formatType: SyntaxFormatRule.Type,
    input: String,
    expected: String,
    file: StaticString = #file,
    line: UInt = #line,
    checkForUnassertedDiagnostics: Bool = false,
    configuration: Configuration? = nil
  ) {
    let sourceFileSyntax: SourceFileSyntax
    do {
      sourceFileSyntax = try SyntaxParser.parse(source: input)
    } catch {
      XCTFail("\(error)", file: file, line: line)
      return
    }

    // Force the rule to be enabled while we test it.
    var configuration = configuration ?? Configuration()
    configuration.rules[formatType.ruleName] = true
    context = makeContext(sourceFileSyntax: sourceFileSyntax, configuration: configuration)

    shouldCheckForUnassertedDiagnostics = checkForUnassertedDiagnostics
    let formatter = formatType.init(context: context!)
    let result = formatter.visit(sourceFileSyntax)
    XCTAssertDiff(result: result.description, expected: expected, file: file, line: line)
  }

  /// Asserts that the two expressions have the same value, and provides a detailed
  /// message in the case there is a difference between both expression.
  ///
  /// - Parameters:
  ///   - result: The result of formatting the input code.
  ///   - expected: The expected result of formatting the input code.
  ///   - file: The file the test resides in (defaults to the current caller's file)
  ///   - line:  The line the test resides in (defaults to the current caller's line)
  func XCTAssertDiff(result: String, expected: String, file: StaticString, line: UInt) {
    let resultLines = result.components(separatedBy: .newlines)
    let expectedLines = expected.components(separatedBy: .newlines)
    let minCount = min(resultLines.count, expectedLines.count)
    let maxCount = max(resultLines.count, expectedLines.count)

    var index = 0
    // Iterates through both expressions while there are no differences.
    while index < minCount && resultLines[index] == expectedLines[index] { index += 1 }

    // If the index is not the same as the number of lines, it's because a
    // difference was found.
    if maxCount != index {
      let message = """
                    Actual and expected have a difference on line of code \(index + 1)
                    Actual line of code: "\(resultLines[index])"
                    Expected line of code: "\(expectedLines[index])"
                    ACTUAL:
                    ("\(result)")
                    EXPECTED:
                    ("\(expected)")
                    """
      XCTFail(message, file: file, line: line)
    }
  }

  /// Asserts that a specific diagnostic message was not emitted.
  ///
  /// - Parameters:
  ///   - message: The diagnostic message to check for.
  ///   - file: The file the test resides in (defaults to the current caller's file)
  ///   - line:  The line the test resides in (defaults to the current caller's line)
  func XCTAssertNotDiagnosed(
    _ message: Diagnostic.Message,
    file: StaticString = #file,
    line: UInt = #line
  ) {
    // This has to be a linear search, because the tests are going to check for the version
    // of the diagnostic that is not annotated with '[NameOfRule]:'.
    let hadDiag = consumer.registeredDiagnostics.contains {
      $0.contains(message.text)
    }

    if hadDiag {
      XCTFail("diagnostic '\(message.text)' should not have been raised", file: file, line: line)
    }
  }

  /// Asserts that a specific diagnostic message was emitted.
  ///
  /// - Parameters:
  ///   - message: The diagnostic message to check for.
  ///   - file: The file the test resides in (defaults to the current caller's file)
  ///   - line:  The line the test resides in (defaults to the current caller's line)
  func XCTAssertDiagnosed(
    _ message: Diagnostic.Message,
    file: StaticString = #file,
    line: UInt = #line
  ) {
    // This has to be a linear search, because the tests are going to check for the version
    // of the diagnostic that is not annotated with '[NameOfRule]:'.
    let maybeIdx = consumer.registeredDiagnostics.firstIndex { $0.contains(message.text) }

    guard let idx = maybeIdx else {
      XCTFail("diagnostic '\(message.text)' not raised", file: file, line: line)
      return
    }

    consumer.registeredDiagnostics.remove(at: idx)
  }
}
