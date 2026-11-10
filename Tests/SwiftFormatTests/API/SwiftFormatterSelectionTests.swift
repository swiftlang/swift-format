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
import SwiftOperators
import SwiftParser
import SwiftSyntax
import XCTest
import _SwiftFormatTestSupport

final class SwiftFormatterSelectionTests: XCTestCase {
  func testSingleLineFormatting() throws {
    let source = """
      func foo() {
      let x = 1
      let y = 2
          let z = 3
      }

      """

    let expected = """
      func foo() {
        let x = 1
      let y = 2
          let z = 3
      }

      """

    try assertFormatting(source, expected: expected, selection: Selection(lineRanges: [2...2]))
  }

  func testMultipleLinesFormatting() throws {
    let source = """
      func foo() {
      let x = 1
      let y = 2
          let z = 3
      }

      """

    let expected = """
      func foo() {
        let x = 1
        let y = 2
          let z = 3
      }

      """

    try assertFormatting(source, expected: expected, selection: Selection(lineRanges: [2...3]))
  }

  func testDisjointLineRanges() throws {
    let source = """
      func foo() {
      let x = 1
      let y = 2
      let z = 3
      }

      """

    let expected = """
      func foo() {
        let x = 1
      let y = 2
        let z = 3
      }

      """

    try assertFormatting(source, expected: expected, selection: Selection(lineRanges: [2...2, 4...4]))
  }

  func testPartiallyWrappedFunctionSignature() throws {
    let source = """
      func someFunction(
        param1: Int,
      param2: String,
        param3: Double
      ) {}

      """

    let expected = """
      func someFunction(
        param1: Int,
        param2: String,
        param3: Double
      ) {}

      """

    try assertFormatting(source, expected: expected, selection: Selection(lineRanges: [3...3]))
  }

  func testComplexExpressionIndentation() throws {
    let source = """
      let x = someFunction(
      a,
      b,
      c
      )

      """

    let expected = """
      let x = someFunction(
      a,
        b,
      c
      )

      """

    try assertFormatting(source, expected: expected, selection: Selection(lineRanges: [3...3]))
  }

  func testMultipleSpacesInsideLine() throws {
    let source = """
      let x = 1
      let y = 1   +   2
      let z = 1

      """

    let expected = """
      let x = 1
      let y = 1 + 2
      let z = 1

      """

    try assertFormatting(source, expected: expected, selection: Selection(lineRanges: [2...2]))
  }

  func testAdjacentLongLineNotWrapped() throws {
    let source = """
      let a = 1
      let veryLongVariableNameThatExceedsTheLineLengthLimitAndShouldBeWrappedIfSelected = 42

      """

    let expected = """
      let a = 1
      let veryLongVariableNameThatExceedsTheLineLengthLimitAndShouldBeWrappedIfSelected = 42

      """

    try assertFormatting(source, expected: expected, selection: Selection(lineRanges: [1...1]))
  }

  func testDegenerateSignatureIndentation() throws {
    let source = """
      func messyFunction(
        p1: Int,
      p2: String,
          p3: Double
      ) {}

      """

    let expected = """
      func messyFunction(
        p1: Int,
        p2: String,
          p3: Double
      ) {}

      """

    try assertFormatting(source, expected: expected, selection: Selection(lineRanges: [3...3]))
  }

  func testOutOfBoundsLineRange() throws {
    let source = """
      let x = 1
      let y = 2

      """

    let expected = """
      let x = 1
      let y = 2

      """

    try assertFormatting(source, expected: expected, selection: Selection(lineRanges: [10...20]))
  }

  func testPartialOutOfBoundsLineRange() throws {
    let source = """
      let x = 1
        let y = 2

      """

    let expected = """
      let x = 1
      let y = 2

      """

    try assertFormatting(source, expected: expected, selection: Selection(lineRanges: [2...100]))
  }

  func testZeroLineRange() throws {
    let source = """
      let x = 1
      let y = 2

      """

    let expected = """
      let x = 1
      let y = 2

      """

    try assertFormatting(source, expected: expected, selection: Selection(lineRanges: [0...0]))
  }

