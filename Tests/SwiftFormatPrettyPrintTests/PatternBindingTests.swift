import SwiftFormatConfiguration

public class PatternBindingTests: PrettyPrintTestCase {
  public func testBindingIncludingTypeAnnotation() {
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
}
