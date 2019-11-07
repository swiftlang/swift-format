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
      shortName = wxyz + aaaaaa
        + bbbbbb + cccccc
      longerName = wxyz + aaaaaa
        + bbbbbb + cccccc || zzzzzzz

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 30)
  }

  public func testAssignmentFromFunctionCalls() {
    let input =
      """
      result = firstOp + secondOp + someOpFetchingFunc(foo, bar: bar, baz: baz)
      result = someOpFetchingFunc(foo, bar: bar, baz: baz)
      result += someOpFetchingFunc(foo, bar: bar, baz: baz)
      result = someOpFetchingFunc(foo, bar: bar, baz: baz) + someOtherOperand + andAThirdOneForReasons
      let result = firstOp + secondOp + someOpFetchingFunc(foo, bar: bar, baz: baz)
      let result = someOpFetchingFunc(foo, bar: bar, baz: baz)
      let result = someOpFetchingFunc(foo, bar: bar, baz: baz) + someOtherOperand + andAThirdOneForReasons
      """
    let expected =
      """
      result = firstOp + secondOp
        + someOpFetchingFunc(
          foo, bar: bar, baz: baz)
      result = someOpFetchingFunc(
        foo, bar: bar, baz: baz)
      result += someOpFetchingFunc(
        foo, bar: bar, baz: baz)
      result = someOpFetchingFunc(
        foo, bar: bar, baz: baz)
        + someOtherOperand
        + andAThirdOneForReasons
      let result = firstOp + secondOp
        + someOpFetchingFunc(
          foo, bar: bar, baz: baz)
      let result = someOpFetchingFunc(
        foo, bar: bar, baz: baz)
      let result = someOpFetchingFunc(
        foo, bar: bar, baz: baz)
        + someOtherOperand
        + andAThirdOneForReasons

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 35)
  }
}
