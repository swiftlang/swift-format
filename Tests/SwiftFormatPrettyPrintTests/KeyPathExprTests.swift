// TODO: Add more tests and figure out how we want to wrap keypaths. Right now, they just get
// printed without breaks.
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

    let expected =
      #"""
      let x = \.foo?
      let y = \.foo!.bar
      let z = a.map(\.foo!.bar)

      """#

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 80)
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
      //let x = \.?.foo
      //let y = \.?.foo.bar
      let z = a.map(\.?.foo.bar)
      """#

    let expected =
      #"""
      //let x = \.?.foo
      //let y = \.?.foo.bar
      let z = a.map(\.?.foo.bar)

      """#

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 80)
  }
}
