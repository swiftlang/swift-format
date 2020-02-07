import SwiftFormatRules

final class OneCasePerLineTests: LintOrFormatRuleTestCase {

  // The inconsistent leading whitespace in the expected text is intentional. This transform does
  // not attempt to preserve leading indentation since the pretty printer will correct it when
  // running the full formatter.

  func testInvalidCasesOnLine() {
    XCTAssertFormatting(
      OneCasePerLine.self,
      input:
        """
        public enum Token {
          case arrow
          case comma, identifier(String), semicolon, stringSegment(String)
          case period
          case ifKeyword(String), forKeyword(String)
          indirect case guardKeyword, elseKeyword, contextualKeyword(String)
          var x: Bool
          case leftParen, rightParen = ")", leftBrace, rightBrace = "}"
        }
        """,
      expected:
        """
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
        """)
  }

  func testElementOrderIsPreserved() {
    XCTAssertFormatting(
      OneCasePerLine.self,
      input:
        """
        enum Foo: Int {
          case a = 0, b, c, d
        }
        """,
      expected:
        """
        enum Foo: Int {
          case a = 0
        case b, c, d
        }
        """)
  }

  func testCommentsAreNotRepeated() {
    XCTAssertFormatting(
      OneCasePerLine.self,
      input:
        """
        enum Foo: Int {
          /// This should only be above `a`.
          case a = 0, b, c, d
          // This should only be above `e`.
          case e, f = 100
        }
        """,
      expected:
        """
        enum Foo: Int {
          /// This should only be above `a`.
          case a = 0
        case b, c, d
          // This should only be above `e`.
          case e
        case f = 100
        }
        """)
  }

  func testAttributesArePropagated() {
    XCTAssertFormatting(
      OneCasePerLine.self,
      input:
        """
        enum Foo {
          @someAttr case a(String), b, c, d
          case e, f(Int)
          @anotherAttr case g, h(Float)
        }
        """,
      expected:
        """
        enum Foo {
          @someAttr case a(String)
        @someAttr case b, c, d
          case e
        case f(Int)
          @anotherAttr case g
        @anotherAttr case h(Float)
        }
        """)
  }
}
