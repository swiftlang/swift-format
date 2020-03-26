final class DifferentiationAttributeTests: PrettyPrintTestCase {
  func testDifferentiable() {
    let input =
      """
      @differentiable(wrt: x, vjp: d where T: D)
      func foo<T>(_ x: T) -> T {}

      @differentiable(wrt: x, vjp: deriv where T: D)
      func foo<T>(_ x: T) -> T {}

      @differentiable(wrt: x, vjp: derivativeFoo where T: Differentiable)
      func foo<T>(_ x: T) -> T {}

      @differentiable(wrt: theVariableNamedX, vjp: derivativeFoo where T: Differentiable)
      func foo<T>(_ theVariableNamedX: T) -> T {}
      """

    let expected =
      """
      @differentiable(wrt: x, vjp: d where T: D)
      func foo<T>(_ x: T) -> T {}

      @differentiable(
        wrt: x, vjp: deriv where T: D
      )
      func foo<T>(_ x: T) -> T {}

      @differentiable(
        wrt: x, vjp: derivativeFoo
        where T: Differentiable
      )
      func foo<T>(_ x: T) -> T {}

      @differentiable(
        wrt: theVariableNamedX,
        vjp: derivativeFoo
        where T: Differentiable
      )
      func foo<T>(_ theVariableNamedX: T) -> T {}

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 43)
  }

  #if HAS_DERIVATIVE_REGISTRATION_ATTRIBUTE
    func testDerivative() {
      let input =
        """
        @derivative(of: foo, wrt: x)
        func deriv<T>(_ x: T) {}

        @derivative(of: foobar, wrt: x)
        func deriv<T>(_ x: T) {}

        @derivative(of: foobarbaz, wrt: theVariableNamedX)
        func deriv<T>(_ theVariableNamedX: T) {}
        """

      let expected =
        """
        @derivative(of: foo, wrt: x)
        func deriv<T>(_ x: T) {}

        @derivative(
          of: foobar, wrt: x
        )
        func deriv<T>(_ x: T) {}

        @derivative(
          of: foobarbaz,
          wrt: theVariableNamedX
        )
        func deriv<T>(
          _ theVariableNamedX: T
        ) {}

        """

      assertPrettyPrintEqual(input: input, expected: expected, linelength: 28)
    }

    func testTranspose() {
      let input =
        """
        @transpose(of: foo, wrt: 0)
        func trans<T>(_ v: T) {}

        @transpose(of: foobar, wrt: 0)
        func trans<T>(_ v: T) {}

        @transpose(of: someReallyLongName, wrt: 0)
        func trans<T>(_ theVariableNamedV: T) {}
        """

      let expected =
        """
        @transpose(of: foo, wrt: 0)
        func trans<T>(_ v: T) {}

        @transpose(
          of: foobar, wrt: 0
        )
        func trans<T>(_ v: T) {}

        @transpose(
          of: someReallyLongName,
          wrt: 0
        )
        func trans<T>(
          _ theVariableNamedV: T
        ) {}

        """

      assertPrettyPrintEqual(input: input, expected: expected, linelength: 27)
    }
  #endif
}
