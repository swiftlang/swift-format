//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2025 Apple Inc. and the Swift project authors
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

private let bom: Unicode.Scalar = "\u{feff}"
private let unknownScalar: Unicode.Scalar = "\u{fffe}"

final class GarbageTextTests: PrettyPrintTestCase {
  func testHashBang() {
    let input =
      """
      #!/usr/bin/swift -foo -bar
      print("Hello world!")
      """

    let expected =
      """
      #!/usr/bin/swift -foo -bar
      print(
        "Hello world!")

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 20)
  }

  func testHashBangFollowedByLineComment() {
    let input =
      """
      #!/usr/bin/env swift
      // (c) Acme Inc.

      print("Hello world!")
      """

    let expected =
      """
      #!/usr/bin/env swift
      // (c) Acme Inc.

      print("Hello world!")

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 80)

    // Also exercise the full formatter pipeline, which is the path the CLI
    // takes and the one the original bug report exercised.
    assertFormatted(input: input, expected: expected, linelength: 80)
  }

  private func assertFormatted(
    input: String,
    expected: String,
    linelength: Int,
    file: StaticString = #file,
    line: UInt = #line
  ) {
    var configuration = Configuration.forTesting
    configuration.lineLength = linelength
    let formatter = SwiftFormatter(configuration: configuration)
    var output = ""
    let tree = Parser.parse(source: input)
    let folded = try! OperatorTable.standardOperators.foldAll(tree).as(SourceFileSyntax.self)!
    try! formatter.format(
      syntax: folded,
      source: input,
      operatorTable: .standardOperators,
      assumingFileURL: nil,
      selection: .infinite,
      to: &output
    )
    XCTAssertEqual(output, expected, file: file, line: line)
  }

  func testHashBangFollowedByBlankLineAndComment() {
    let input =
      """
      #!/usr/bin/env swift

      // (c) Acme Inc.

      print("Hello world!")
      """

    let expected =
      """
      #!/usr/bin/env swift

      // (c) Acme Inc.

      print("Hello world!")

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 80)
  }

  func testBOM() {
    let input =
      """
      \(bom)print("Hello world!")
      """

    let expected =
      """
      \(bom)print("Hello world!")

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 21)
  }

  func testBOMPresenceDoesNotPermitLeadingNewlines() {
    let input =
      """
      \(bom)
      print("Hello world!")
      """

    let expected =
      """
      \(bom)print("Hello world!")

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 21)
  }

  func testUnknownCodePointAsLeadingTrivia() {
    let input =
      """
      \(unknownScalar)print("Hello world!")
      """

    let expected =
      """
      \(unknownScalar)print("Hello world!")

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 21)
  }

  func testUnknownCodePointAsTrailingTriviaAreGluedToPreviousToken() {
    // Note: The third line here is a bit of a weird case. Despite the operator being separated from
    // the left-hand-side by a space, the intervening garbage text appears to put the parser in a
    // mode where it treats the operator as a postfix operator, which then causes `secondTerm` to be
    // parsed as its own distinct statement and `CodeBlockItem`---hence the lack of indentation.
    let input =
      """
      x = y\(unknownScalar)+z

      x = firstTerm\(unknownScalar)+secondTerm

      x = firstTerm \(unknownScalar)+ secondTerm

      x = firstTerm\(unknownScalar) + secondTerm

      x = firstTerm \(unknownScalar) + secondTerm

      x = firstTerm \(unknownScalar) \(unknownScalar) + secondTerm
      """

    let expected =
      """
      x = y\(unknownScalar) + z

      x =
        firstTerm\(unknownScalar)
        + secondTerm

      x = firstTerm \(unknownScalar)+
      secondTerm

      x =
        firstTerm\(unknownScalar)
        + secondTerm

      x =
        firstTerm \(unknownScalar)
        + secondTerm

      x =
        firstTerm \(unknownScalar) \(unknownScalar)
        + secondTerm

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 20)
  }

  func testConflictMarkers() {
    let input =
      """
      func greet() {
      print("Hello")
      <<<<<<< hash:filename
      print("werld")
      =======
      print("world")
      >>>>>>> hash:filename
      print("!!")
      }
      """

    let expected =
      """
      func greet() {
        print("Hello")
      <<<<<<< hash:filename
      print("werld")
      =======
      print("world")
      >>>>>>> hash:filename
        print("!!")
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 80)
  }
}
