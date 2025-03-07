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

final class SemiColonTypeTests: PrettyPrintTestCase {
  func testSemicolon() {
    let input =
      """
      var foo = false
      guard !foo else { return }; defer { foo = true }

      struct Foo {
        var foo = false; var bar = true; var baz = false
      }
      """

    assertPrettyPrintEqual(input: input, expected: input + "\n", linelength: 50)
  }

  func testNoSemicolon() {
    let input =
      """
      var foo = false
      guard !foo else { return }
      defer { foo = true }

      struct Foo {
        var foo = false
        var bar = true
        var baz = false
      }
      """

    assertPrettyPrintEqual(input: input, expected: input + "\n", linelength: 50)
  }
}
