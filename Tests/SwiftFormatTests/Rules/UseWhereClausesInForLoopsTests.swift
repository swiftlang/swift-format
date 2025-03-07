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

final class UseWhereClausesInForLoopsTests: LintOrFormatRuleTestCase {
  func testForLoopWhereClauses() {
    assertFormatting(
      UseWhereClausesInForLoops.self,
      input: """
        for i in [0, 1, 2, 3] {
          1️⃣if i > 30 {
            print(i)
          }
        }

        for i in [0, 1, 2, 3] {
          if i > 30 {
            print(i)
          } else {
            print(i)
          }
        }

        for i in [0, 1, 2, 3] {
          if i > 30 {
            print(i)
          } else if i > 40 {
            print(i)
          }
        }

        for i in [0, 1, 2, 3] {
          if i > 30 {
            print(i)
          }
          print(i)
        }

        for i in [0, 1, 2, 3] {
          if let x = (2 as Int?) {
            print(i)
          }
        }

        for i in [0, 1, 2, 3] {
          2️⃣guard i > 30 else {
            continue
          }
          print(i)
        }
        """,
      expected: """
        for i in [0, 1, 2, 3] where i > 30 {
            print(i)
        }

        for i in [0, 1, 2, 3] {
          if i > 30 {
            print(i)
          } else {
            print(i)
          }
        }

        for i in [0, 1, 2, 3] {
          if i > 30 {
            print(i)
          } else if i > 40 {
            print(i)
          }
        }

        for i in [0, 1, 2, 3] {
          if i > 30 {
            print(i)
          }
          print(i)
        }

        for i in [0, 1, 2, 3] {
          if let x = (2 as Int?) {
            print(i)
          }
        }

        for i in [0, 1, 2, 3] where i > 30 {
          print(i)
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "replace this 'if' statement with a 'where' clause"),
        FindingSpec("2️⃣", message: "replace this 'guard' statement with a 'where' clause"),
      ]
    )
  }
}
