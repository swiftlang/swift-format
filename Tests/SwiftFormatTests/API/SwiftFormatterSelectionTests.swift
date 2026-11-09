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
      reflowComments: true
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

  private func assertFormatting(
    _ source: String,
    expected: String,
    selection: Selection,
    reflowComments: Bool = false,
    multiElementCollectionTrailingCommas: Bool = false,
    file: StaticString = #file,
    line: UInt = #line
  ) throws {
    var configuration = Configuration.forTesting
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
