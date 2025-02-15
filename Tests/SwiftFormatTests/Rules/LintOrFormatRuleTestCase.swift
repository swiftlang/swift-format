import SwiftFormat
@_spi(Rules) @_spi(Testing) import SwiftFormat
import SwiftOperators
@_spi(ExperimentalLanguageFeatures) import SwiftParser
import SwiftSyntax
import XCTest
@_spi(Testing) import _SwiftFormatTestSupport

class LintOrFormatRuleTestCase: DiagnosingTestCase {
  /// Performs a lint using the provided linter rule on the provided input and asserts that the
  /// emitted findings are correct.
  ///
  /// - Parameters:
  ///   - type: The metatype of the lint rule you wish to perform.
  ///   - markedSource: The input source code, which may include emoji markers at the locations
  ///     where findings are expected to be emitted.
  ///   - findings: A list of `FindingSpec` values that describe the findings that are expected to
  ///     be emitted.
  ///   - experimentalFeatures: The set of experimental features that should be enabled in the
  ///     parser.
  ///   - file: The file the test resides in (defaults to the current caller's file).
  ///   - line: The line the test resides in (defaults to the current caller's line).
  final func assertLint<LintRule: SyntaxLintRule>(
    _ type: LintRule.Type,
    _ markedSource: String,
    findings: [FindingSpec] = [],
    experimentalFeatures: Parser.ExperimentalFeatures = [],
    file: StaticString = #file,
    line: UInt = #line
  ) {
    let markedText = MarkedText(textWithMarkers: markedSource)
    let unmarkedSource = markedText.textWithoutMarkers
    let tree = Parser.parse(source: unmarkedSource, experimentalFeatures: experimentalFeatures)
    let sourceFileSyntax =
      try! OperatorTable.standardOperators.foldAll(tree).as(SourceFileSyntax.self)!

    var emittedFindings = [Finding]()

    // Force the rule to be enabled while we test it.
    let configuration = Configuration.forTesting(enabledRule: type.ruleName)
    let context = makeContext(
      sourceFileSyntax: sourceFileSyntax,
      configuration: configuration,
      selection: .infinite,
      findingConsumer: { emittedFindings.append($0) }
    )

    var emittedPipelineFindings = [Finding]()
    let pipeline = SwiftLinter(
      configuration: configuration,
      findingConsumer: { emittedPipelineFindings.append($0) }
    )
    pipeline.debugOptions.insert(.disablePrettyPrint)
    try! pipeline.lint(
      syntax: sourceFileSyntax,
      source: unmarkedSource,
      operatorTable: OperatorTable.standardOperators,
      assumingFileURL: URL(fileURLWithPath: file.description)
    )

    // Check that pipeline produces the expected findings
    assertFindings(
      expected: findings,
      markerLocations: markedText.markers,
      emittedFindings: emittedPipelineFindings,
      context: context,
      file: file,
      line: line
    )
  }

