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

final class GroupNumericLiteralsTests: LintOrFormatRuleTestCase {
  func testNumericGrouping() {
    assertFormatting(
      GroupNumericLiterals.self,
      input: """
        let a = 1️⃣9876543210
        let b = 1234
        let c = 2️⃣0x34950309233
        let d = -0x34242
        let e = 3️⃣0b10010010101
        let f = 0b101
        let g = 11_15_1999
        let h = 0o21743
        let i = -4️⃣53096828347
        let j = 5️⃣0000123
        let k = 6️⃣0x00000012
        let l = 0x0000012
        let m = 7️⃣0b00010010101
        let n = [
          8️⃣0xff00ff00,  // comment
          9️⃣0x00ff00ff,  // comment
        ]
        """,
      expected: """
        let a = 9_876_543_210
        let b = 1234
        let c = 0x349_5030_9233
        let d = -0x34242
        let e = 0b100_10010101
        let f = 0b101
        let g = 11_15_1999
        let h = 0o21743
        let i = -53_096_828_347
        let j = 0_000_123
        let k = 0x0000_0012
        let l = 0x0000012
        let m = 0b000_10010101
        let n = [
          0xff00_ff00,  // comment
          0x00ff_00ff,  // comment
        ]
        """,
      findings: [
        FindingSpec("1️⃣", message: "group every 3 digits in this decimal literal using a '_' separator"),
        FindingSpec("2️⃣", message: "group every 4 digits in this hexadecimal literal using a '_' separator"),
        FindingSpec("3️⃣", message: "group every 8 digits in this binary literal using a '_' separator"),
        FindingSpec("4️⃣", message: "group every 3 digits in this decimal literal using a '_' separator"),
        FindingSpec("5️⃣", message: "group every 3 digits in this decimal literal using a '_' separator"),
        FindingSpec("6️⃣", message: "group every 4 digits in this hexadecimal literal using a '_' separator"),
        FindingSpec("7️⃣", message: "group every 8 digits in this binary literal using a '_' separator"),
        FindingSpec("8️⃣", message: "group every 4 digits in this hexadecimal literal using a '_' separator"),
        FindingSpec("9️⃣", message: "group every 4 digits in this hexadecimal literal using a '_' separator"),
      ]
    )
  }
}
