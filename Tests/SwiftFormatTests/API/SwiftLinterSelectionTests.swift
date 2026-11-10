//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import SwiftFormat
@_spi(Rules) @_spi(Testing) import SwiftFormat
import SwiftOperators
import SwiftParser
import SwiftSyntax
import XCTest
@_spi(Testing) import _SwiftFormatTestSupport

final class SwiftLinterSelectionTests: DiagnosingTestCase {
  func testSingleLineWhitespaceAndSyntaxFindings() throws {
    let source = """
      func foo() {
      let Bad_Name_1 = 1;
      1️⃣let 2️⃣Bad_Name_2 =3️⃣   24️⃣;
          let Bad_Name_3 = 3;
      }

      """

    try assertLint(
      source,
      selection: Selection(lineRanges: [3...3]),
      findings: [
        FindingSpec("1️⃣", message: "replace leading whitespace with 2 spaces"),
        FindingSpec("2️⃣", message: "rename the constant 'Bad_Name_2' using lowerCamelCase"),
        FindingSpec("3️⃣", message: "remove 2 spaces"),
        FindingSpec("4️⃣", message: "remove ';'"),
      ]
    )
  }

  func testDisjointLineRanges() throws {
    let source = """
      func foo() {
      1️⃣let x = 12️⃣;
      let y = 2;
      3️⃣let z = 34️⃣;
      }

      """

    try assertLint(
      source,
      selection: Selection(lineRanges: [2...2, 4...4]),
      findings: [
        FindingSpec("1️⃣", message: "replace leading whitespace with 2 spaces"),
        FindingSpec("2️⃣", message: "remove ';'"),
        FindingSpec("3️⃣", message: "replace leading whitespace with 2 spaces"),
        FindingSpec("4️⃣", message: "remove ';'"),
      ]
    )
  }

  func testOutOfBoundsAndZeroLineRanges() throws {
    let source = """
        let Bad_Name = 1;
      let y = 2;

      """

    try assertLint(
      source,
      selection: Selection(lineRanges: [10...20]),
      findings: []
    )

    try assertLint(
      source,
      selection: Selection(lineRanges: [0...0]),
      findings: []
    )
  }

  func testEnclosingDeclarationFindingsFilteredByLine() throws {
    var config = Configuration.forTesting
    config.rules["AllPublicDeclarationsHaveDocumentation"] = true

    let source = """
      1️⃣public struct UndocumentedStruct {
        public let firstUndocumentedField: Int
        2️⃣public let secondUndocumentedField: Int
      }

      """

    // Selecting only line 3 emits only line 3's finding, not line 1 or line 2.
    try assertLint(
      source,
      selection: Selection(lineRanges: [3...3]),
      configuration: config,
      findings: [
        FindingSpec("2️⃣", message: "add a documentation comment for 'secondUndocumentedField'")
      ]
    )

    // Selecting line 1 emits only the struct's finding on line 1.
    try assertLint(
      source,
      selection: Selection(lineRanges: [1...1]),
      configuration: config,
      findings: [
        FindingSpec("1️⃣", message: "add a documentation comment for 'UndocumentedStruct'")
      ]
    )
  }

  func testTestLibraryImportContextPreservedWhenSelectingLaterLines() throws {
    var config = Configuration.forTesting
    config.rules["NeverForceUnwrap"] = true

    let testFileSource = """
      import XCTest

      final class MyTests: XCTestCase {
        func test_something_with_underscores() {
          let x = Optional(1)!
        }
        func 1️⃣helper_with_underscores() {
          let y = Optional(2)!
        }
      }

      """

    // Line 4 (`test_something_with_underscores`) and line 5 (`Optional(1)!`) are in an XCTest
    // file, which is detected on line 1 (`import XCTest`) and line 3 (`class MyTests: XCTestCase`).
    // Even when only lines 4...5 are selected, test context must still be recognized.
    try assertLint(
      testFileSource,
      selection: Selection(lineRanges: [4...5]),
      configuration: config,
      findings: []
    )

    // Non-test helper method on line 7 still diagnoses underscore naming, while force-unwrap on
    // line 8 is still suppressed because the file imports XCTest.
    try assertLint(
      testFileSource,
      selection: Selection(lineRanges: [7...8]),
      configuration: config,
      findings: [
        FindingSpec(
          "1️⃣",
          message: "rename the function 'helper_with_underscores' using lowerCamelCase"
        )
      ]
    )

    let nonTestFileSource = """
      import Foundation

      func helper() {
        let x = Optional(1)!
        let y = 1️⃣Optional(2)!
      }

      """

    // In a non-test file, selecting line 5 still sets `importsAnyTestLibrary` to
    // `.doesNotImportATestLibrary` when visiting `SourceFileSyntax`, so `NeverForceUnwrap` fires
    // on line 5 and not on unselected line 4.
    try assertLint(
      nonTestFileSource,
      selection: Selection(lineRanges: [5...5]),
      configuration: config,
      findings: [
        FindingSpec("1️⃣", message: "do not force unwrap 'Optional(2)'")
      ]
    )
  }

