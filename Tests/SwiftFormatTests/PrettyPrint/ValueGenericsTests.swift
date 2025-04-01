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

@_spi(ExperimentalLanguageFeatures) import SwiftParser

final class ValueGenericsTests: PrettyPrintTestCase {
  func testValueGenericDeclaration() {
    let input = "struct Foo<let n: Int> { static let bar = n }"
    let expected = """
      struct Foo<
        let n: Int
      > {
        static let bar = n
      }

      """
    assertPrettyPrintEqual(
      input: input,
      expected: expected,
      linelength: 20
    )
  }

  func testValueGenericTypeUsage() {
    let input =
      """
      let v1: Vector<100, Int>
      let v2 = Vector<100, Int>()
      """
    let expected = """
      let v1:
        Vector<
          100, Int
        >
      let v2 =
        Vector<
          100, Int
        >()

      """
    assertPrettyPrintEqual(
      input: input,
      expected: expected,
      linelength: 15
    )
  }
}
