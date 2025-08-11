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
