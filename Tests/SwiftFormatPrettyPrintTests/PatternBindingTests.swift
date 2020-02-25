import SwiftFormatConfiguration

final class PatternBindingTests: PrettyPrintTestCase {
  func testBindingIncludingTypeAnnotation() {
    let input =
      """
      let someObject: Foo = object
      let someObject: (foo: Foo, bar: SomeVeryLongTypeNameThatDefinitelyBreaks, baz: Baz) = foo(a, b, c, d)
      """

    let expected =
      """
      let someObject: Foo = object
      let someObject:
        (
          foo: Foo,
          bar:
            SomeVeryLongTypeNameThatDefinitelyBreaks,
          baz: Baz
        ) = foo(a, b, c, d)

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 40)
  }

  func testIgnoresDiscretionaryNewlineAfterColon() {
    let input =
      """
      let someObject:
        Foo = object
      let someObject:
        Foo = longerObjectName
      """

    let expected =
      """
      let someObject: Foo = object
      let someObject: Foo =
        longerObjectName

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 28)
  }

  func testGroupingIncludesTrailingComma() {
    let input =
      """
      let foo =  veryLongCondition
        ? firstOption
        : secondOption,
        bar = bar()
      """

    let expected =
      """
      let
        foo =
          veryLongCondition
          ? firstOption
          : secondOption,
        bar = bar()

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 18)
  }
}
