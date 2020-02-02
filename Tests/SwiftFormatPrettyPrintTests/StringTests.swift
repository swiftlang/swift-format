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

  func testMultilineStringIsReindentedCorrectly() {
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
}
