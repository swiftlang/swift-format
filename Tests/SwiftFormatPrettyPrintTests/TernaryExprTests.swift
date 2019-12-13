public class TernaryExprTests: PrettyPrintTestCase {
  public func testTernaryExprs() {
    let input =
      """
      let x = a ? b : c
      let y = a ?b:c
      let z = a ? b: c
      let reallyLongName = a ? longTruePart : longFalsePart
      let reallyLongName = reallyLongCondition ? reallyLongTruePart : reallyLongFalsePart
      let reallyLongName = reallyLongCondition ? reallyReallyReallyLongTruePart : reallyLongFalsePart
      let reallyLongName = someCondition ? firstFunc(foo: arg) : secondFunc(bar: arg)
      """

    let expected =
      """
      let x = a ? b : c
      let y = a ? b : c
      let z = a ? b : c
      let reallyLongName =
        a ? longTruePart : longFalsePart
      let reallyLongName =
        reallyLongCondition
        ? reallyLongTruePart : reallyLongFalsePart
      let reallyLongName =
        reallyLongCondition
        ? reallyReallyReallyLongTruePart
        : reallyLongFalsePart
      let reallyLongName =
        someCondition
        ? firstFunc(foo: arg)
        : secondFunc(bar: arg)

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 45)
  }

  public func testTernaryExprsWithMultiplePartChoices() {
    let input =
      """
      let someLocalizedText =
        shouldUseTheFirstOption ? stringFunc(name: "Name1", comment: "short comment") :
        stringFunc(name: "Name2", comment: "Some very, extremely long comment", details: "Another comment")
      """
    let expected =
      """
      let someLocalizedText =
        shouldUseTheFirstOption
        ? stringFunc(name: "Name1", comment: "short comment")
        : stringFunc(
          name: "Name2", comment: "Some very, extremely long comment",
          details: "Another comment")

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 80)
  }

  public func testTernaryWithWrappingExpressions() {
    let input =
      """
      foo = firstTerm + secondTerm + thirdTerm ? firstTerm + secondTerm + thirdTerm : firstTerm + secondTerm + thirdTerm
      let foo = firstTerm + secondTerm + thirdTerm ? firstTerm + secondTerm + thirdTerm : firstTerm + secondTerm + thirdTerm
      foo = firstTerm || secondTerm && thirdTerm ? firstTerm + secondTerm + thirdTerm : firstTerm + secondTerm + thirdTerm
      let foo = firstTerm || secondTerm && thirdTerm ? firstTerm + secondTerm + thirdTerm : firstTerm + secondTerm + thirdTerm
      """

    let expected =
      """
      foo =
        firstTerm
          + secondTerm
          + thirdTerm
        ? firstTerm
          + secondTerm
          + thirdTerm
        : firstTerm
          + secondTerm
          + thirdTerm
      let foo =
        firstTerm
          + secondTerm
          + thirdTerm
        ? firstTerm
          + secondTerm
          + thirdTerm
        : firstTerm
          + secondTerm
          + thirdTerm
      foo =
        firstTerm
          || secondTerm
            && thirdTerm
        ? firstTerm
          + secondTerm
          + thirdTerm
        : firstTerm
          + secondTerm
          + thirdTerm
      let foo =
        firstTerm
          || secondTerm
            && thirdTerm
        ? firstTerm
          + secondTerm
          + thirdTerm
        : firstTerm
          + secondTerm
          + thirdTerm

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 15)
  }

  public func testNestedTernaries() {
    let input =
      """
      a = b ? c : d ? e : f
      let a = b ? c : d ? e : f
      a = b ? c0 + c1 : d ? e : f
      let a = b ? c0 + c1 : d ? e : f
      a = b ? c0 + c1 + c2 + c3 : d ? e : f
      let a = b ? c0 + c1 + c2 + c3 : d ? e : f
      foo = testA ? testB ? testC : testD : testE ? testF : testG
      let foo = testA ? testB ? testC : testD : testE ? testF : testG
      """

    let expected =
      """
      a =
        b
        ? c
        : d ? e : f
      let a =
        b
        ? c
        : d ? e : f
      a =
        b
        ? c0 + c1
        : d ? e : f
      let a =
        b
        ? c0 + c1
        : d ? e : f
      a =
        b
        ? c0 + c1
          + c2 + c3
        : d ? e : f
      let a =
        b
        ? c0 + c1
          + c2 + c3
        : d ? e : f
      foo =
        testA
        ? testB
          ? testC
          : testD
        : testE
          ? testF
          : testG
      let foo =
        testA
        ? testB
          ? testC
          : testD
        : testE
          ? testF
          : testG

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 15)
  }

  public func testExpressionStartsWithTernary() {
    // When the ternary itself doesn't already start on a continuation line, we don't have a way
    // to indent the continuation of the condition differently from the first and second choices,
    // because we don't want to double-indent the condition's continuation lines, and we don't want
    // to keep put the choices at the same indentation level as the condition (because that would
    // be the start of the statement). Neither of these choices is really ideal, unfortunately.
    let input =
      """
      condition ? callSomething() : callSomethingElse()
      condition && otherCondition ? callSomething() : callSomethingElse()
      (condition && otherCondition) ? callSomething() : callSomethingElse()
      """

    let expected =
      """
      condition
        ? callSomething()
        : callSomethingElse()
      condition
        && otherCondition
        ? callSomething()
        : callSomethingElse()
      (condition
        && otherCondition)
        ? callSomething()
        : callSomethingElse()

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 25)
  }
}
