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

final class OneCasePerLineTests: LintOrFormatRuleTestCase {

  // The inconsistent leading whitespace in the expected text is intentional. This transform does
  // not attempt to preserve leading indentation since the pretty printer will correct it when
  // running the full formatter.

  func testInvalidCasesOnLine() {
    assertFormatting(
      OneCasePerLine.self,
      input: """
        public enum Token {
          case arrow
          case comma, 1️⃣identifier(String), semicolon, 2️⃣stringSegment(String)
          case period
          case 3️⃣ifKeyword(String), 4️⃣forKeyword(String)
          indirect case guardKeyword, elseKeyword, 5️⃣contextualKeyword(String)
          var x: Bool
          case leftParen, 6️⃣rightParen = ")", leftBrace, 7️⃣rightBrace = "}"
        }
        """,
      expected: """
        public enum Token {
          case arrow
          case comma
        case identifier(String)
        case semicolon
        case stringSegment(String)
          case period
          case ifKeyword(String)
        case forKeyword(String)
          indirect case guardKeyword, elseKeyword
        indirect case contextualKeyword(String)
          var x: Bool
          case leftParen
        case rightParen = ")"
        case leftBrace
        case rightBrace = "}"
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "move 'identifier' to its own 'case' declaration"),
        FindingSpec("2️⃣", message: "move 'stringSegment' to its own 'case' declaration"),
        FindingSpec("3️⃣", message: "move 'ifKeyword' to its own 'case' declaration"),
        FindingSpec("4️⃣", message: "move 'forKeyword' to its own 'case' declaration"),
        FindingSpec("5️⃣", message: "move 'contextualKeyword' to its own 'case' declaration"),
        FindingSpec("6️⃣", message: "move 'rightParen' to its own 'case' declaration"),
        FindingSpec("7️⃣", message: "move 'rightBrace' to its own 'case' declaration"),
      ]
    )
  }

  func testElementOrderIsPreserved() {
    assertFormatting(
      OneCasePerLine.self,
      input: """
        enum Foo: Int {
          case 1️⃣a = 0, b, c, d
        }
        """,
      expected: """
        enum Foo: Int {
          case a = 0
        case b, c, d
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "move 'a' to its own 'case' declaration")
      ]
    )
  }

  func testCommentsAreNotRepeated() {
    assertFormatting(
      OneCasePerLine.self,
      input: """
        enum Foo: Int {
          /// This should only be above `a`.
          case 1️⃣a = 0, b, c, d
          // This should only be above `e`.
          case e, 2️⃣f = 100
        }
        """,
      expected: """
        enum Foo: Int {
          /// This should only be above `a`.
          case a = 0
        case b, c, d
          // This should only be above `e`.
          case e
        case f = 100
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "move 'a' to its own 'case' declaration"),
        FindingSpec("2️⃣", message: "move 'f' to its own 'case' declaration"),
      ]
    )
  }

  func testElementsOnContinuationLinesAreMovedOntoCaseKeyword() {
    assertFormatting(
      OneCasePerLine.self,
      input: """
        public enum TestEnum: Int {
          case 1️⃣a = 0,
            2️⃣b = 1,
            3️⃣c = 2
        }
        """,
      expected: """
        public enum TestEnum: Int {
          case a = 0
        case b = 1
        case c = 2
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "move 'a' to its own 'case' declaration"),
        FindingSpec("2️⃣", message: "move 'b' to its own 'case' declaration"),
        FindingSpec("3️⃣", message: "move 'c' to its own 'case' declaration"),
      ]
    )
  }

  func testCommentBeforeElementOnContinuationLineMovesAheadOfCaseKeyword() {
    assertFormatting(
      OneCasePerLine.self,
      input: """
        enum Foo: Int {
          case 1️⃣a = 1,
            // This should stay with `b`.
            2️⃣b = 2
        }
        """,
      expected: """
        enum Foo: Int {
          case a = 1
        // This should stay with `b`.
        case b = 2
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "move 'a' to its own 'case' declaration"),
        FindingSpec("2️⃣", message: "move 'b' to its own 'case' declaration"),
      ]
    )
  }

  func testEndOfLineCommentStaysWithItsElement() {
    assertFormatting(
      OneCasePerLine.self,
      input: """
        enum Foo: Int {
          case 1️⃣a = 1,  // a comment about 'a'
            2️⃣b = 2
        }
        """,
      expected: """
        enum Foo: Int {
          case a = 1  // a comment about 'a'
        case b = 2
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "move 'a' to its own 'case' declaration"),
        FindingSpec("2️⃣", message: "move 'b' to its own 'case' declaration"),
      ]
    )
  }

  func testEndOfLineAndLeadingCommentsBothStayWithTheirElements() {
    assertFormatting(
      OneCasePerLine.self,
      input: """
        enum Foo: Int {
          case 1️⃣a = 1,  // an end-of-line comment about 'a'
            // This should stay with `b`.
            2️⃣b = 2
        }
        """,
      expected: """
        enum Foo: Int {
          case a = 1  // an end-of-line comment about 'a'
        // This should stay with `b`.
        case b = 2
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "move 'a' to its own 'case' declaration"),
        FindingSpec("2️⃣", message: "move 'b' to its own 'case' declaration"),
      ]
    )
  }

  func testAttributesArePropagated() {
    assertFormatting(
      OneCasePerLine.self,
      input: """
        enum Foo {
          @someAttr case 1️⃣a(String), b, c, d
          case e, 2️⃣f(Int)
          @anotherAttr case g, 3️⃣h(Float)
        }
        """,
      expected: """
        enum Foo {
          @someAttr case a(String)
        @someAttr case b, c, d
          case e
        case f(Int)
          @anotherAttr case g
        @anotherAttr case h(Float)
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "move 'a' to its own 'case' declaration"),
        FindingSpec("2️⃣", message: "move 'f' to its own 'case' declaration"),
        FindingSpec("3️⃣", message: "move 'h' to its own 'case' declaration"),
      ]
    )
  }

  func testNoAssociatedOrRawValuesAndContinuationLineIsUnchanged() {
    assertFormatting(
      OneCasePerLine.self,
      input: """
        public enum TestEnum {
          case
            // foo
            1️⃣withPayload(Int),
            // bar
            2️⃣withPayload2(String)
          case
            a,
            b,
            c
        }
        """,
      expected: """
        public enum TestEnum {
          // foo
        case withPayload(Int)
        // bar
        case withPayload2(String)
          case
            a,
            b,
            c
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "move 'withPayload' to its own 'case' declaration"),
        FindingSpec("2️⃣", message: "move 'withPayload2' to its own 'case' declaration"),
      ]
    )
  }
}
