import SwiftFormatConfiguration
import SwiftFormatCore
import SwiftFormatRules
import SwiftSyntax
import XCTest

/// DiagnosingTestCase is an XCTestCase subclass meant to inject diagnostic-specific testing
/// routines into specific formatting test cases.
open class DiagnosingTestCase: XCTestCase {
  /// Set during lint tests to indicate that we should check for unasserted diagnostics when the
  /// test is torn down and fail if there were any.
  public var shouldCheckForUnassertedDiagnostics = false

  /// A helper that will keep track of the findings that were emitted.
  private var consumer = TestingFindingConsumer()

  override open func setUp() {
    shouldCheckForUnassertedDiagnostics = false
  }

  override open func tearDown() {
    guard shouldCheckForUnassertedDiagnostics else { return }

    // This will emit a test failure if a diagnostic is thrown but we don't explicitly call
    // XCTAssertDiagnosed for it.
    for finding in consumer.emittedFindings {
      XCTFail("unexpected finding '\(finding)' emitted")
    }
  }

  /// Creates and returns a new `Context` from the given syntax tree and configuration.
  ///
  /// The returned context is configured with a diagnostic consumer that records diagnostics emitted
  /// during the tests, which can then be asserted using the `XCTAssertDiagnosed` and
  /// `XCTAssertNotDiagnosed` methods.
  public func makeContext(sourceFileSyntax: SourceFileSyntax, configuration: Configuration? = nil)
    -> Context
  {
    consumer = TestingFindingConsumer()
    let context = Context(
      configuration: configuration ?? Configuration(),
      operatorTable: .standardOperators,
      findingConsumer: consumer.consume,
      fileURL: URL(fileURLWithPath: "/tmp/test.swift"),
      sourceFileSyntax: sourceFileSyntax,
      ruleNameCache: ruleNameCache)
    return context
  }

  /// Stops tracking diagnostics emitted during formatting/linting.
  ///
  /// This used by the pretty-printer tests to suppress any diagnostics that might be emitted during
  /// the second format pass (which checks for idempotence).
  public func stopTrackingDiagnostics() {
    consumer.stopTrackingFindings()
  }

  /// Asserts that a specific diagnostic message was emitted.
  ///
  /// - Parameters:
  ///   - message: The diagnostic message expected to be emitted.
  ///   - file: The file in which failure occurred. Defaults to the file name of the test case in
  ///     which this function was called.
  ///   - line: The line number on which failure occurred. Defaults to the line number on which this
  ///     function was called.
  public final func XCTAssertDiagnosed(
    _ message: Finding.Message,
    line diagnosticLine: Int? = nil,
    column diagnosticColumn: Int? = nil,
    file: StaticString = #file,
    line: UInt = #line
  ) {
    let wasEmitted: Bool
    if let diagnosticLine = diagnosticLine, let diagnosticColumn = diagnosticColumn {
      wasEmitted = consumer.popFinding(
        containing: message.text, atLine: diagnosticLine, column: diagnosticColumn)
    } else {
      wasEmitted = consumer.popFinding(containing: message.text)
    }
    if !wasEmitted {
      XCTFail("diagnostic '\(message.text)' not emitted", file: file, line: line)
    }
  }

  /// Asserts that a specific diagnostic message was not emitted.
  ///
  /// - Parameters:
  ///   - message: The diagnostic message expected to not be emitted.
  ///   - file: The file in which failure occurred. Defaults to the file name of the test case in
  ///     which this function was called.
  ///   - line: The line number on which failure occurred. Defaults to the line number on which this
  ///     function was called.
  public final func XCTAssertNotDiagnosed(
    _ message: Finding.Message,
    file: StaticString = #file,
    line: UInt = #line
  ) {
    let wasEmitted = consumer.popFinding(containing: message.text)
    XCTAssertFalse(
      wasEmitted,
      "diagnostic '\(message.text)' should not have been emitted",
      file: file, line: line)
  }

  /// Asserts that the two strings are equal, providing Unix `diff`-style output if they are not.
  ///
  /// - Parameters:
  ///   - actual: The actual string.
  ///   - expected: The expected string.
  ///   - message: An optional description of the failure.
  ///   - file: The file in which failure occurred. Defaults to the file name of the test case in
  ///     which this function was called.
  ///   - line: The line number on which failure occurred. Defaults to the line number on which this
  ///     function was called.
  public final func XCTAssertStringsEqualWithDiff(
    _ actual: String,
    _ expected: String,
    _ message: String = "",
    file: StaticString = #file,
    line: UInt = #line
  ) {
    // Use `CollectionDifference` on supported platforms to get `diff`-like line-based output. On
    // older platforms, fall back to simple string comparison.
    if #available(macOS 10.15, *) {
      let actualLines = actual.components(separatedBy: .newlines)
      let expectedLines = expected.components(separatedBy: .newlines)

      let difference = actualLines.difference(from: expectedLines)
      if difference.isEmpty { return }

      var result = ""

      var insertions = [Int: String]()
      var removals = [Int: String]()

      for change in difference {
        switch change {
        case .insert(let offset, let element, _):
          insertions[offset] = element
        case .remove(let offset, let element, _):
          removals[offset] = element
        }
      }

      var expectedLine = 0
      var actualLine = 0

      while expectedLine < expectedLines.count || actualLine < actualLines.count {
        if let removal = removals[expectedLine] {
          result += "-\(removal)\n"
          expectedLine += 1
        } else if let insertion = insertions[actualLine] {
          result += "+\(insertion)\n"
          actualLine += 1
        } else {
          result += " \(expectedLines[expectedLine])\n"
          expectedLine += 1
          actualLine += 1
        }
      }

      let failureMessage = "Actual output (+) differed from expected output (-):\n\(result)"
      let fullMessage = message.isEmpty ? failureMessage : "\(message) - \(failureMessage)"
      XCTFail(fullMessage, file: file, line: line)
    } else {
      // Fall back to simple string comparison on platforms that don't support CollectionDifference.
      let failureMessage = "Actual output differed from expected output:"
      let fullMessage = message.isEmpty ? failureMessage : "\(message) - \(failureMessage)"
      XCTAssertEqual(actual, expected, fullMessage, file: file, line: line)
    }
  }
}
