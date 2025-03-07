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

final class GuardStmtTests: PrettyPrintTestCase {
  func testGuardStatement() {
    let input =
      """
      guard var1 > var2 else {
        let a = 23
        var b = "abc"
      }
      guard var1, var2 > var3 else {
        let a = 23
        var b = "abc"
      }
      guard let var1 = someFunction(), let var2 = myFun() else {
        let a = 23
        var b = "abc"
      }
      guard let var1 = someFunction(), let var2 = myLongFunction() else {
        let a = 23
        var b = "abc"
      }
      """

    let expected =
      """
      guard var1 > var2 else {
        let a = 23
        var b = "abc"
      }
      guard var1, var2 > var3 else {
        let a = 23
        var b = "abc"
      }
      guard let var1 = someFunction(),
        let var2 = myFun()
      else {
        let a = 23
        var b = "abc"
      }
      guard let var1 = someFunction(),
        let var2 = myLongFunction()
      else {
        let a = 23
        var b = "abc"
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 35)
  }

  func testGuardWithFuncCall() {
    let input =
      """
      guard let myvar = myClass.itsFunc(first: .someStuff, second: .moreStuff).first else {
        // do stuff
      }
      guard let myvar1 = myClass.itsFunc(first: .someStuff, second: .moreStuff).first,
      let myvar2 = myClass.diffFunc(first: .someStuff, second: .moreStuff).first else {
        // do stuff
      }
      """

    let expected =
      """
      guard
        let myvar = myClass.itsFunc(
          first: .someStuff,
          second: .moreStuff
        ).first
      else {
        // do stuff
      }
      guard
        let myvar1 = myClass.itsFunc(
          first: .someStuff,
          second: .moreStuff
        ).first,
        let myvar2 = myClass.diffFunc(
          first: .someStuff,
          second: .moreStuff
        ).first
      else {
        // do stuff
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 35)
  }

  func testOpenBraceIsGluedToElseKeyword() {
    let input =
      """
      guard let foo = something,
        let bar = somethingElse else
      {
        body()
      }
      """

    let expected =
      """
      guard let foo = something,
        let bar = somethingElse
      else {
        body()
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 60)
  }

  func testContinuationLineBreaking() {
    let input =
      """
      guard let someObject = object as? Int,
        let anotherCastedObject = object as? SomeOtherSlightlyLongerType else {
        return nil
      }
      guard let someObject = object as? SomeLongLineBreakingType,
        let anotherCastedObject = object as? SomeOtherSlightlyLongerType else {
        return nil
      }
      guard let someCastedObject = someFunc(foo, bar, baz, quxxe, far, fab, faz),
        let anotherCastedObject = object as? SomeOtherSlightlyLongerType else {
        return nil
      }
      guard let object1 = fetchingFunc(foo), let object2 = fetchingFunc(bar), let object3 = fetchingFunc(baz) else {
        return nil
      }
      """

    let expected =
      """
      guard let someObject = object as? Int,
        let anotherCastedObject = object
          as? SomeOtherSlightlyLongerType
      else {
        return nil
      }
      guard
        let someObject = object
          as? SomeLongLineBreakingType,
        let anotherCastedObject = object
          as? SomeOtherSlightlyLongerType
      else {
        return nil
      }
      guard
        let someCastedObject = someFunc(
          foo, bar, baz, quxxe, far, fab, faz),
        let anotherCastedObject = object
          as? SomeOtherSlightlyLongerType
      else {
        return nil
      }
      guard let object1 = fetchingFunc(foo),
        let object2 = fetchingFunc(bar),
        let object3 = fetchingFunc(baz)
      else {
        return nil
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 40)
  }

  func testOptionalBindingConditions() {
    let input =
      """
      guard let someObject: Foo = object as? Int else {
        return nil
      }
      guard let someObject: (foo: Foo, bar: SomeVeryLongTypeNameThatBreaks, baz: Baz) = foo(a, b, c, d) else { return nil }
      """

    let expected =
      """
      guard
        let someObject: Foo = object as? Int
      else {
        return nil
      }
      guard
        let someObject:
          (
            foo: Foo,
            bar:
              SomeVeryLongTypeNameThatBreaks,
            baz: Baz
          ) = foo(a, b, c, d)
      else { return nil }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 40)
  }

  func testParenthesizedClauses() {
    let input =
      """
      guard foo && (
          bar < 1 || bar > 1
        ) && baz else {
        // do something
      }
      guard muchLongerFoo && (
          muchLongerBar < 1 || muchLongerBar > 1
        ) && baz else {
        // do something
      }
      guard muchLongerFoo && (
          muchLongerBar < 1 || muchLongerBar > 100000000
        ) && baz else {
        // do something
      }
      guard muchLongerFoo && (
          muchLongerBar < 1 || muchLongerBar > 100000000 || (
            extraTerm1 + extraTerm2 + extraTerm3
          )
        ) && baz else {
        // do something
      }
      """

    let expected =
      """
      guard foo && (bar < 1 || bar > 1) && baz else {
        // do something
      }
      guard
        muchLongerFoo
          && (muchLongerBar < 1 || muchLongerBar > 1)
          && baz
      else {
        // do something
      }
      guard
        muchLongerFoo
          && (muchLongerBar < 1
            || muchLongerBar > 100000000)
          && baz
      else {
        // do something
      }
      guard
        muchLongerFoo
          && (muchLongerBar < 1
            || muchLongerBar > 100000000
            || (extraTerm1 + extraTerm2 + extraTerm3))
          && baz
      else {
        // do something
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 50)
  }

  func testCompoundClauses() {
    let input =
      """
      guard foo &&
          bar < 1 || bar
            > 1,
        let quxxe = 0
      else {
        // do something
      }
      guard
        bar < 1 && (
          baz
            > 1
          ),
        let quxxe = 0
      else {
        // blah
      }
      """

    let expected =
      """
      guard
        foo && bar < 1
          || bar
            > 1,
        let quxxe = 0
      else {
        // do something
      }
      guard
        bar < 1
          && (baz
            > 1),
        let quxxe = 0
      else {
        // blah
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 50)
  }
}
