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

@_spi(Rules) import SwiftFormat
import _SwiftFormatTestSupport

final class NoEmptyLinesOpeningClosingBracesTests: LintOrFormatRuleTestCase {
  func testNoEmptyLinesOpeningClosingBracesInCodeBlock() {
    assertFormatting(
      NoEmptyLinesOpeningClosingBraces.self,
      input: """
        func f() {1️⃣

          //
          return


        2️⃣}
        """,
      expected: """
        func f() {
          //
          return
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove empty line after '{'"),
        FindingSpec("2️⃣", message: "remove empty lines before '}'"),
      ]
    )
  }

  func testNoEmptyLinesOpeningClosingBracesInMemberBlock() {
    assertFormatting(
      NoEmptyLinesOpeningClosingBraces.self,
      input: """
        struct {1️⃣

          let x: Int

          let y: Int

        2️⃣}
        """,
      expected: """
        struct {
          let x: Int

          let y: Int
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove empty line after '{'"),
        FindingSpec("2️⃣", message: "remove empty line before '}'"),
      ]
    )
  }

  func testNoEmptyLinesOpeningClosingBracesInAccessorBlock() {
    assertFormatting(
      NoEmptyLinesOpeningClosingBraces.self,
      input: """
        var x: Int {1️⃣

        //
          return _x

        2️⃣}

        var y: Int {3️⃣

          get 5️⃣{

          //
            return _y

         6️⃣ }

          set 7️⃣{

          //
            _x = newValue

         8️⃣ }

        4️⃣}
        """,
      expected: """
        var x: Int {
        //
          return _x
        }

        var y: Int {
          get {
          //
            return _y
          }

          set {
          //
            _x = newValue
          }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove empty line after '{'"),
        FindingSpec("2️⃣", message: "remove empty line before '}'"),
        FindingSpec("3️⃣", message: "remove empty line after '{'"),
        FindingSpec("4️⃣", message: "remove empty line before '}'"),
        FindingSpec("5️⃣", message: "remove empty line after '{'"),
        FindingSpec("6️⃣", message: "remove empty line before '}'"),
        FindingSpec("7️⃣", message: "remove empty line after '{'"),
        FindingSpec("8️⃣", message: "remove empty line before '}'"),
      ]
    )
  }

  func testNoEmptyLinesOpeningClosingBracesInClosureExpr() {
    assertFormatting(
      NoEmptyLinesOpeningClosingBraces.self,
      input: """
        let closure = {1️⃣

          //
          return

        2️⃣}
        """,
      expected: """
        let closure = {
          //
          return
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove empty line after '{'"),
        FindingSpec("2️⃣", message: "remove empty line before '}'"),
      ]
    )
  }

  func testNoEmptyLinesOpeningClosingBracesInFunctionBeginningAndEndingWithComment() {
    assertFormatting(
      NoEmptyLinesOpeningClosingBraces.self,
      input: """
        func myFunc() {
            // Some comment here

            // Do a thing
            var x = doAThing()

            // Do a thing

            var y = doAThing()

            // Some other comment here
        }
        """,
      expected: """
        func myFunc() {
            // Some comment here

            // Do a thing
            var x = doAThing()

            // Do a thing

            var y = doAThing()

            // Some other comment here
        }
        """
    )
  }

  func testNoEmptyLinesOpeningClosingBracesInFunctionWithEmptyLinesOnly() {
    assertFormatting(
      NoEmptyLinesOpeningClosingBraces.self,
      input: """
        func myFunc() {





        1️⃣}
        """,
      expected: """
        func myFunc() {
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove empty lines before '}'")
      ]
    )
  }
}
