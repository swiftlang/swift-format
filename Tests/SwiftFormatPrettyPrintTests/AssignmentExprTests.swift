import SwiftFormatConfiguration

public class AssignmentExprTests: PrettyPrintTestCase {
  public func testBasicAssignmentExprs() {
    let input =
      """
      foo = bar
      someVeryLongVariableName = anotherPrettyLongVariableName
      shortName = superLongNameForAVariable
      """
    let expected =
      """
      foo = bar
      someVeryLongVariableName =
        anotherPrettyLongVariableName
      shortName =
        superLongNameForAVariable

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 30)
  }

  public func testAssignmentExprsWithGroupedOperators() {
    let input =
      """
      someVeryLongVariableName = anotherPrettyLongVariableName && someOtherOperand
      shortName = wxyz + aaaaaa + bbbbbb + cccccc
      longerName = wxyz + aaaaaa + bbbbbb + cccccc || zzzzzzz
      """
    let expected =
      """
      someVeryLongVariableName =
        anotherPrettyLongVariableName
        && someOtherOperand
      shortName =
        wxyz + aaaaaa + bbbbbb
        + cccccc
      longerName =
        wxyz + aaaaaa + bbbbbb
        + cccccc || zzzzzzz

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 30)
  }

  public func testAssignmentOperatorFromSequenceWithFunctionCalls() {
    let input =
        """
        result = firstOp + secondOp + someOpFetchingFunc(foo, bar: bar, baz: baz)
        result = someOpFetchingFunc(foo, bar: bar, baz: baz)
        result += someOpFetchingFunc(foo, bar: bar, baz: baz)
        result = someOpFetchingFunc(foo, bar: bar, baz: baz) + someOtherOperand + andAThirdOneForReasons
        result = firstOp + secondOp + thirdOp + someOpFetchingFunc(foo, bar, baz) + nextOp + lastOp
        result += firstOp + secondOp + thirdOp + someOpFetchingFunc(foo, bar, baz) + nextOp + lastOp
        """

      let expectedWithArgBinPacking =
        """
        result =
          firstOp + secondOp
          + someOpFetchingFunc(
            foo, bar: bar, baz: baz)
        result = someOpFetchingFunc(
          foo, bar: bar, baz: baz)
        result += someOpFetchingFunc(
          foo, bar: bar, baz: baz)
        result =
          someOpFetchingFunc(
            foo, bar: bar, baz: baz)
          + someOtherOperand
          + andAThirdOneForReasons
        result =
          firstOp + secondOp + thirdOp
          + someOpFetchingFunc(
            foo, bar, baz) + nextOp
          + lastOp
        result +=
          firstOp + secondOp + thirdOp
          + someOpFetchingFunc(
            foo, bar, baz) + nextOp
          + lastOp

        """

      var config = Configuration()
      config.lineBreakBeforeEachArgument = false
      assertPrettyPrintEqual(
        input: input, expected: expectedWithArgBinPacking, linelength: 35, configuration: config)

      let expectedWithBreakBeforeEachArg =
        """
        result =
          firstOp + secondOp
          + someOpFetchingFunc(
            foo,
            bar: bar,
            baz: baz
          )
        result = someOpFetchingFunc(
          foo,
          bar: bar,
          baz: baz
        )
        result += someOpFetchingFunc(
          foo,
          bar: bar,
          baz: baz
        )
        result =
          someOpFetchingFunc(
            foo,
            bar: bar,
            baz: baz
          ) + someOtherOperand
          + andAThirdOneForReasons
        result =
          firstOp + secondOp + thirdOp
          + someOpFetchingFunc(
            foo,
            bar,
            baz
          ) + nextOp + lastOp
        result +=
          firstOp + secondOp + thirdOp
          + someOpFetchingFunc(
            foo,
            bar,
            baz
          ) + nextOp + lastOp

        """
      config.lineBreakBeforeEachArgument = true
      assertPrettyPrintEqual(
        input: input, expected: expectedWithBreakBeforeEachArg, linelength: 35, configuration: config)
  }

  public func testAssignmentPatternBindingFromSequenceWithFunctionCalls() {
    let input =
      """
      let result = firstOp + secondOp + someOpFetchingFunc(foo, bar: bar, baz: baz)
      let result = someOpFetchingFunc(foo, bar: bar, baz: baz)
      let result = someOpFetchingFunc(foo, bar: bar, baz: baz) + someOtherOperand + andAThirdOneForReasons
      let result = firstOp + secondOp + thirdOp + someOpFetchingFunc(foo, bar, baz) + nextOp + lastOp
      """

    let expectedWithArgBinPacking =
      """
      let result =
        firstOp + secondOp
        + someOpFetchingFunc(
          foo, bar: bar, baz: baz)
      let result = someOpFetchingFunc(
        foo, bar: bar, baz: baz)
      let result =
        someOpFetchingFunc(
          foo, bar: bar, baz: baz)
        + someOtherOperand
        + andAThirdOneForReasons
      let result =
        firstOp + secondOp + thirdOp
        + someOpFetchingFunc(
          foo, bar, baz) + nextOp
        + lastOp

      """

    var config = Configuration()
    config.lineBreakBeforeEachArgument = false
    assertPrettyPrintEqual(
      input: input, expected: expectedWithArgBinPacking, linelength: 35, configuration: config)

    let expectedWithBreakBeforeEachArg =
      """
      let result =
        firstOp + secondOp
        + someOpFetchingFunc(
          foo,
          bar: bar,
          baz: baz
        )
      let result = someOpFetchingFunc(
        foo,
        bar: bar,
        baz: baz
      )
      let result =
        someOpFetchingFunc(
          foo,
          bar: bar,
          baz: baz
        ) + someOtherOperand
        + andAThirdOneForReasons
      let result =
        firstOp + secondOp + thirdOp
        + someOpFetchingFunc(
          foo,
          bar,
          baz
        ) + nextOp + lastOp

      """
    config.lineBreakBeforeEachArgument = true
    assertPrettyPrintEqual(
      input: input, expected: expectedWithBreakBeforeEachArg, linelength: 35, configuration: config)
  }
}
