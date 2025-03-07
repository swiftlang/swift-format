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

final class UseEarlyExitsTests: LintOrFormatRuleTestCase {
  func testBasicIfElse() {
    // In this and other tests, the indentation of the true block in the expected output is
    // explicitly incorrect because this formatting rule does not fix it up with the assumption that
    // the pretty-printer will handle it.
    assertFormatting(
      UseEarlyExits.self,
      input: """
        1️⃣if condition {
          trueBlock()
        } else {
          falseBlock()
          return
        }
        """,
      expected: """
        guard condition else {
          falseBlock()
          return
        }
          trueBlock()
        """,
      findings: [
        FindingSpec("1️⃣", message: "replace this 'if/else' block with a 'guard' statement containing the early exit")
      ]
    )
  }

  func testIfElseWithBothEarlyExiting() {
    assertFormatting(
      UseEarlyExits.self,
      input: """
        1️⃣if condition {
          trueBlock()
          return
        } else {
          falseBlock()
          return
        }
        """,
      expected: """
        guard condition else {
          falseBlock()
          return
        }
          trueBlock()
          return
        """,
      findings: [
        FindingSpec("1️⃣", message: "replace this 'if/else' block with a 'guard' statement containing the early exit")
      ]
    )
  }

  func testElseIfsDoNotChange() {
    let input = """
      if condition {
        trueBlock()
      } else if otherCondition {
        otherBlock()
        return
      }
      """
    assertFormatting(UseEarlyExits.self, input: input, expected: input, findings: [])
  }

  func testElsesAtEndOfElseIfsDoNotChange() {
    let input = """
      if condition {
        trueBlock()
      } else if otherCondition {
        otherBlock()
        return
      } else {
        falseBlock()
        return
      }
      """
    assertFormatting(UseEarlyExits.self, input: input, expected: input, findings: [])
  }

  func testComplex() {
    assertFormatting(
      UseEarlyExits.self,
      input: """
        func discombobulate(_ values: [Int]) throws -> Int {

          // Comment 1

          /*Comment 2*/ 1️⃣if let first = values.first {
            // Comment 3

            /// Doc comment
            2️⃣if first >= 0 {
              // Comment 4
              var result = 0
              for value in values {
                result += invertedCombobulatorFactor(of: value)
              }
              return result
            } else {
              print("Can't have negative energy")
              throw DiscombobulationError.negativeEnergy
            }
          } else {
            print("The array was empty")
            throw DiscombobulationError.arrayWasEmpty
          }
        }
        """,
      expected: """
        func discombobulate(_ values: [Int]) throws -> Int {

          // Comment 1

          /*Comment 2*/ guard let first = values.first else {
            print("The array was empty")
            throw DiscombobulationError.arrayWasEmpty
          }
            // Comment 3

            /// Doc comment
            guard first >= 0 else {
              print("Can't have negative energy")
              throw DiscombobulationError.negativeEnergy
            }
              // Comment 4
              var result = 0
              for value in values {
                result += invertedCombobulatorFactor(of: value)
              }
              return result
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "replace this 'if/else' block with a 'guard' statement containing the early exit"),
        FindingSpec("2️⃣", message: "replace this 'if/else' block with a 'guard' statement containing the early exit"),
      ]
    )
  }
}
