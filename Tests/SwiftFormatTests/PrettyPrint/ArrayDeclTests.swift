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
import SwiftSyntax
import _SwiftFormatTestSupport

final class ArrayDeclTests: PrettyPrintTestCase {
  func testBasicArrays() {
    let input =
      """
      let a = [ ]
      let a = [
      ]
      let a = [
        // Comment
      ]
      let a = [1, 2, 3,]
      let a: [Bool] = [false, true, true, false]
      let a = [11111111, 2222222, 33333333, 4444444]
      let a: [String] = ["One", "Two", "Three", "Four"]
      let a: [String] = ["One", "Two", "Three", "Four", "Five", "Six", "Seven"]
      let a: [String] = ["One", "Two", "Three", "Four", "Five", "Six", "Seven",]
      let a: [String] = [
        "One", "Two", "Three", "Four", "Five",
        "Six", "Seven", "Eight",
      ]
      let a = [11111111, 2222222, 33333333, 444444]
      """

    let expected =
      """
      let a = []
      let a = []
      let a = [
        // Comment
      ]
      let a = [1, 2, 3]
      let a: [Bool] = [false, true, true, false]
      let a = [
        11111111, 2222222, 33333333, 4444444,
      ]
      let a: [String] = [
        "One", "Two", "Three", "Four",
      ]
      let a: [String] = [
        "One", "Two", "Three", "Four", "Five",
        "Six", "Seven",
      ]
      let a: [String] = [
        "One", "Two", "Three", "Four", "Five",
        "Six", "Seven",
      ]
      let a: [String] = [
        "One", "Two", "Three", "Four", "Five",
        "Six", "Seven", "Eight",
      ]

      """
        // Ideally, this array would be left on 1 line without a trailing comma. We don't know if the
        // comma is required when calculating the length of array elements, so the comma's length is
        // always added to last element and that 1 character causes the newlines inside of the array.
        + """
        let a = [
          11111111, 2222222, 33333333, 444444,
        ]

        """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 45)
  }

  func testArrayOfFunctions() {
    let input =
      """
      let A = [(Int, Double) -> Bool]()
      let A = [(Int, Double) async -> Bool]()
      let A = [(Int, Double) throws -> Bool]()
      let A = [(Int, Double) async throws -> Bool]()
      """

    let expected46 =
      """
      let A = [(Int, Double) -> Bool]()
      let A = [(Int, Double) async -> Bool]()
      let A = [(Int, Double) throws -> Bool]()
      let A = [(Int, Double) async throws -> Bool]()

      """
    assertPrettyPrintEqual(input: input, expected: expected46, linelength: 46)

    let expected43 =
      """
      let A = [(Int, Double) -> Bool]()
      let A = [(Int, Double) async -> Bool]()
      let A = [(Int, Double) throws -> Bool]()
      let A = [
        (Int, Double) async throws -> Bool
      ]()

      """
    assertPrettyPrintEqual(input: input, expected: expected43, linelength: 43)

    let expected35 =
      """
      let A = [(Int, Double) -> Bool]()
      let A = [
        (Int, Double) async -> Bool
      ]()
      let A = [
        (Int, Double) throws -> Bool
      ]()
      let A = [
        (Int, Double) async throws
          -> Bool
      ]()

      """
    assertPrettyPrintEqual(input: input, expected: expected35, linelength: 35)

    let expected27 =
      """
      let A = [
        (Int, Double) -> Bool
      ]()
      let A = [
        (Int, Double) async
          -> Bool
      ]()
      let A = [
        (Int, Double) throws
          -> Bool
      ]()
      let A = [
        (Int, Double)
          async throws -> Bool
      ]()

      """
    assertPrettyPrintEqual(input: input, expected: expected27, linelength: 27)
  }

  func testNoTrailingCommasInTypes() {
    let input =
      """
      let a = [SomeSuperMegaLongTypeName]()
      """

    let expected =
      """
      let a = [
        SomeSuperMegaLongTypeName
      ]()

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 30)
  }

  func testWhitespaceOnlyDoesNotChangeTrailingComma() {
    assertPrettyPrintEqual(
      input: """
        let a = [
          "String"1️⃣,
        ]
        let a = [1, 2, 32️⃣,]
        let a: [String] = [
          "One", "Two", "Three", "Four", "Five",
          "Six", "Seven", "Eight"3️⃣
        ]
        """,
      expected: """
        let a = [
          "String",
        ]
        let a = [1, 2, 3,]
        let a: [String] = [
          "One", "Two", "Three", "Four", "Five",
          "Six", "Seven", "Eight"
        ]

        """,
      linelength: 45,
      whitespaceOnly: true,
      findings: [
        FindingSpec("1️⃣", message: "remove trailing comma from the last element in single line collection literal"),
        FindingSpec("2️⃣", message: "remove trailing comma from the last element in single line collection literal"),
        FindingSpec("3️⃣", message: "add trailing comma to the last element in multiline collection literal"),
      ]
    )
  }

  func testTrailingCommaDiagnostics() {
    assertPrettyPrintEqual(
      input: """
        let a = [1, 2, 31️⃣,]
        let a: [String] = [
          "One", "Two", "Three", "Four", "Five",
          "Six", "Seven", "Eight"2️⃣
        ]
        """,
      expected: """
        let a = [1, 2, 3,]
        let a: [String] = [
          "One", "Two", "Three", "Four", "Five",
          "Six", "Seven", "Eight"
        ]

        """,
      linelength: 45,
      whitespaceOnly: true,
      findings: [
        FindingSpec("1️⃣", message: "remove trailing comma from the last element in single line collection literal"),
        FindingSpec("2️⃣", message: "add trailing comma to the last element in multiline collection literal"),
      ]
    )
  }

  func testGroupsTrailingComma() {
    let input =
      """
      let a = [
        condition ? firstOption : secondOption,
        bar(),
      ]
      """

    let expected =
      """
      let a = [
        condition
          ? firstOption
          : secondOption,
        bar(),
      ]

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 32)
  }

  func testInnerElementBreakingFromComma() {
    let input =
      """
      let a = [("abc", "def", "xyz"),("this ", "string", "is long"),]
      let a = [("abc", "def", "xyz"),("this ", "string", "is long")]
      let a = [("this ", "string", "is long"),]
      let a = [("this ", "string", "is long")]
      let a = ["this ", "string", "is longer",]
      let a = [("this", "str"), ("is", "lng")]
      a = [("az", "by"), ("cf", "de")]
      """

    let expected =
      """
      let a = [
        ("abc", "def", "xyz"),
        (
          "this ", "string", "is long"
        ),
      ]
      let a = [
        ("abc", "def", "xyz"),
        (
          "this ", "string", "is long"
        ),
      ]
      let a = [
        ("this ", "string", "is long")
      ]
      let a = [
        ("this ", "string", "is long")
      ]
      let a = [
        "this ", "string",
        "is longer",
      ]
      let a = [
        ("this", "str"),
        ("is", "lng"),
      ]

      """
        // Ideally, this array would be left on 1 line without a trailing comma. We don't know if the
        // comma is required when calculating the length of array elements, so the comma's length is
        // always added to last element and that 1 character causes the newlines inside of the array.
        + """
        a = [
          ("az", "by"), ("cf", "de"),
        ]

        """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 32)
  }
}