  func testOrderedImportsWithSelection() throws {
    let source = """
      import Zebra
      1️⃣import Alpha
      import Beta

      let x = 1;

      """

    // Selecting the entire import block (lines 1...3) emits the import ordering finding on line 2,
    // matching `SwiftFormatter` which reorders the import block when lines 1...3 are selected.
    try assertLint(
      source,
      selection: Selection(lineRanges: [1...3]),
      findings: [
        FindingSpec("1️⃣", message: "sort import statements lexicographically")
      ]
    )

    // Selecting only a single line of the multi-line import block does not emit an import ordering
    // finding because reordering the block would modify unselected lines 1 and 3.
    let sourceWithoutImportMarkers = """
      import Zebra
      import Alpha
      import Beta

      let x = 1;

      """

    try assertLint(
      sourceWithoutImportMarkers,
      selection: Selection(lineRanges: [2...2]),
      findings: []
    )

    // Selecting only line 5 does not emit import ordering findings on lines 2 or 3.
    let sourceSelectingLine5 = """
      import Zebra
      import Alpha
      import Beta

      let x = 11️⃣;

      """

    try assertLint(
      sourceSelectingLine5,
      selection: Selection(lineRanges: [5...5]),
      findings: [
        FindingSpec("1️⃣", message: "remove ';'")
      ]
    )
  }

  func testTriviaAnchoredFindingsWithSelection() throws {
    let source = """
      /* unselected block comment */
      let a = 1

      1️⃣/*
       * multi-line block comment
       */
      let b = 2

      2️⃣/**
       * Multi-line doc block comment.
       */
      func foo() {}

      """

    // Selecting line 5 (inside the multi-line block comment) emits the finding anchored at the
    // start of that block comment on line 4, while ignoring the block comment on line 1 and the
    // doc block comment on lines 9...11.
    try assertLint(
      source,
      selection: Selection(lineRanges: [5...5]),
      findings: [
        FindingSpec("1️⃣", message: "replace this block comment with line comments")
      ]
    )

    // Selecting only line 12 (`func foo() {}`) does not emit the doc block comment finding on
    // lines 9...11.
    try assertLint(
      source,
      selection: Selection(lineRanges: [12...12]),
      findings: []
    )

    // Selecting line 10 (inside the multi-line doc block comment) emits the doc block comment
    // finding anchored at line 9.
    try assertLint(
      source,
      selection: Selection(lineRanges: [10...10]),
      findings: [
        FindingSpec(
          "2️⃣",
          message: "replace documentation block comments with documentation line comments"
        )
      ]
    )
  }

  func testReflowCommentFindingsWithSelection() throws {
    var config = Configuration.forTesting
    config.lineLength = 60
    config.reflowComments.regularComments = .always
    config.reflowComments.docComments = .always

    let source = """
      /// This is an unselected doc comment that exceeds the line length limit.
      func first(a: Int,1️⃣   b: Int) {}

      2️⃣/// This is a partially selected doc comment that exceeds the line length
      /// and continues onto a second line.
      func second() {}

      """

    // Selecting lines 2 and 5:
    // - Line 1's doc comment is not selected, so no reflow or line length finding is emitted on line 1.
    // - Line 2's spacing finding is emitted.
    // - Lines 4...5 form a contiguous doc comment touching line 5, so its reflow finding is emitted
    //   at line 4, while the whitespace line-length finding on line 4 is not emitted unless line 4
    //   itself is selected.
    try assertLint(
      source,
      selection: Selection(lineRanges: [2...2, 5...5]),
      configuration: config,
      findings: [
        FindingSpec("1️⃣", message: "remove 2 spaces"),
        FindingSpec("2️⃣", message: "reflow comment"),
      ]
    )
  }

  func testWhitespaceFindingsOnSelectedLinesOnly() throws {
    var config = Configuration.forTesting
    config.lineLength = 60

    let source = """
      let unselectedTrailingSpaces = 1\u{20}\u{20}
      let selectedTrailingSpaces = 21️⃣\u{20}\u{20}
      let unselectedLongLine = someFunction(firstArgument: 1, secondArgument: 2)
      2️⃣let selectedLongLine = someFunction(firstArgument: 3, secondArgument: 4)

      """

    try assertLint(
      source,
      selection: Selection(lineRanges: [2...2, 4...4]),
      configuration: config,
      findings: [
        FindingSpec("1️⃣", message: "remove trailing whitespace"),
        FindingSpec("2️⃣", message: "line is too long"),
      ]
    )
  }

