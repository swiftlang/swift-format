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
