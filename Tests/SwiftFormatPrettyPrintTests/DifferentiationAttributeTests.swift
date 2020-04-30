final class DifferentiationAttributeTests: PrettyPrintTestCase {
  func testDifferentiable() {
    let input =
      """
      @differentiable(wrt: x where T: D)
      func foo<T>(_ x: T) -> T {}

      @differentiable(wrt: x where T: Differentiable)
      func foo<T>(_ x: T) -> T {}

      @differentiable(wrt: theVariableNamedX where T: Differentiable)
      func foo<T>(_ theVariableNamedX: T) -> T {}
      """

    let expected =
      """
      @differentiable(wrt: x where T: D)
      func foo<T>(_ x: T) -> T {}

      @differentiable(
        wrt: x where T: Differentiable
      )
      func foo<T>(_ x: T) -> T {}

      @differentiable(
        wrt: theVariableNamedX
        where T: Differentiable
      )
      func foo<T>(_ theVariableNamedX: T) -> T {}

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 43)
  }

  func testDifferentiableWithOnlyWhereClause() {
    let input =
      """
      @differentiable(where T: D)
      func foo<T>(_ x: T) -> T {}

      @differentiable(where T: Differentiable)
      func foo<T>(_ x: T) -> T {}
      """

    let expected =
      """
      @differentiable(where T: D)
      func foo<T>(_ x: T) -> T {}

      @differentiable(
        where T: Differentiable
      )
      func foo<T>(_ x: T) -> T {}

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 28)
  }

  func testDifferentiableWithMultipleParameters() {
    let input =
      """
      @differentiable(wrt: (x, y))
      func foo<T>(_ x: T) -> T {}

      @differentiable(wrt: (self, x, y))
      func foo<T>(_ x: T) -> T {}

      @differentiable(wrt: (theVariableNamedSelf, theVariableNamedX, theVariableNamedY))
      func foo<T>(_ x: T) -> T {}
      """

    let expected =
      """
      @differentiable(wrt: (x, y))
      func foo<T>(_ x: T) -> T {}

      @differentiable(
        wrt: (self, x, y)
      )
      func foo<T>(_ x: T) -> T {}

      @differentiable(
        wrt: (
          theVariableNamedSelf,
          theVariableNamedX,
          theVariableNamedY
        )
      )
      func foo<T>(_ x: T) -> T {}

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 28)
  }

  func testDerivative() {
    #if HAS_DERIVATIVE_REGISTRATION_ATTRIBUTE
      let input =
        """
        @derivative(of: foo)
        func deriv<T>() {}

        @derivative(of: foo, wrt: x)
        func deriv<T>(_ x: T) {}

        @derivative(of: foobar, wrt: x)
        func deriv<T>(_ x: T) {}

        @derivative(of: foobarbaz, wrt: theVariableNamedX)
        func deriv<T>(_ theVariableNamedX: T) {}
        """

      let expected =
        """
        @derivative(of: foo)
        func deriv<T>() {}

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
    #endif
  }

  func testTranspose() {
    #if HAS_DERIVATIVE_REGISTRATION_ATTRIBUTE
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
    #endif
  }
}
