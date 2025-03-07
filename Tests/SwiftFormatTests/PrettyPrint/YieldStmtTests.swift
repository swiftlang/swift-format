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

final class YieldStmtTests: PrettyPrintTestCase {
  func testBasic() {
    let input =
      """
      var foo: Int {
        _read{
          yield 1234567890
        }
        _modify{
          var someLongVariable = 0
          yield &someLongVariable
        }
      }
      """

    let expected =
      """
      var foo: Int {
        _read {
          yield 1234567890
        }
        _modify {
          var someLongVariable =
            0
          yield &someLongVariable
        }
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 19)
  }
}
