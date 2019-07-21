import Foundation
import SwiftSyntax
import XCTest

@testable import SwiftFormatRules

public class OneCasePerLineTests: DiagnosingTestCase {
  func testInvalidCasesOnLine() {
    XCTAssertFormatting(OneCasePerLine.self,
                        input: """
                               public enum Token {
                                 case arrow
                                 case comma, identifier(String), semicolon, stringSegment(String)
                                 case period
                                 case ifKeyword(String), forKeyword(String)
                                 indirect case guardKeyword, elseKeyword, contextualKeyword(String)
                                 var x: Bool
                                 case leftParen, rightParen = ")", leftBrace, rightBrace = "}"
                               }
                               public enum Token: Int {
                                 case a, b, c
                                 case a = 0, b, c = 5, d
                                 case a = 0, b = 10, c, d
                               }
                               public enum Token: Float {
                                 case a, b, c
                                 case a = 0, b, c = 5, d
                                 case a = 0, b = 10, c, d
                               }
                               """,
                        expected: """
                                  public enum Token {
                                    case arrow
                                    case comma, semicolon
                                    case identifier(String)
                                    case stringSegment(String)
                                    case period
                                    case ifKeyword(String)
                                    case forKeyword(String)
                                    indirect case guardKeyword, elseKeyword
                                    indirect case contextualKeyword(String)
                                    var x: Bool
                                    case leftParen, leftBrace
                                    case rightParen = ")"
                                    case rightBrace = "}"
                                  }
                                  public enum Token: Int {
                                    case a, b, c
                                    case a = 0, b
                                    case c = 5, d
                                    case a = 0
                                    case b = 10, c, d
                                  }
                                  public enum Token: Float {
                                    case a, b, c
                                    case a = 0, b
                                    case c = 5, d
                                    case a = 0
                                    case b = 10, c, d
                                  }
                                  """)
  }
}
