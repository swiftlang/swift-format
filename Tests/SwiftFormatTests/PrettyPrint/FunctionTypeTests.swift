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

final class FunctionTypeTests: PrettyPrintTestCase {
  func testFunctionType() {
    let input =
      """
      func f(g: (_ somevalue: Int) -> String?) {
        let a = 123
        let b = "abc"
      }
      func f(g: (currentLevel: Int) -> String?) {
        let a = 123
        let b = "abc"
      }
      func f(g: (currentLevel: inout Int) -> String?) {
        let a = 123
        let b = "abc"
      }
      func f(g: (variable1: Int, variable2: Double, variable3: Bool) -> Double) {
        let a = 123
        let b = "abc"
      }
      func f(g: (variable1: Int, variable2: Double, variable3: Bool, variable4: String) -> Double) {
        let a = 123
        let b = "abc"
      }
      """

    let expected =
      """
      func f(g: (_ somevalue: Int) -> String?) {
        let a = 123
        let b = "abc"
      }
      func f(g: (currentLevel: Int) -> String?) {
        let a = 123
        let b = "abc"
      }
      func f(g: (currentLevel: inout Int) -> String?) {
        let a = 123
        let b = "abc"
      }
      func f(
        g: (variable1: Int, variable2: Double, variable3: Bool) ->
          Double
      ) {
        let a = 123
        let b = "abc"
      }
      func f(
        g: (
          variable1: Int, variable2: Double, variable3: Bool,
          variable4: String
        ) -> Double
      ) {
        let a = 123
        let b = "abc"
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 60)
  }

  func testFunctionTypeAsync() {
    let input =
      """
      func f(g: (_ somevalue: Int) async -> String?) {
        let a = 123
        let b = "abc"
      }
      func f(g: (currentLevel: Int) async -> String?) {
        let a = 123
        let b = "abc"
      }
      func f(g: (currentLevel: inout Int) async -> String?) {
        let a = 123
        let b = "abc"
      }
      func f(g: (variable1: Int, variable2: Double, variable3: Bool) async -> Double) {
        let a = 123
        let b = "abc"
      }
      func f(g: (variable1: Int, variable2: Double, variable3: Bool, variable4: String) async -> Double) {
        let a = 123
        let b = "abc"
      }
      """

    let expected =
      """
      func f(g: (_ somevalue: Int) async -> String?) {
        let a = 123
        let b = "abc"
      }
      func f(g: (currentLevel: Int) async -> String?) {
        let a = 123
        let b = "abc"
      }
      func f(g: (currentLevel: inout Int) async -> String?) {
        let a = 123
        let b = "abc"
      }
      func f(
        g: (variable1: Int, variable2: Double, variable3: Bool) async ->
          Double
      ) {
        let a = 123
        let b = "abc"
      }
      func f(
        g: (
          variable1: Int, variable2: Double, variable3: Bool,
          variable4: String
        ) async -> Double
      ) {
        let a = 123
        let b = "abc"
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 66)
  }

  func testFunctionTypeAsyncThrows() {
    let input =
      """
      func f(g: (_ somevalue: Int) async throws -> String?) {
        let a = 123
        let b = "abc"
      }
      func f(g: (currentLevel: Int) async throws -> String?) {
        let a = 123
        let b = "abc"
      }
      func f(g: (currentLevel: inout Int) async throws -> String?) {
        let a = 123
        let b = "abc"
      }
      func f(g: (variable1: Int, variable2: Double, variable3: Bool) async throws -> Double) {
        let a = 123
        let b = "abc"
      }
      func f(g: (variable1: Int, variable2: Double, variable3: Bool, variable4: String) async throws -> Double) {
        let a = 123
        let b = "abc"
      }
      """

    let expected =
      """
      func f(g: (_ somevalue: Int) async throws -> String?) {
        let a = 123
        let b = "abc"
      }
      func f(g: (currentLevel: Int) async throws -> String?) {
        let a = 123
        let b = "abc"
      }
      func f(g: (currentLevel: inout Int) async throws -> String?) {
        let a = 123
        let b = "abc"
      }
      func f(
        g: (variable1: Int, variable2: Double, variable3: Bool) async throws ->
          Double
      ) {
        let a = 123
        let b = "abc"
      }
      func f(
        g: (
          variable1: Int, variable2: Double, variable3: Bool, variable4: String
        ) async throws -> Double
      ) {
        let a = 123
        let b = "abc"
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 73)
  }

  func testFunctionTypeThrows() {
    let input =
      """
      func f(g: (_ somevalue: Int) throws -> String?) {
        let a = 123
        let b = "abc"
      }
      func f(g: (currentLevel: Int) throws -> String?) {
        let a = 123
        let b = "abc"
      }
      func f(g: (currentLevel: inout Int) throws -> String?) {
        let a = 123
        let b = "abc"
      }
      func f(g: (variable1: Int, variable2: Double, variable3: Bool) throws -> Double) {
        let a = 123
        let b = "abc"
      }
      func f(g: (variable1: Int, variable2: Double, variable3: Bool, variable4: String) throws -> Double) {
        let a = 123
        let b = "abc"
      }
      """

    let expected =
      """
      func f(g: (_ somevalue: Int) throws -> String?) {
        let a = 123
        let b = "abc"
      }
      func f(g: (currentLevel: Int) throws -> String?) {
        let a = 123
        let b = "abc"
      }
      func f(g: (currentLevel: inout Int) throws -> String?) {
        let a = 123
        let b = "abc"
      }
      func f(
        g: (variable1: Int, variable2: Double, variable3: Bool) throws ->
          Double
      ) {
        let a = 123
        let b = "abc"
      }
      func f(
        g: (
          variable1: Int, variable2: Double, variable3: Bool,
          variable4: String
        ) throws -> Double
      ) {
        let a = 123
        let b = "abc"
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 67)
  }

  func testFunctionTypeInOut() {
    let input =
      """
      func f(g: (firstArg: inout FirstArg, secondArg: inout SecondArg) -> Result) {
        let a = 123
        let b = "abc"
      }
      """

    let expected =
      """
      func f(
        g: (
          firstArg:
            inout
            FirstArg,
          secondArg:
            inout
            SecondArg
        ) -> Result
      ) {
        let a = 123
        let b = "abc"
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 17)
  }
}
