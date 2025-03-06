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

final class NoCasesWithOnlyFallthroughTests: LintOrFormatRuleTestCase {
  func testFallthroughCases() {
    assertFormatting(
      NoCasesWithOnlyFallthrough.self,
      input: """
        switch numbers {
        case 1: print("one")
        1️⃣case 2: fallthrough
        2️⃣case 3: fallthrough
        case 4: print("two to four")
        3️⃣case 5: fallthrough
        case 7: print("five or seven")
        default: break
        }
        switch letters {
        4️⃣case "a": fallthrough
        5️⃣case "b", "c": fallthrough
        case "d": print("abcd")
        case "e": print("e")
        6️⃣case "f": fallthrough
        case "z": print("fz")
        default: break
        }
        switch tokens {
        case .comma: print(",")
        7️⃣case .rightBrace: fallthrough
        8️⃣case .leftBrace: fallthrough
        case .braces: print("{}")
        case .period: print(".")
        case .empty: fallthrough
        default: break
        }
        """,
      expected: """
        switch numbers {
        case 1: print("one")
        case 2, 3, 4: print("two to four")
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
        case .empty: fallthrough
        default: break
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "combine this fallthrough-only 'case' and the following 'case' into a single 'case'"),
        FindingSpec("2️⃣", message: "combine this fallthrough-only 'case' and the following 'case' into a single 'case'"),
        FindingSpec("3️⃣", message: "combine this fallthrough-only 'case' and the following 'case' into a single 'case'"),
        FindingSpec("4️⃣", message: "combine this fallthrough-only 'case' and the following 'case' into a single 'case'"),
        FindingSpec("5️⃣", message: "combine this fallthrough-only 'case' and the following 'case' into a single 'case'"),
        FindingSpec("6️⃣", message: "combine this fallthrough-only 'case' and the following 'case' into a single 'case'"),
        FindingSpec("7️⃣", message: "combine this fallthrough-only 'case' and the following 'case' into a single 'case'"),
        FindingSpec("8️⃣", message: "combine this fallthrough-only 'case' and the following 'case' into a single 'case'"),
      ]
    )
  }

  func testFallthroughCasesWithCommentsAreNotCombined() {
    assertFormatting(
      NoCasesWithOnlyFallthrough.self,
      input: """
        switch numbers {
        case 1:
          return 0 // This return has an inline comment.
        1️⃣case 2: fallthrough
        // This case is commented so it should stay.
        case 3:
          fallthrough
        case 4:
          // This fallthrough is commented so it should stay.
          fallthrough
        case 5: fallthrough  // This fallthrough is relevant.
        2️⃣case 6:
          fallthrough
        // This case has a descriptive comment.
        case 7: print("got here")
        }
        """,
      expected: """
        switch numbers {
        case 1:
          return 0 // This return has an inline comment.
        // This case is commented so it should stay.
        case 2, 3:
          fallthrough
        case 4:
          // This fallthrough is commented so it should stay.
          fallthrough
        case 5: fallthrough  // This fallthrough is relevant.
        // This case has a descriptive comment.
        case 6, 7: print("got here")
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "combine this fallthrough-only 'case' and the following 'case' into a single 'case'"),
        FindingSpec("2️⃣", message: "combine this fallthrough-only 'case' and the following 'case' into a single 'case'"),
      ]
    )
  }

  func testCommentsAroundCombinedCasesStayInPlace() {
    assertFormatting(
      NoCasesWithOnlyFallthrough.self,
      input: """
        switch numbers {
        case 5:
          return 42 // This return is important.
        1️⃣case 6: fallthrough
        // This case has an important comment.
        case 7: print("6 to 7")
        2️⃣case 8: fallthrough

        // This case has an extra leading newline for emphasis.
        case 9: print("8 to 9")
        }
        """,
      expected: """
        switch numbers {
        case 5:
          return 42 // This return is important.
        // This case has an important comment.
        case 6, 7: print("6 to 7")

        // This case has an extra leading newline for emphasis.
        case 8, 9: print("8 to 9")
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "combine this fallthrough-only 'case' and the following 'case' into a single 'case'"),
        FindingSpec("2️⃣", message: "combine this fallthrough-only 'case' and the following 'case' into a single 'case'"),
      ]
    )
  }

  func testNestedSwitches() {
    assertFormatting(
      NoCasesWithOnlyFallthrough.self,
      input: """
        switch x {
        1️⃣case 1: fallthrough
        2️⃣case 2: fallthrough
        case 3:
          switch y {
          3️⃣case 1: fallthrough
          case 2: print(2)
          }
        case 4:
          switch y {
          4️⃣case 1: fallthrough
          case 2: print(2)
          }
        }
        """,
      expected: """
        switch x {
        case 1, 2, 3:
          switch y {
          case 1, 2: print(2)
          }
        case 4:
          switch y {
          case 1, 2: print(2)
          }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "combine this fallthrough-only 'case' and the following 'case' into a single 'case'"),
        FindingSpec("2️⃣", message: "combine this fallthrough-only 'case' and the following 'case' into a single 'case'"),
        FindingSpec("3️⃣", message: "combine this fallthrough-only 'case' and the following 'case' into a single 'case'"),
        FindingSpec("4️⃣", message: "combine this fallthrough-only 'case' and the following 'case' into a single 'case'"),
      ]
    )
  }

  func testCasesInsideConditionalCompilationBlock() {
    assertFormatting(
      NoCasesWithOnlyFallthrough.self,
      input: """
        switch x {
        case 1: fallthrough
        #if FOO
        1️⃣case 2: fallthrough
        case 3: print(3)
        case 4: print(4)
        #endif
        2️⃣case 5: fallthrough
        case 6: print(6)
        #if BAR
        #if BAZ
        case 7: print(7)
        case 8: fallthrough
        #endif
        case 9: fallthrough
        #endif
        case 10: print(10)
        }
        """,
      expected: """
        switch x {
        case 1: fallthrough
        #if FOO
        case 2, 3: print(3)
        case 4: print(4)
        #endif
        case 5, 6: print(6)
        #if BAR
        #if BAZ
        case 7: print(7)
        case 8: fallthrough
        #endif
        case 9: fallthrough
        #endif
        case 10: print(10)
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "combine this fallthrough-only 'case' and the following 'case' into a single 'case'"),
        FindingSpec("2️⃣", message: "combine this fallthrough-only 'case' and the following 'case' into a single 'case'"),
      ]
    )
  }

  func testCasesWithWhereClauses() {
    // As noted in the rule implementation, the formatted result should include a newline before any
    // case items that have `where` clauses if they follow any case items that do not, to avoid
    // compiler warnings. This is handled by the pretty printer, not this rule.
    assertFormatting(
      NoCasesWithOnlyFallthrough.self,
      input: """
        switch x {
        1️⃣case 1 where y < 0: fallthrough
        2️⃣case 2 where y == 0: fallthrough
        3️⃣case 3 where y < 0: fallthrough
        case 4 where y != 0: print(4)
        4️⃣case 5: fallthrough
        5️⃣case 6: fallthrough
        6️⃣case 7: fallthrough
        7️⃣case 8: fallthrough
        8️⃣case 9: fallthrough
        case 10 where y == 0: print(10)
        default: print("?")
        }
        """,
      expected: """
        switch x {
        case 1 where y < 0, 2 where y == 0, 3 where y < 0, 4 where y != 0: print(4)
        case 5, 6, 7, 8, 9, 10 where y == 0: print(10)
        default: print("?")
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "combine this fallthrough-only 'case' and the following 'case' into a single 'case'"),
        FindingSpec("2️⃣", message: "combine this fallthrough-only 'case' and the following 'case' into a single 'case'"),
        FindingSpec("3️⃣", message: "combine this fallthrough-only 'case' and the following 'case' into a single 'case'"),
        FindingSpec("4️⃣", message: "combine this fallthrough-only 'case' and the following 'case' into a single 'case'"),
        FindingSpec("5️⃣", message: "combine this fallthrough-only 'case' and the following 'case' into a single 'case'"),
        FindingSpec("6️⃣", message: "combine this fallthrough-only 'case' and the following 'case' into a single 'case'"),
        FindingSpec("7️⃣", message: "combine this fallthrough-only 'case' and the following 'case' into a single 'case'"),
        FindingSpec("8️⃣", message: "combine this fallthrough-only 'case' and the following 'case' into a single 'case'"),
      ]
    )
  }

  func testCasesWithValueBindingsAreNotMerged() {
    assertFormatting(
      NoCasesWithOnlyFallthrough.self,
      input: """
        switch x {
        1️⃣case .a: fallthrough
        case .b: fallthrough
        case .c(let x): fallthrough
        case .d(let y): fallthrough
        2️⃣case .e: fallthrough
        case .f: fallthrough
        case (let g, let h): fallthrough
        3️⃣case .i: fallthrough
        case .j?: fallthrough
        case let k as K: fallthrough
        case .l: break
        }
        """,
      expected: """
        switch x {
        case .a, .b: fallthrough
        case .c(let x): fallthrough
        case .d(let y): fallthrough
        case .e, .f: fallthrough
        case (let g, let h): fallthrough
        case .i, .j?: fallthrough
        case let k as K: fallthrough
        case .l: break
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "combine this fallthrough-only 'case' and the following 'case' into a single 'case'"),
        FindingSpec("2️⃣", message: "combine this fallthrough-only 'case' and the following 'case' into a single 'case'"),
        FindingSpec("3️⃣", message: "combine this fallthrough-only 'case' and the following 'case' into a single 'case'"),
      ]
    )
  }

  func testFallthroughOnlyCasesAreNotMergedWithDefault() {
    assertFormatting(
      NoCasesWithOnlyFallthrough.self,
      input: """
        switch x {
        1️⃣case .a: fallthrough
        case .b: fallthrough
        default: print("got here")
        }
        """,
      expected: """
        switch x {
        case .a, .b: fallthrough
        default: print("got here")
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "combine this fallthrough-only 'case' and the following 'case' into a single 'case'")
      ]
    )
  }

  func testFallthroughOnlyCasesAreNotMergedWithUnknownDefault() {
    assertFormatting(
      NoCasesWithOnlyFallthrough.self,
      input: """
        switch x {
        1️⃣case .a: fallthrough
        case .b: fallthrough
        @unknown default: print("got here")
        }
        """,
      expected: """
        switch x {
        case .a, .b: fallthrough
        @unknown default: print("got here")
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "combine this fallthrough-only 'case' and the following 'case' into a single 'case'")
      ]
    )
  }
}
