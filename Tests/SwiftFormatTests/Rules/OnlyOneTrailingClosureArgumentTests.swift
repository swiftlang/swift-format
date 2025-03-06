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

final class OnlyOneTrailingClosureArgumentTests: LintOrFormatRuleTestCase {
  func testInvalidTrailingClosureCall() {
    assertLint(
      OnlyOneTrailingClosureArgument.self,
      """
      1️⃣callWithBoth(someClosure: {}) {
        // ...
      }
      callWithClosure(someClosure: {})
      callWithTrailingClosure {
        // ...
      }
      """,
      findings: [
        FindingSpec(
          "1️⃣",
          message: "revise this function call to avoid using both closure arguments and a trailing closure"
        )
      ]
    )
  }
}
