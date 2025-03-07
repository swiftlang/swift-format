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

final class BacktickTests: PrettyPrintTestCase {
  func testBackticks() {
    let input =
      """
      let `case` = 123
      enum MyEnum {
        case `break`
        case `continue`
        case `case`(var1: Int, Double)
      }

      """

    let expected =
      """
      let `case` = 123
      enum MyEnum {
        case `break`
        case `continue`
        case `case`(var1: Int, Double)
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 45)
  }
}
