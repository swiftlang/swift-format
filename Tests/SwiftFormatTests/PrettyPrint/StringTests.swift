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

@_spi(Rules) @_spi(Testing) import SwiftFormat

final class StringTests: PrettyPrintTestCase {
  func testStrings() {
    let input =
      """
      let a = "abc"
      myFun("Some string \\(a + b)")
      let b = "A really long string that should not wrap"
      let c = "A really long string with \\(a + b) some expressions \\(c + d)"
      """

    let expected =
      """
      let a = "abc"
      myFun("Some string \\(a + b)")
      let b =
        "A really long string that should not wrap"
      let c =
        "A really long string with \\(a + b) some expressions \\(c + d)"

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 35)
  }

  func testLongMultilinestringIsWrapped() {
    let input =
      #"""
      let someString = """
        this string's total lengths will be longer than the column limit even though its individual lines are as well, whoops.
        """
      """#

    let expected =
      #"""
      let someString = """
        this string's total \
        lengths will be longer \
        than the column limit even \
        though its individual \
        lines are as well, whoops.
        """

      """#

    var config = Configuration()
    config.reflowMultilineStringLiterals = .onlyLinesOverLength
    assertPrettyPrintEqual(
      input: input,
      expected: expected,
      linelength: 30,
      configuration: config
    )
  }

  func testMultilineStringIsNotReformattedWithIgnore() {
    let input =
      #"""
      let someString =
        // swift-format-ignore
        """
        lines \
        are \
        short.
        """
      """#

    let expected =
      #"""
      let someString =
        // swift-format-ignore
        """
        lines \
        are \
        short.
        """

      """#

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 30)
  }

  func testMultilineStringIsNotReformattedWithReflowDisabled() {
    let input =
      #"""
      let someString =
        """
        lines \
        are \
        short.
        """
      """#

    let expected =
      #"""
      let someString =
        """
        lines \
        are \
        short.
        """

      """#

    var config = Configuration()
    config.reflowMultilineStringLiterals = .onlyLinesOverLength
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 30, configuration: config)
  }

  func testMultilineStringWithInterpolations() {
    let input =
      #"""
      if true {
        guard let opt else {
          functionCall("""
            Lorem ipsum dolor sit amet, consectetur adipiscing elit. Donec rutrum libero \(2) \(testVariable) ids risus placerat imperdiet. Praesent fringilla vel nisi sed fermentum. In vitae purus feugiat, euismod nulla in, rhoncus leo. Suspendisse feugiat sapien lobortis facilisis malesuada. Aliquam feugiat suscipit accumsan. Praesent tempus fermentum est, vel blandit mi pretium a. Proin in posuere sapien. Nunc tincidunt efficitur ante id fermentum.
            """)
        }
      }
      """#

    let expected =
      #"""
      if true {
        guard let opt else {
          functionCall(
            """
            Lorem ipsum dolor sit amet, consectetur adipiscing elit. Donec rutrum libero \(2) \
            \(testVariable) ids risus placerat imperdiet. Praesent fringilla vel nisi sed fermentum. In \
            vitae purus feugiat, euismod nulla in, rhoncus leo. Suspendisse feugiat sapien lobortis \
            facilisis malesuada. Aliquam feugiat suscipit accumsan. Praesent tempus fermentum est, vel \
            blandit mi pretium a. Proin in posuere sapien. Nunc tincidunt efficitur ante id fermentum.
            """)
        }
      }

      """#

    var config = Configuration()
    config.reflowMultilineStringLiterals = .onlyLinesOverLength
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 100, configuration: config)
  }

  func testMutlilineStringsRespectsHardLineBreaks() {
    let input =
      #"""
      """
      Lorem ipsum dolor sit amet, consectetur adipiscing elit. Donec rutrum libero ids risus placerat imperdiet. Praesent fringilla vel nisi sed fermentum. In vitae purus feugiat, euismod nulla in, rhoncus leo.
      Suspendisse feugiat sapien lobortis facilisis malesuada. Aliquam feugiat suscipit accumsan. Praesent tempus fermentum est, vel blandit mi pretium a. Proin in posuere sapien. Nunc tincidunt efficitur ante id fermentum.
      """
      """#

    let expected =
      #"""
      """
      Lorem ipsum dolor sit amet, consectetur adipiscing elit. Donec rutrum libero ids risus placerat \
      imperdiet. Praesent fringilla vel nisi sed fermentum. In vitae purus feugiat, euismod nulla in, \
      rhoncus leo.
      Suspendisse feugiat sapien lobortis facilisis malesuada. Aliquam feugiat suscipit accumsan. \
      Praesent tempus fermentum est, vel blandit mi pretium a. Proin in posuere sapien. Nunc tincidunt \
      efficitur ante id fermentum.
      """

      """#

    var config = Configuration()
    config.reflowMultilineStringLiterals = .onlyLinesOverLength
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 100, configuration: config)
  }

  func testMultilineStringsWrapAroundInterpolations() {
    let input =
      #"""
      """
      An interpolation should be treated as a single "word" and can't be broken up \(aLongVariableName + anotherLongVariableName), so no line breaks should be available within the expr.
      """
      """#

    let expected =
      #"""
      """
      An interpolation should be treated as a single "word" and can't be broken up \
      \(aLongVariableName + anotherLongVariableName), so no line breaks should be available within the \
      expr.
      """

      """#

    var config = Configuration()
    config.reflowMultilineStringLiterals = .onlyLinesOverLength
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 100, configuration: config)
  }

  func testMultilineStringOpenQuotesDoNotWrapIfStringIsVeryLong() {
    let input =
      #"""
      let someString = """
        this string's total
        length will be longer
        than the column limit
        even though none of
        its individual lines
        are.
        """
      """#

    assertPrettyPrintEqual(input: input, expected: input + "\n", linelength: 30)
  }

  func testMultilineStringWithAssignmentOperatorInsteadOfPatternBinding() {
    let input =
      #"""
      someString = """
        this string's total
        length will be longer
        than the column limit
        even though none of
        its individual lines
        are.
        """
      """#

    assertPrettyPrintEqual(input: input, expected: input + "\n", linelength: 30)
  }

  func testMultilineStringUnlabeledArgumentIsReindentedCorrectly() {
    let input =
      #"""
      functionCall(longArgument, anotherLongArgument, """
            some multi-
              line string
            """)
      """#

    let expected =
      #"""
      functionCall(
        longArgument,
        anotherLongArgument,
        """
        some multi-
          line string
        """)

      """#

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 25)
  }

  func testMultilineStringLabeledArgumentIsReindentedCorrectly() {
    let input =
      #"""
      functionCall(longArgument: x, anotherLongArgument: y, longLabel: """
            some multi-
              line string
            """)
      """#

    let expected =
      #"""
      functionCall(
        longArgument: x,
        anotherLongArgument: y,
        longLabel: """
          some multi-
            line string
          """)

      """#

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 25)
  }

  func testMultilineStringWithWordLongerThanLineLength() {
    let input =
      #"""
      """
      there isn't an opportunity to break up this long url: https://www.cool-math-games.org/games/id?=01913310-b7c3-77d8-898e-300ccd451ea8
      """
      """#
    let expected =
      #"""
      """
      there isn't an opportunity to break up this long url: \
      https://www.cool-math-games.org/games/id?=01913310-b7c3-77d8-898e-300ccd451ea8
      """

      """#

    var config = Configuration()
    config.reflowMultilineStringLiterals = .onlyLinesOverLength
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 70, configuration: config)
  }

  func testMultilineStringInterpolations() {
    let input =
      #"""
      let x = """
        \(1) 2 3
        4 \(5) 6
        7 8 \(9)
        """
      """#

    assertPrettyPrintEqual(input: input, expected: input + "\n", linelength: 25)
  }

  func testMultilineRawString() {
    let input =
      ##"""
      let x = #"""
        """who would
        ever do this"""
        """#
      """##

    assertPrettyPrintEqual(input: input, expected: input + "\n", linelength: 25)
  }

