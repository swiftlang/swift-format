final class SubscriptExprTests: PrettyPrintTestCase {
  func testBasicSubscriptGetters() {
    let input =
      """
      let a = myCollection[index]
      let a = myCollection[label: index]
      let a = myCollection[index, default: someDefaultValue]
      """

    let expected =
      """
      let a = myCollection[index]
      let a = myCollection[label: index]
      let a = myCollection[
        index, default: someDefaultValue]

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 45)
  }

  func testBasicSubscriptSetters() {
    let input =
      """
      myCollection[index] = someValue
      myCollection[label: index] = someValue
      myCollection[index, default: someDefaultValue] = someValue
      """

    let expected =
      """
      myCollection[index] = someValue
      myCollection[label: index] = someValue
      myCollection[
        index, default: someDefaultValue] =
        someValue

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 45)
  }

  func testSubscriptGettersWithTrailingClosures() {
    let input =
      """
      let a = myCollection[index] { $0 < $1 }
      let a = myCollection[label: index] { arg1, arg2 in foo() }
      let a = myCollection[index, default: someDefaultValue] { arg1, arg2 in foo() }
      """

    let expected =
      """
      let a = myCollection[index] { $0 < $1 }
      let a = myCollection[label: index] {
        arg1, arg2 in foo()
      }
      let a = myCollection[
        index, default: someDefaultValue
      ] { arg1, arg2 in foo() }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 45)
  }

  func testSubscriptSettersWithTrailingClosures() {
    let input =
      """
      myCollection[index] { $0 < $1 } = someValue
      myCollection[label: index] { arg1, arg2 in foo() } = someValue
      myCollection[index, default: someDefaultValue] { arg1, arg2 in foo() } = someValue
      """

    let expected =
      """
      myCollection[index] { $0 < $1 } = someValue
      myCollection[label: index] { arg1, arg2 in
        foo()
      } = someValue
      myCollection[
        index, default: someDefaultValue
      ] { arg1, arg2 in foo() } = someValue

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 45)
  }

  func testGroupsTrailingComma() {
    let input =
      """
      myCollection[
        image: useLongName ? image(named: .longNameImage) : image(named: .veryLongNameImageZ),
        bar: bar]
      """

    let expected =
      """
      myCollection[
        image: useLongName
          ? image(named: .longNameImage)
          : image(named: .veryLongNameImageZ),
        bar: bar]

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 70)
  }

  func testDiscretionaryLineBreakBeforeTrailingClosure() {
    let input =
      """
      foo[a, b, c]
      {
        blah()
      }
      foo[
        a, b, c
      ]
      {
        blah()
      }
      foo[arg1, arg2, arg3, arg4, arg5, arg6, arg7]
      {
        blah()
      }
      foo[ab, arg1, arg2] {
        blah()
      }
      """

    let expected =
      """
      foo[a, b, c] {
        blah()
      }
      foo[
        a, b, c
      ] {
        blah()
      }
      foo[
        arg1, arg2, arg3,
        arg4, arg5, arg6,
        arg7
      ] {
        blah()
      }
      foo[ab, arg1, arg2]
      {
        blah()
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 20)
  }
}
