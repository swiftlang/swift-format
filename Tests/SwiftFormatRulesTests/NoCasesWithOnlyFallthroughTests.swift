import Foundation
import SwiftSyntax
import XCTest

@testable import SwiftFormatRules

public class NoCasesWithOnlyFallthroughTests: DiagnosingTestCase {
  func testFallthroughCases() {
    XCTAssertFormatting(NoCasesWithOnlyFallthrough.self,
                        input: """
                               switch numbers {
                               case 1: print("one")
                               case 2: fallthrough
                               case 3: fallthrough
                               case 4: print("two to four")
                               case 5: fallthrough
                               case 7: print("five or seven")
                               default: break
                               }
                               switch letters {
                               case "a": fallthrough
                               case "b", "c": fallthrough
                               case "d": print("abcd")
                               case "e": print("e")
                               case "f": fallthrough
                               case "z": print("fz")
                               default: break
                               }
                               switch tokens {
                               case .comma: print(",")
                               case .rightBrace: fallthrough
                               case .leftBrace: fallthrough
                               case .braces: print("{}")
                               case .period: print(".")
                               case .empty: fallthrough
                               default: break
                               }
                               """,
                        expected: """
                                  switch numbers {
                                  case 1: print("one")
                                  case 2...4: print("two to four")
                                  case 5, 7: print("five or seven")
                                  default: break
                                  }
                                  switch letters {
                                  case "a", "b", "c", "d": print("abcd")
                                  case "e": print("e")
                                  case "f", "z": print("fz")
                                  default: break
                                  }
                                  switch tokens {
                                  case .comma: print(",")
                                  case .rightBrace, .leftBrace, .braces: print("{}")
                                  case .period: print(".")
                                  default: break
                                  }
                                  """)
  }
}
