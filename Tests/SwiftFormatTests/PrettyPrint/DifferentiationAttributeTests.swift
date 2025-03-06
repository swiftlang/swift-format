//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2025 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

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
}
