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

final class IndentBlankLinesTests: PrettyPrintTestCase {
  func testIndentBlankLinesEnabled() {
    let input =
      """
      class A {
        func foo() -> Int {
          return 1
        }
      \u{0020}\u{0020}
        func bar() -> Int {
          return 2
        }
      }
      """

    let expected =
      """
      class A {
        func foo() -> Int {
          return 1
        }
      \u{0020}\u{0020}
        func bar() -> Int {
          return 2
        }
      }

      """
    var config = Configuration.forTesting
    config.indentBlankLines = true
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 80, configuration: config)
  }

  func testIndentBlankLinesDisabled() {
    let input =
      """
      class A {
        func foo() -> Int {
          return 1
        }
      \u{0020}\u{0020}
        func bar() -> Int {
          return 2
        }
      }
      """

    let expected =
      """
      class A {
        func foo() -> Int {
          return 1
        }

        func bar() -> Int {
          return 2
        }
      }

      """
    var config = Configuration.forTesting
    config.indentBlankLines = false
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 80, configuration: config)
  }

  func testLineWithMoreWhitespacesThanIndentation() {
    let input =
      """
      class A {
        func foo() -> Int {
          return 1
        }
      \u{0020}\u{0020}\u{0020}\u{0020}\u{0020}
        func bar() -> Int {
          return 2
        }
      }
      """

    let expected =
      """
      class A {
        func foo() -> Int {
          return 1
        }
      \u{0020}\u{0020}
        func bar() -> Int {
          return 2
        }
      }

      """
    var config = Configuration.forTesting
    config.indentBlankLines = true
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 80, configuration: config)
  }

  func testLineWithFewerWhitespacesThanIndentation() {
    let input =
      """
      class A {
        func foo() -> Int {
          return 1
        }
      \u{0020}
        func bar() -> Int {
          return 2
        }
      }
      """

    let expected =
      """
      class A {
        func foo() -> Int {
          return 1
        }
      \u{0020}\u{0020}
        func bar() -> Int {
          return 2
        }
      }

      """
    var config = Configuration.forTesting
    config.indentBlankLines = true
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 80, configuration: config)
  }

  func testLineWithoutWhitespace() {
    let input =
      """
      class A {
        func foo() -> Int {
          return 1
        }

        func bar() -> Int {
          return 2
        }
      }
      """

    let expected =
      """
      class A {
        func foo() -> Int {
          return 1
        }
      \u{0020}\u{0020}
        func bar() -> Int {
          return 2
        }
      }

      """
    var config = Configuration.forTesting
    config.indentBlankLines = true
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 80, configuration: config)
  }

  func testConsecutiveLinesWithMoreWhitespacesThanIndentation() {
    let input =
      """
      class A {
        func foo() -> Int {
          return 1
        }
      \u{0020}\u{0020}\u{0020}\u{0020}\u{0020}
      \u{0020}\u{0020}\u{0020}\u{0020}
        func bar() -> Int {
          return 2
        }
      }
      """

    let expected =
      """
      class A {
        func foo() -> Int {
          return 1
        }
      \u{0020}\u{0020}
        func bar() -> Int {
          return 2
        }
      }

      """
    var config = Configuration.forTesting
    config.indentBlankLines = true
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 80, configuration: config)
  }

  func testConsecutiveLinesWithFewerWhitespacesThanIndentation() {
    let input =
      """
      class A {
        func foo() -> Int {
          return 1
        }
      \u{0020}

        func bar() -> Int {
          return 2
        }
      }
      """

    let expected =
      """
      class A {
        func foo() -> Int {
          return 1
        }
      \u{0020}\u{0020}
        func bar() -> Int {
          return 2
        }
      }

      """
    var config = Configuration.forTesting
    config.indentBlankLines = true
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 80, configuration: config)
  }

  func testConsecutiveLinesWithoutWhitespace() {
    let input =
      """
      class A {
        func foo() -> Int {
          return 1
        }


        func bar() -> Int {
          return 2
        }
      }
      """

    let expected =
      """
      class A {
        func foo() -> Int {
          return 1
        }
      \u{0020}\u{0020}
        func bar() -> Int {
          return 2
        }
      }

      """
    var config = Configuration.forTesting
    config.indentBlankLines = true
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 80, configuration: config)
  }

  func testExpressionsWithUnnecessaryWhitespaces() {
    let input =
      """
          class A {
        func   foo() -> Int {
          return 1
        }
      \u{0020}\u{0020}
        func bar()    -> Int {
          return 2
        }
      }
      """

    let expected =
      """
      class A {
        func foo() -> Int {
          return 1
        }
      \u{0020}\u{0020}
        func bar() -> Int {
          return 2
        }
      }

      """
    var config = Configuration.forTesting
    config.indentBlankLines = true
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 80, configuration: config)
  }
}
