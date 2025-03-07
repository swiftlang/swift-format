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

final class DiscardStmtTests: PrettyPrintTestCase {
  func testDiscard() {
    assertPrettyPrintEqual(
      input: """
        discard self
        """,
      expected: """
        discard self

        """,
      linelength: 9
    )
  }
}
