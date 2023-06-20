final class KeyPathExprTests: PrettyPrintTestCase {
  func testSimple() {
    let input =
      #"""
      let x = \.foo
      let y = \.foo.bar
      let z = a.map(\.foo.bar)
      """#

    let expected =
      #"""
      let x = \.foo
      let y = \.foo.bar
      let z = a.map(\.foo.bar)

      """#

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 80)
  }

  func testWithType() {
    let input =
      #"""
      let x = \Type.foo
      let y = \Type.foo.bar
      let z = a.map(\Type.foo.bar)
      """#

    let expected =
      #"""
      let x = \Type.foo
      let y = \Type.foo.bar
      let z = a.map(\Type.foo.bar)

      """#

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 80)
  }

  func testOptionalUnwrap() {
    let input =
      #"""
      let x = \.foo?
      let y = \.foo!.bar
      let z = a.map(\.foo!.bar)
      """#

    let expected80 =
      #"""
      let x = \.foo?
      let y = \.foo!.bar
      let z = a.map(\.foo!.bar)

      """#

    assertPrettyPrintEqual(input: input, expected: expected80, linelength: 80)

    let expected11 =
      #"""
      let x =
        \.foo?
      let y =
        \.foo!
        .bar
      let z =
        a.map(
          \.foo!
            .bar)

      """#

    assertPrettyPrintEqual(input: input, expected: expected11, linelength: 11)
  }

  func testSubscript() {
    let input =
      #"""
      let x = \.foo[0]
      let y = \.foo[0].bar
      let z = a.map(\.foo[0].bar)
      """#

    let expected =
      #"""
      let x = \.foo[0]
      let y = \.foo[0].bar
      let z = a.map(\.foo[0].bar)

      """#

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 80)
  }

  func testImplicitSelfUnwrap() {
    let input =
      #"""
      let x = \.?.foo
      let y = \.?.foo.bar
      let z = a.map(\.?.foo.bar)
      """#

    let expected80 =
      #"""
      let x = \.?.foo
      let y = \.?.foo.bar
      let z = a.map(\.?.foo.bar)

      """#

    assertPrettyPrintEqual(input: input, expected: expected80, linelength: 80)

    let expected11 =
      #"""
      let x =
        \.?.foo
      let y =
        \.?.foo
        .bar
      let z =
        a.map(
          \.?.foo
            .bar)

      """#

    assertPrettyPrintEqual(input: input, expected: expected11, linelength: 11)
  }

  func testWrapping() {
    let input =
      #"""
      let x = \ReallyLongType.reallyLongProperty.anotherLongProperty
      let x = \.reeeeallyLongProperty.anotherLongProperty
      let x = \.longProperty.a.b.c[really + long + expression].anotherLongProperty
      """#

    let expected =
      #"""
      let x =
        \ReallyLongType
        .reallyLongProperty
        .anotherLongProperty
      let x =
        \.reeeeallyLongProperty
        .anotherLongProperty
      let x =
        \.longProperty.a.b.c[
          really + long
            + expression
        ].anotherLongProperty

      """#

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 23)
  }
}
