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

final class MemberTypeIdentifierTests: PrettyPrintTestCase {
  func testMemberTypes() {
    let input =
      """
      let a: One.Two.Three.Four.Five
      let b: One.Two.Three<Four, Five>
      """

    let expected =
      """
      let a:
        One.Two.Three
          .Four.Five
      let b:
        One.Two
          .Three<
            Four,
            Five
          >

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 15)
  }
}
