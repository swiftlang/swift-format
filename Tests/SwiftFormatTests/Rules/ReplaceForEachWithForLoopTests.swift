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

final class ReplaceForEachWithForLoopTests: LintOrFormatRuleTestCase {
  func test() {
    assertLint(
      ReplaceForEachWithForLoop.self,
      """
      values.1️⃣forEach { $0 * 2 }
      values.map { $0 }.2️⃣forEach { print($0) }
      values.forEach(callback)
      values.forEach { $0 }.chained()
      values.forEach({ $0 }).chained()
      values.3️⃣forEach {
        let arg = $0
        return arg + 1
      }
      values.forEach {
        let arg = $0
        return arg + 1
      } other: {
        42
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: "replace use of '.forEach { ... }' with for-in loop"),
        FindingSpec("2️⃣", message: "replace use of '.forEach { ... }' with for-in loop"),
        FindingSpec("3️⃣", message: "replace use of '.forEach { ... }' with for-in loop"),
      ]
    )
  }
}
