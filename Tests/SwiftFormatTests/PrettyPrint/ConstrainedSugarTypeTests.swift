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

final class ConstrainedSugarTypeTests: PrettyPrintTestCase {
  func testSomeTypes() {
    let input =
      """
      var body: some View
      func foo() -> some Foo
      """

    assertPrettyPrintEqual(input: input, expected: input + "\n", linelength: 25)

    let expected11 =
      """
      var body:
        some View
      func foo()
        -> some Foo

      """
    assertPrettyPrintEqual(input: input, expected: expected11, linelength: 11)
  }

  func testAnyTypes() {
    let input =
      """
      var body: any View
      func foo() -> any Foo
      """

    assertPrettyPrintEqual(input: input, expected: input + "\n", linelength: 25)

    let expected11 =
      """
      var body:
        any View
      func foo()
        -> any Foo

      """
    assertPrettyPrintEqual(input: input, expected: expected11, linelength: 11)
  }
}
