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
      let reallyLongName = a
        ? longTruePart : longFalsePart
      let reallyLongName = reallyLongCondition
        ? reallyLongTruePart : reallyLongFalsePart
      let reallyLongName = reallyLongCondition
        ? reallyReallyReallyLongTruePart
        : reallyLongFalsePart
      let reallyLongName = someCondition
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
      let someLocalizedText = shouldUseTheFirstOption
        ? stringFunc(name: "Name1", comment: "short comment")
        : stringFunc(
          name: "Name2", comment: "Some very, extremely long comment",
          details: "Another comment")

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 80)
  }
}
