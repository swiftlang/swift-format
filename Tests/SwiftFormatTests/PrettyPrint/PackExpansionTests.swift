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

import SwiftFormat

final class PackExpansionTests: PrettyPrintTestCase {
  func testExprIgnoresDiscretionaryNewlineAfterRepeat() {
    let input =
      """
      func f<each T>(_ values: repeat each T) -> (repeat each T) {
        return (repeat
          each values)
      }
      """

    let expected =
      """
      func f<each T>(_ values: repeat each T) -> (repeat each T) {
        return (repeat each values)
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 80)
  }

  func testTypeIgnoresDiscretionaryNewlineAfterRepeat() {
    let input =
      """
      func f<each T>(_ values: repeat
        each T) {}
      """

    let expected =
      """
      func f<each T>(_ values: repeat each T) {}

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 80)
  }
}
