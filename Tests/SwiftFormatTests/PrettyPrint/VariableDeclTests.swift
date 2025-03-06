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

final class VariableDeclarationTests: PrettyPrintTestCase {
  func testBasicVariableDecl() {
    let input =
      """
      let x = firstVariable + secondVariable / thirdVariable + fourthVariable
      let y: Int = anotherVar + moreVar
      let (w, z, s): (Int, Double, Bool) = firstTuple + secondTuple
      """

    let expected =
      """
      let x =
        firstVariable
        + secondVariable
        / thirdVariable
        + fourthVariable
      let y: Int =
        anotherVar + moreVar
      let (w, z, s):
        (Int, Double, Bool) =
          firstTuple + secondTuple

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 30)
  }

  func testVariableDeclWithAttributes() {
    let input =
      """
      @NSCopying let a: Int = 123
      @NSCopying @NSManaged let a: Int = 123
      @NSCopying let areallylongvarname: Int = 123
      @NSCopying @NSManaged let areallylongvarname: Int = 123
      """

    let expected =
      """
      @NSCopying let a: Int = 123
      @NSCopying @NSManaged let a: Int = 123
      @NSCopying let areallylongvarname: Int =
        123
      @NSCopying @NSManaged
      let areallylongvarname: Int = 123

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 40)
  }

  func testMultipleBindings() {
    let input =
      """
      let a = 100, b = 200, c = 300, d = 400, e = 500, f = 600
      let a = 5, anotherReallyLongVariableName = something, longVariableName = longFunctionCall()
      let a = letsForceTheFirstOneToWrapAsWell, longVariableName = longFunctionCall()
      let a = firstThing + secondThing + thirdThing, b = firstThing + secondThing + thirdThing
      """

    let expected =
      """
      let a = 100, b = 200, c = 300, d = 400,
        e = 500, f = 600
      let a = 5,
        anotherReallyLongVariableName =
          something,
        longVariableName = longFunctionCall()
      let
        a = letsForceTheFirstOneToWrapAsWell,
        longVariableName = longFunctionCall()
      let
        a =
          firstThing + secondThing
          + thirdThing,
        b =
          firstThing + secondThing
          + thirdThing

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 40)
  }

  func testMultipleBindingsWithTypeAnnotations() {
    let input =
      """
      let a: Int = 100, b: ReallyLongTypeName = 200, c: (AnotherLongTypeName, AnotherOne) = 300
      """

    let expected =
      """
      let a: Int = 100,
        b: ReallyLongTypeName = 200,
        c: (AnotherLongTypeName, AnotherOne) =
          300

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 40)
  }

  func testAsyncLetBindings() {
    let input =
      """
      async let a = fetch("1.jpg")
      async let b: Image = fetch("2.jpg")
      async let secondPhotoToFetch = fetch("3.jpg")
      async let theVeryLastPhotoWeWant = fetch("4.jpg")
      """

    let expected =
      """
      async let a = fetch("1.jpg")
      async let b: Image = fetch(
        "2.jpg")
      async let secondPhotoToFetch =
        fetch("3.jpg")
      async let theVeryLastPhotoWeWant =
        fetch("4.jpg")

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 29)
  }
}