  func testMultilineStringLiteralWithSelection() throws {
    let partiallySelectedClosingQuote = #"""
      let s = """
          hello
          """

      """#

    // Selecting only the closing `"""` line must not diagnose an indentation error on `"""` when
    // the enclosing multiline string literal is not completely selected.
    try assertLint(
      partiallySelectedClosingQuote,
      selection: Selection(lineRanges: [3...3]),
      findings: []
    )

    // Selecting the entire multiline string literal diagnoses the over-indented content and closing
    // quote lines together.
    let fullySelectedMultilineString = #"""
      let s = """
      1️⃣    hello
      2️⃣    """

      """#

    try assertLint(
      fullySelectedMultilineString,
      selection: Selection(lineRanges: [1...3]),
      findings: [
        FindingSpec("1️⃣", message: "unindent by 2 spaces"),
        FindingSpec("2️⃣", message: "unindent by 2 spaces"),
      ]
    )
  }

  func testReflowMultilineStringLiteralsInLinter() throws {
    var config = Configuration.forTesting
    config.lineLength = 30
    config.reflowMultilineStringLiterals = .onlyLinesOverLength

    let overlongMultilineString = #"""
      let someString = """
        this string's total lengths will be longer than the column limit
        """
      let x =1️⃣   1

      """#

    try assertLint(
      overlongMultilineString,
      selection: .infinite,
      configuration: config,
      findings: [
        FindingSpec("1️⃣", message: "remove 2 spaces")
      ]
    )

    config.reflowMultilineStringLiterals = .always
    let multilineStringWithContinuations = #"""
      let someString = """
        short \
        line
        this string's total lengths will be longer than the column limit
        """
      let x =1️⃣   1

      """#

    try assertLint(
      multilineStringWithContinuations,
      selection: .infinite,
      configuration: config,
      findings: [
        FindingSpec("1️⃣", message: "remove 2 spaces")
      ]
    )
  }

  func testOffsetRangesSelection() throws {
    let source = """
      let a = 1;
      ⏩let 1️⃣Bad_Name =2️⃣   23️⃣;⏪
      let c = 3;

      """

    try assertLint(
      source,
      findings: [
        FindingSpec("1️⃣", message: "rename the constant 'Bad_Name' using lowerCamelCase"),
        FindingSpec("2️⃣", message: "remove 2 spaces"),
        FindingSpec("3️⃣", message: "remove ';'"),
      ]
    )
  }

  func testMultilineCollectionTrailingCommaWithSelection() throws {
    var config = Configuration.forTesting
    config.multiElementCollectionTrailingCommas = true

    let dictionaryWithTrailingComma = """
      let dict = [
        "a": 1,
        "b": 2,
      ]

      """

    // Selecting the last element lines of a multi-line dictionary literal that already has a
    // trailing comma must emit no findings (and must not desynchronize WhitespaceLinter).
    try assertLint(
      dictionaryWithTrailingComma,
      selection: Selection(lineRanges: [2...3]),
      configuration: config,
      findings: []
    )

    let dictionaryWithoutTrailingComma = """
      let dict = [
        "a": 1,
        "b": 21️⃣
      ]

      """

    // Selecting the last element line when a trailing comma is missing must emit the finding.
    try assertLint(
      dictionaryWithoutTrailingComma,
      selection: Selection(lineRanges: [3...3]),
      configuration: config,
      findings: [
        FindingSpec(
          "1️⃣",
          message: "add trailing comma to the last element in multiline collection literal"
        )
      ]
    )

    // Selecting only an earlier element line must not emit a finding on the unselected last line.
    let dictionarySelectingFirstElementOnly = """
      let dict = [
        "a": 1,
        "b": 2
      ]

      """

    try assertLint(
      dictionarySelectingFirstElementOnly,
      selection: Selection(lineRanges: [2...2]),
      configuration: config,
      findings: []
    )

    let arrayWithoutTrailingComma = """
      let array = [
        1,
        21️⃣
      ]

      """

    try assertLint(
      arrayWithoutTrailingComma,
      selection: Selection(lineRanges: [3...3]),
      configuration: config,
      findings: [
        FindingSpec(
          "1️⃣",
          message: "add trailing comma to the last element in multiline collection literal"
        )
      ]
    )
  }

  func testSyntaxFormatRulesAgreeWithSelection() throws {
    var config = Configuration.forTesting
    config.rules["NoEmptyLinesOpeningClosingBraces"] = true
    config.rules["OmitExplicitReturns"] = true

    // Statement- and condition-level rules inside a function body: only selected lines are
    // diagnosed, even when the enclosing function or control-flow block spans unselected lines.
    let statementAndConditionSource = """
      func foo(x: Int?, y: Bool) -> Void {
        var a = 1, b = 2;
        1️⃣var c = 3, d = 42️⃣;
        if(y) {
          let unselected: Array<Int> = []
        }
        if 3️⃣(y), 4️⃣let _ = x {
          let selected: 5️⃣Array<Int> = []
        }
      }

      """

    try assertLint(
      statementAndConditionSource,
      selection: Selection(lineRanges: [3...3, 7...8]),
      configuration: config,
      findings: [
        FindingSpec(
          "1️⃣",
          message: "split this variable declaration to introduce only one variable per 'var'"
        ),
        FindingSpec("2️⃣", message: "remove ';'"),
        FindingSpec("3️⃣", message: "remove the parentheses around this expression"),
        FindingSpec(
          "4️⃣",
          message: "compare this value using `!= nil` instead of binding and discarding it"
        ),
        FindingSpec("5️⃣", message: "use shorthand syntax for this 'Array' type"),
      ]
    )

    // NoEmptyLinesOpeningClosingBraces: selecting the empty line after `{` diagnoses only the
    // leading empty line, while selecting the closing `}` line diagnoses only the trailing empty
    // line.
    let emptyLinesAfterOpeningBrace = """
      func bar() {1️⃣

        let x = 1

      }

      """

    try assertLint(
      emptyLinesAfterOpeningBrace,
      selection: Selection(lineRanges: [1...2]),
      configuration: config,
      findings: [
        FindingSpec("1️⃣", message: "remove empty line after '{'")
      ]
    )

    let emptyLinesBeforeClosingBrace = """
      func bar() {

        let x = 1

      1️⃣}

      """

    try assertLint(
      emptyLinesBeforeClosingBrace,
      selection: Selection(lineRanges: [5...5]),
      configuration: config,
      findings: [
        FindingSpec("1️⃣", message: "remove empty line before '}'")
      ]
    )

    // FileScopedDeclarationPrivacy, NoVoidReturnOnFunctionSignature, OmitExplicitReturns, and
    // OneCasePerLine on partial selections.
    let declRulesSource = """
      fileprivate struct UnselectedStruct {
        let value: Int
      }
      1️⃣fileprivate struct SelectedHeaderStruct {
        let value: Int
      }
      func unselectedSingleReturn() -> Void {
        return 1
      }
      func selectedHeaderAndReturn() -> 2️⃣Void {
        3️⃣return 2
      }
      enum MyEnum: Int {
        case unselectedA, unselectedB = 1
        case selectedA, 4️⃣selectedB = 2
      }

      """

    try assertLint(
      declRulesSource,
      selection: Selection(lineRanges: [4...4, 10...11, 15...15]),
      configuration: config,
      findings: [
        FindingSpec(
          "1️⃣",
          message: "replace 'fileprivate' with 'private' on file-scoped declarations"
        ),
        FindingSpec("2️⃣", message: "remove the explicit return type 'Void' from this function"),
        FindingSpec(
          "3️⃣",
          message: "'return' can be omitted because body consists of a single expression"
        ),
        FindingSpec("4️⃣", message: "move 'selectedB' to its own 'case' declaration"),
      ]
    )
  }

  private func assertLint(
    _ markedSource: String,
    selection: Selection? = nil,
    configuration: Configuration? = nil,
    findings: [FindingSpec],
    file: StaticString = #file,
    line: UInt = #line
  ) throws {
    let markedText = MarkedText(textWithMarkers: markedSource)
    let unmarkedSource = markedText.textWithoutMarkers
    let effectiveSelection = selection ?? markedText.selection
    let effectiveConfig = configuration ?? Configuration.forTesting

    let tree = Parser.parse(source: unmarkedSource)
    let foldedTree = try OperatorTable.standardOperators.foldAll(tree).as(SourceFileSyntax.self)!

    var emittedFindings: [Finding] = []
    let context = makeContext(
      sourceFileSyntax: foldedTree,
      configuration: effectiveConfig,
      selection: effectiveSelection,
      findingConsumer: { emittedFindings.append($0) }
    )

    let linter = SwiftLinter(
      configuration: effectiveConfig,
      findingConsumer: { emittedFindings.append($0) }
    )
    try linter.lint(
      source: unmarkedSource,
      assumingFileURL: URL(fileURLWithPath: "/tmp/test.swift"),
      selection: effectiveSelection
    )

    assertFindings(
      expected: findings,
      markerLocations: markedText.markers,
      emittedFindings: emittedFindings,
      context: context,
      file: file,
      line: line
    )
  }
}
