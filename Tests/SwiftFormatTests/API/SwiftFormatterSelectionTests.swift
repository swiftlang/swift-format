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

  private func assertFormatting(
    _ source: String,
    expected: String,
    selection: Selection,
    file: StaticString = #file,
    line: UInt = #line
  ) throws {
    var configuration = Configuration.forTesting
    configuration.lineLength = 60

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
