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

final class NoVoidReturnOnFunctionSignatureTests: LintOrFormatRuleTestCase {
  func testVoidReturns() {
    assertFormatting(
      NoVoidReturnOnFunctionSignature.self,
      input: """
        func foo() -> 1️⃣() {
        }

        func test() -> 2️⃣Void{
        }

        func x() -> Int { return 2 }

        let x = { () -> Void in
          print("Hello, world!")
        }
        """,
      expected: """
        func foo() {
        }

        func test() {
        }

        func x() -> Int { return 2 }

        let x = { () -> Void in
          print("Hello, world!")
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove the explicit return type '()' from this function"),
        FindingSpec("2️⃣", message: "remove the explicit return type 'Void' from this function"),
      ]
    )
  }
}