  func testMultilineStringLiteralWithSelection() throws {
    let source = #"""
      let   s   =   """
          hello \(1 + 2)
          world
          """

      """#

    // Selecting only the closing `"""` line must not dedent `"""` relative to the unselected
    // content lines (which would silently alter the string literal's runtime value).
    try assertFormatting(
      source,
      expected: source,
      selection: Selection(lineRanges: [4...4])
    )

    // Selecting only a middle content line (even one containing string interpolation) must not
    // partially format or re-indent the multiline string literal.
    try assertFormatting(
      source,
      expected: source,
      selection: Selection(lineRanges: [2...2])
    )

    // Selecting only the opening line formats the declaration up to `"""` without re-indenting the
    // unselected content lines or closing `"""`.
    let expectedOpeningLineFormatted = #"""
      let s = """
          hello \(1 + 2)
          world
          """

      """#
    try assertFormatting(
      source,
      expected: expectedOpeningLineFormatted,
      selection: Selection(lineRanges: [1...1])
    )

    // Selecting the entire multiline string literal formats the declaration and re-indents the
    // string lines and closing quote together.
    let expectedAllFormatted = #"""
      let s = """
        hello \(1 + 2)
        world
        """

      """#
    try assertFormatting(
      source,
      expected: expectedAllFormatted,
      selection: Selection(lineRanges: [1...4])
    )

    // Selecting the closing line of a multiline string argument still formats tokens after `"""` on
    // that line while keeping the closing `"""` indentation intact.
    let callSource = #"""
      foo(
        """
          hello
          """,   bar:   1
      )

      """#
    let expectedCallClosingLineFormatted = #"""
      foo(
        """
          hello
          """, bar: 1
      )

      """#
    try assertFormatting(
      callSource,
      expected: expectedCallClosingLineFormatted,
      selection: Selection(lineRanges: [4...4])
    )
  }

  func testReflowCommentCompletelyEncompassed() throws {
    let source = """
      /// This is a very long doc comment attached to a function that exceeds the line length limit.
      func foo(a: Int,   b: Int) {
      let x = 1
      }

      """

    let expected = """
      /// This is a very long doc comment attached to a function
      /// that exceeds the line length limit.
      func foo(a: Int,   b: Int) {
      let x = 1
      }

      """

    try assertFormatting(
      source,
      expected: expected,
      selection: Selection(lineRanges: [1...1]),
      reflowComments: true
    )
  }

  func testReflowCommentFunctionHeaderEncompassedButNotDocComment() throws {
    let source = """
      /// This is a very long doc comment attached to a function that exceeds the line length limit.
      /// And a second line of the doc comment.
      func foo(a: Int,   b: Int) {
      let x = 1
      }

      """

    let expected = """
      /// This is a very long doc comment attached to a function that exceeds the line length limit.
      /// And a second line of the doc comment.
      func foo(a: Int, b: Int) {
      let x = 1
      }

      """

    try assertFormatting(
      source,
      expected: expected,
      selection: Selection(lineRanges: [3...3]),
      reflowComments: true
    )
  }

  func testReflowCommentFunctionHeaderEncompassedButNotDocBlockComment() throws {
    let source = """
      /**
       * This is a very long doc block comment attached to a function that exceeds the line length.
       */
      func foo(a: Int,   b: Int) {
      let x = 1
      }

      """

    let expected = """
      /**
       * This is a very long doc block comment attached to a function that exceeds the line length.
       */
      func foo(a: Int, b: Int) {
      let x = 1
      }

      """

    try assertFormatting(
      source,
      expected: expected,
      selection: Selection(lineRanges: [4...4]),
      reflowComments: true
    )
  }

  func testReflowMultilineLineCommentPartiallyEncompassedFirstLine() throws {
    let source = """
      /// This is the first line of a doc comment that is very long and exceeds the column limit
      /// and this is the second line of the paragraph
      /// and the third line.
      func foo(a: Int,   b: Int) {}

      """

    let expected = """
      /// This is the first line of a doc comment that is very
      /// long and exceeds the column limit and this is the second
      /// line of the paragraph and the third line.
      func foo(a: Int,   b: Int) {}

      """

    try assertFormatting(
      source,
      expected: expected,
      selection: Selection(lineRanges: [1...1]),
      reflowComments: true
    )
  }

  func testReflowMultilineLineCommentPartiallyEncompassedMiddleLine() throws {
    let source = """
      /// This is the first line of a doc comment that is very long and exceeds the column limit
      /// and this is the second line of the paragraph
      /// and the third line.
      func foo(a: Int,   b: Int) {}

      """

    let expected = """
      /// This is the first line of a doc comment that is very
      /// long and exceeds the column limit and this is the second
      /// line of the paragraph and the third line.
      func foo(a: Int,   b: Int) {}

      """

    try assertFormatting(
      source,
      expected: expected,
      selection: Selection(lineRanges: [2...2]),
      reflowComments: true
    )
  }

  func testReflowMultilineLineCommentPartiallyEncompassedLastLine() throws {
    let source = """
      /// This is the first line of a doc comment that is very long and exceeds the column limit
      /// and this is the second line of the paragraph
      /// and the third line.
      func foo(a: Int,   b: Int) {}

      """

    let expected = """
      /// This is the first line of a doc comment that is very
      /// long and exceeds the column limit and this is the second
      /// line of the paragraph and the third line.
      func foo(a: Int,   b: Int) {}

      """

    try assertFormatting(
      source,
      expected: expected,
      selection: Selection(lineRanges: [3...3]),
      reflowComments: true
    )
  }

  func testReflowMultilineLineCommentPartiallyEncompassedAndFunctionHeader() throws {
    let source = """
      /// This is the first line of a doc comment that is very long and exceeds the column limit
      /// and this is the second line of the paragraph
      /// and the third line.
      func foo(a: Int,   b: Int) {
      let x = 1
      }

      """

    let expected = """
      /// This is the first line of a doc comment that is very
      /// long and exceeds the column limit and this is the second
      /// line of the paragraph and the third line.
      func foo(a: Int, b: Int) {
      let x = 1
      }

      """

    try assertFormatting(
      source,
      expected: expected,
      selection: Selection(lineRanges: [3...4]),
      reflowComments: true
    )
  }

  func testReflowBlockCommentPartiallyEncompassed() throws {
    var config = Configuration.forTesting
    config.rules["UseTripleSlashForDocumentationComments"] = false

    let source = """
      /**
       * This is the first line of a doc block comment that is very long and exceeds the limit
       * and this is the second line of the paragraph.
       */
      func foo(a: Int,   b: Int) {}

      """

    let expected = """
      /**
       * This is the first line of a doc block comment that is
       * very long and exceeds the limit and this is the second
       * line of the paragraph.
       */
      func foo(a: Int,   b: Int) {}

      """

    try assertFormatting(
      source,
      expected: expected,
      selection: Selection(lineRanges: [3...3]),
      reflowComments: true,
      configuration: config
    )
  }

  func testReflowCommentPartiallyEncompassedInsideFencedCodeBlock() throws {
    let source = """
      /// This is a very long summary line above the code block that exceeds the line length limit.
      ///
      /// ```swift
      /// let veryLongCodeLineInsideCodeBlock = someFunction(firstArg: 1, secondArg: 2)
      /// ```
      func foo() {}

      """

    let expected = """
      /// This is a very long summary line above the code block
      /// that exceeds the line length limit.
      ///
      /// ```swift
      /// let veryLongCodeLineInsideCodeBlock = someFunction(firstArg: 1, secondArg: 2)
      /// ```
      func foo() {}

      """

    // Selecting only line 4 (inside the fenced code block) still keeps the contiguous doc comment
    // together so the code block is recognized and preserved while the prose is reflowed.
    try assertFormatting(
      source,
      expected: expected,
      selection: Selection(lineRanges: [4...4]),
      reflowComments: true
    )
  }

  func testReflowOnlyTouchedCommentAmongMultipleComments() throws {
    let source = """
      // First separate comment that is very long and exceeds the line length limit.

      // Second separate comment that is also very long and exceeds the line length limit.
      // Continuation of the second comment.

      // Third separate comment that is also very long and exceeds the line length limit.
      let x = 1

      """

    let expected = """
      // First separate comment that is very long and exceeds the line length limit.

      // Second separate comment that is also very long and
      // exceeds the line length limit. Continuation of the second
      // comment.

      // Third separate comment that is also very long and exceeds the line length limit.
      let x = 1

      """

    try assertFormatting(
      source,
      expected: expected,
      selection: Selection(lineRanges: [4...4]),
      reflowComments: true
    )
  }

  func testMultilineCollectionTrailingCommaWithSelection() throws {
    let dictionaryWithTrailingComma = """
      let dict = [
        "a": 1,
        "b": 2,
      ]

      """

    // Selecting the last element lines of a multi-line dictionary literal must preserve an
    // existing trailing comma even when the closing bracket line is outside the selection.
    try assertFormatting(
      dictionaryWithTrailingComma,
      expected: dictionaryWithTrailingComma,
      selection: Selection(lineRanges: [2...3]),
      multiElementCollectionTrailingCommas: true
    )

    let dictionaryWithoutTrailingComma = """
      let dict = [
        "a": 1,
        "b": 2
      ]

      """

    // Selecting the last element line when a trailing comma is missing must insert it.
    try assertFormatting(
      dictionaryWithoutTrailingComma,
      expected: dictionaryWithTrailingComma,
      selection: Selection(lineRanges: [3...3]),
      multiElementCollectionTrailingCommas: true
    )

    // Selecting only an earlier element line must not modify the unselected last element line.
    try assertFormatting(
      dictionaryWithoutTrailingComma,
      expected: dictionaryWithoutTrailingComma,
      selection: Selection(lineRanges: [2...2]),
      multiElementCollectionTrailingCommas: true
    )

    let arrayWithoutTrailingComma = """
      let array = [
        1,
        2
      ]

      """

    let arrayWithTrailingComma = """
      let array = [
        1,
        2,
      ]

      """

    try assertFormatting(
      arrayWithoutTrailingComma,
      expected: arrayWithTrailingComma,
      selection: Selection(lineRanges: [3...3]),
      multiElementCollectionTrailingCommas: true
    )

    try assertFormatting(
      arrayWithTrailingComma,
      expected: arrayWithTrailingComma,
      selection: Selection(lineRanges: [2...3]),
      multiElementCollectionTrailingCommas: true
    )
  }

  func testSyntaxFormatRulesWithSelection() throws {
    let source = """
      func foo(x: Int?, y: Bool) -> Void {
        var a = 1, b = 2;
        var c = 3, d = 4;
        if(y) {
          let unselected: Array<Int> = []
        }
        if(y), let _ = x {
          let selected: Array<Int> = []
        }
      }

      """

    let expected = """
      func foo(x: Int?, y: Bool) -> Void {
        var a = 1, b = 2;
        var c = 3
        var d = 4
        if(y) {
          let unselected: Array<Int> = []
        }
        if y, x != nil {
          let selected: [Int] = []
        }
      }

      """

    try assertFormatting(
      source,
      expected: expected,
      selection: Selection(lineRanges: [3...3, 7...8])
    )
  }

  func testOrderedImportsWithSelection() throws {
    let source = """
      import Zebra
      import Alpha
      import Beta

      let x = 1;

      """

    // Selecting the entire import block reorders the imports without formatting unselected line 5.
    let expectedWhenImportsSelected = """
      import Alpha
      import Beta
      import Zebra

      let x = 1;

      """

    try assertFormatting(
      source,
      expected: expectedWhenImportsSelected,
      selection: Selection(lineRanges: [1...3])
    )

    // Selecting only a single line of the import block leaves the imports unchanged.
    try assertFormatting(
      source,
      expected: source,
      selection: Selection(lineRanges: [2...2])
    )

    // Selecting only line 5 formats line 5 (removing the semicolon) without reordering the
    // unselected imports on lines 1...3.
    let expectedWhenLine5Selected = """
      import Zebra
      import Alpha
      import Beta

      let x = 1

      """

    try assertFormatting(
      source,
      expected: expectedWhenLine5Selected,
      selection: Selection(lineRanges: [5...5])
    )
  }

  func testDocBlockCommentsWithSelection() throws {
    let source = """
      /**
       * Unselected doc block comment.
       */
      func first() {}

      /**
       * Selected doc block comment.
       */
      func second() {
      let x = 1;
      }

      """

    // Selecting a line inside the second doc block comment converts it to doc line comments
    // without formatting the unselected body of `second()` or the first doc block comment.
    let expectedWhenDocCommentSelected = """
      /**
       * Unselected doc block comment.
       */
      func first() {}

      /// Selected doc block comment.
      func second() {
      let x = 1;
      }

      """

    try assertFormatting(
      source,
      expected: expectedWhenDocCommentSelected,
      selection: Selection(lineRanges: [7...7])
    )

    // Selecting only the declaration line below the doc block comment leaves the doc block
    // comment untouched.
    try assertFormatting(
      source,
      expected: source,
      selection: Selection(lineRanges: [9...9])
    )
  }

  func testNoEmptyLinesOpeningClosingBracesWithSelection() throws {
    var config = Configuration.forTesting
    config.rules["NoEmptyLinesOpeningClosingBraces"] = true

    let source = """
      func bar() {

        let x = 1

      }

      """

    let expectedOpeningTrimmed = """
      func bar() {
        let x = 1

      }

      """

    try assertFormatting(
      source,
      expected: expectedOpeningTrimmed,
      selection: Selection(lineRanges: [1...2]),
      configuration: config
    )

    let expectedClosingTrimmed = """
      func bar() {

        let x = 1
      }

      """

    try assertFormatting(
      source,
      expected: expectedClosingTrimmed,
      selection: Selection(lineRanges: [5...5]),
      configuration: config
    )
  }

  func testDeclarationAndByteOffsetShiftingSyntaxRulesWithSelection() throws {
    var config = Configuration.forTesting
    config.rules["OmitExplicitReturns"] = true

    let source = """
      fileprivate struct UnselectedStruct {
        let value: Array<Dictionary<String, Optional<Int>>> = []
      }
      fileprivate struct SelectedHeaderStruct {
        let value: Array<Dictionary<String, Optional<Int>>> = []
      }
      func unselectedSingleReturn() -> Void {
        return 1
      }
      func selectedHeaderAndReturn() -> Void {
        return 2
      }
      enum MyEnum: Int {
        case unselectedA, unselectedB = 1
        case selectedA, selectedB = 2
      }

      """

    let expected = """
      fileprivate struct UnselectedStruct {
        let value: Array<Dictionary<String, Optional<Int>>> = []
      }
      private struct SelectedHeaderStruct {
        let value: Array<Dictionary<String, Optional<Int>>> = []
      }
      func unselectedSingleReturn() -> Void {
        return 1
      }
      func selectedHeaderAndReturn() {
        2
      }
      enum MyEnum: Int {
        case unselectedA, unselectedB = 1
        case selectedA
        case selectedB = 2
      }

      """

    try assertFormatting(
      source,
      expected: expected,
      selection: Selection(lineRanges: [4...4, 10...11, 15...15]),
      configuration: config
    )
  }

  private func assertFormatting(
    _ source: String,
    expected: String,
    selection: Selection,
    reflowComments: Bool = false,
    multiElementCollectionTrailingCommas: Bool = false,
    configuration: Configuration? = nil,
    file: StaticString = #file,
    line: UInt = #line
  ) throws {
    var configuration = configuration ?? Configuration.forTesting
    configuration.lineLength = 60
    if reflowComments {
      configuration.reflowComments.regularComments = .always
      configuration.reflowComments.docComments = .always
    }
    if multiElementCollectionTrailingCommas {
      configuration.multiElementCollectionTrailingCommas = true
    }

    let formatter = SwiftFormatter(configuration: configuration)
    var output = ""
    let tree = Parser.parse(source: source)
    let foldedTree = try! OperatorTable.standardOperators.foldAll(tree).as(SourceFileSyntax.self)!
    try formatter.format(
      syntax: foldedTree,
      source: source,
      operatorTable: .standardOperators,
      assumingFileURL: nil,
      selection: selection,
      to: &output
    )
    XCTAssertEqual(output, expected, file: file, line: line)
  }
}