  /// Asserts that the result of applying a formatter to the provided input code yields the output.
  ///
  /// This method should be called by each test of each rule.
  ///
  /// - Parameters:
  ///   - formatType: The metatype of the format rule you wish to apply.
  ///   - input: The unformatted input code.
  ///   - expected: The expected result of formatting the input code.
  ///   - findings: A list of `FindingSpec` values that describe the findings that are expected to
  ///     be emitted.
  ///   - configuration: The configuration to use when formatting (or nil to use the default).
  ///   - experimentalFeatures: The set of experimental features that should be enabled in the
  ///     parser.
  ///   - file: The file the test resides in (defaults to the current caller's file)
  ///   - line:  The line the test resides in (defaults to the current caller's line)
  final func assertFormatting(
    _ formatType: SyntaxFormatRule.Type,
    input: String,
    expected: String,
    findings: [FindingSpec] = [],
    configuration: Configuration? = nil,
    experimentalFeatures: Parser.ExperimentalFeatures = [],
    file: StaticString = #file,
    line: UInt = #line
  ) {
    let markedInput = MarkedText(textWithMarkers: input)
    let originalSource: String = markedInput.textWithoutMarkers
    let tree = Parser.parse(source: originalSource, experimentalFeatures: experimentalFeatures)
    let sourceFileSyntax =
      try! OperatorTable.standardOperators.foldAll(tree).as(SourceFileSyntax.self)!

    var emittedFindings = [Finding]()

    // Force the rule to be enabled while we test it.
    let configuration = configuration ?? Configuration.forTesting(enabledRule: formatType.ruleName)

    let context = makeContext(
      sourceFileSyntax: sourceFileSyntax,
      configuration: configuration,
      selection: .infinite,
      findingConsumer: { emittedFindings.append($0) }
    )

    let formatter = formatType.init(context: context)
    let actual = formatter.visit(sourceFileSyntax)
    assertStringsEqualWithDiff("\(actual)", expected, file: file, line: line)

    assertFindings(
      expected: findings,
      markerLocations: markedInput.markers,
      emittedFindings: emittedFindings,
      context: context,
      file: file,
      line: line
    )

    // Verify that the pretty printer can consume the transformed tree (e.g., it does not contain
    // any unfolded `SequenceExpr`s). Then do a whitespace-insensitive comparison of the two trees
    // to verify that the format rule didn't transform the tree in such a way that it caused the
    // pretty-printer to drop important information (the most likely case is a format rule
    // misplacing trivia in a way that the pretty-printer isn't able to handle).
    let prettyPrintedSource = PrettyPrinter(
      context: context,
      source: originalSource,
      node: Syntax(actual),
      printTokenStream: false,
      whitespaceOnly: false
    ).prettyPrint()
    let prettyPrintedTree = Parser.parse(source: prettyPrintedSource, experimentalFeatures: experimentalFeatures)
    XCTAssertEqual(
      whitespaceInsensitiveText(of: actual),
      whitespaceInsensitiveText(of: prettyPrintedTree),
      "After pretty-printing and removing fluid whitespace, the files did not match",
      file: file,
      line: line
    )

    var emittedPipelineFindings = [Finding]()
    let pipeline = SwiftFormatter(
      configuration: configuration,
      findingConsumer: { emittedPipelineFindings.append($0) }
    )
    pipeline.debugOptions.insert(.disablePrettyPrint)
    var pipelineActual = ""
    try! pipeline.format(
      syntax: sourceFileSyntax,
      source: originalSource,
      operatorTable: OperatorTable.standardOperators,
      assumingFileURL: nil,
      selection: .infinite,
      to: &pipelineActual
    )
    assertStringsEqualWithDiff(pipelineActual, expected)
    assertFindings(
      expected: findings,
      markerLocations: markedInput.markers,
      emittedFindings: emittedPipelineFindings,
      context: context,
      file: file,
      line: line
    )
  }
}

/// Returns a string containing a whitespace-insensitive representation of the given source file.
private func whitespaceInsensitiveText(of file: SourceFileSyntax) -> String {
  var result = ""
  for token in file.tokens(viewMode: .sourceAccurate) {
    appendNonspaceTrivia(token.leadingTrivia, to: &result)
    result.append(token.text)
    appendNonspaceTrivia(token.trailingTrivia, to: &result)
  }
  return result
}

/// Appends any non-whitespace trivia pieces from the given trivia collection to the output string.
private func appendNonspaceTrivia(_ trivia: Trivia, to string: inout String) {
  for piece in trivia {
    switch piece {
    case .carriageReturnLineFeeds, .carriageReturns, .formfeeds, .newlines, .spaces, .tabs:
      break
    case .lineComment(let comment), .docLineComment(let comment):
      // A tree transforming rule might leave whitespace at the end of a line comment, which the
      // pretty printer will remove, so we should ignore that.
      if let lastNonWhitespaceIndex = comment.lastIndex(where: { !$0.isWhitespace }) {
        string.append(contentsOf: comment[...lastNonWhitespaceIndex])
      } else {
        string.append(comment)
      }
    default:
      piece.write(to: &string)
    }
  }
}