  func testMultilineRawStringOpenQuotesWrap() {
    let input =
      #"""
      let aLongVariableName = """
        some
        multi-
        line
        string
        """
      """#

    let expected =
      #"""
      let aLongVariableName =
        """
        some
        multi-
        line
        string
        """

      """#

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 25)
  }

  func testMultilineStringAutocorrectMisalignedLines() {
    let input =
      #"""
      let x = """
          the
        second
          line is
          wrong
          """
      """#

    let expected =
      #"""
      let x = """
        the
        second
        line is
        wrong
        """

      """#

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 25)
  }

  func testMultilineStringKeepsBlankLines() {
    // This test not only ensures that the blank lines are retained in the first place, but that
    // the newlines are mandatory and not collapsed to the maximum number allowed by the formatter
    // configuration.
    let input =
      #"""
      let x = """


          there should be




          gaps all around here


          """
      """#

    let expected =
      #"""
      let x = """


        there should be




        gaps all around here


        """

      """#

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 25)
  }

  func testMultilineStringReflowsTrailingBackslashes() {
    let input =
      #"""
      let x = """
          there should be \
          backslashes at \
          the end of \
          every line \
          except this one
          """
      """#

    let expected =
      #"""
      let x = """
        there should be \
        backslashes at \
        the end of every \
        line except this \
        one
        """

      """#

    var config = Configuration.forTesting
    config.reflowMultilineStringLiterals = .always
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 20, configuration: config)
  }

  func testRawMultilineStringIsNotFormatted() {
    let input =
      ##"""
      #"""
      this is a long line that is not broken.
      """#
      """##
    let expected =
      ##"""
      #"""
      this is a long line that is not broken.
      """#

      """##

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 10)
  }

  func testMultilineStringIsNotFormattedWithNeverReflowBehavior() {
    let input =
      #"""
      """
      this is a long line that is not broken.
      """
      """#
    let expected =
      #"""
      """
      this is a long line that is not broken.
      """

      """#

    var config = Configuration.forTesting
    config.reflowMultilineStringLiterals = .never
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 10, configuration: config)
  }

  func testMultilineStringInParenthesizedExpression() {
    let input =
      #"""
      let x = ("""
          this is a
          multiline string
          """)
      """#

    let expected =
      #"""
      let x =
        ("""
        this is a
        multiline string
        """)

      """#

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 20)
  }

  func testMultilineStringAfterStatementKeyword() {
    let input =
      #"""
      return """
          this is a
          multiline string
          """
      return """
          this is a
          multiline string
          """ + "hello"
      """#

    let expected =
      #"""
      return """
        this is a
        multiline string
        """
      return """
        this is a
        multiline string
        """ + "hello"

      """#

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 20)
  }

  func testMultilineStringsInExpressionWithNarrowMargins() {
    let input =
      #"""
      x = """
          abcdefg
          hijklmn
          """ + """
          abcde
          hijkl
          """
      """#

    let expected =
      #"""
      x = """
        abcdefg
        hijklmn
        """
          + """
          abcde
          hijkl
          """

      """#

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 9)
  }

  func testMultilineStringsInExpression() {
    let input =
      #"""
      let x = """
          this is a
          multiline string
          """ + """
          this is more
          multiline string
          """
      """#

    let expected =
      #"""
      let x = """
        this is a
        multiline string
        """ + """
          this is more
          multiline string
          """

      """#

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 20)
  }

  func testLeadingMultilineStringsInOtherExpressions() {
    // The stacked indentation behavior needs to drill down into different node types to find the
    // leftmost multiline string literal. This makes sure that we cover various cases.
    let input =
      #"""
      let bytes = """
        {
          "key": "value"
        }
        """.utf8.count
      let json = """
        {
          "key": "value"
        }
        """.data(using: .utf8)
      let slice = """
        {
          "key": "value"
        }
        """[...]
      let forceUnwrap = """
        {
          "key": "value"
        }
        """!
      let optionalChaining = """
        {
          "key": "value"
        }
        """?
      let postfix = """
        {
          "key": "value"
        }
        """^*^
      let prefix = +"""
        {
          "key": "value"
        }
        """
      let postfixIf = """
        {
          "key": "value"
        }
        """
        #if FLAG
          .someMethod
        #endif

      // Like the infix operator cases, cast operations force the string's open quotes to wrap.
      // This could be considered consistent if you look at it through the right lens. Let's make
      // sure to test it so that we can see if the behavior ever changes accidentally.
      let cast =
        """
        {
          "key": "value"
        }
        """ as NSString
      let typecheck =
        """
        {
          "key": "value"
        }
        """ is NSString
      """#
    assertPrettyPrintEqual(input: input, expected: input + "\n", linelength: 100)
  }

  func testMultilineStringsAsEnumRawValues() {
    let input = #"""
      enum E: String {
        case x = """
          blah blah
          """
      }
      """#
    assertPrettyPrintEqual(input: input, expected: input + "\n", linelength: 100)
  }

  func testMultilineStringsNestedInAnotherWrappingContext() {
    let input =
      #"""
      guard
          let x = """
              blah
              blah
              """.data(using: .utf8) else {
          print(x)
      }
      """#

    let expected =
      #"""
      guard
        let x = """
          blah
          blah
          """.data(using: .utf8)
      else {
        print(x)
      }

      """#
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 100)
  }

  func testEmptyMultilineStrings() {
    let input =
      ##"""
      let x = """
        """
      let y =
        """
        """
      let x = #"""
        """#
      let y =
        #"""
        """#
      """##

    assertPrettyPrintEqual(input: input, expected: input + "\n", linelength: 20)
  }

  func testOnlyBlankLinesMultilineStrings() {
    let input =
      ##"""
      let x = """

        """
      let y =
        """

        """
      let x = #"""

        """#
      let y =
        #"""

        """#
      """##

    assertPrettyPrintEqual(input: input, expected: input + "\n", linelength: 20)
  }
}
