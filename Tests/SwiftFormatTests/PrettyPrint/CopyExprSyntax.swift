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

final class CopyExprTests: PrettyPrintTestCase {
  func testCopy() {
    assertPrettyPrintEqual(
      input: """
        let x = copy y
        """,
      expected: """
        let x =
          copy y

        """,
      linelength: 13
    )
  }
}
