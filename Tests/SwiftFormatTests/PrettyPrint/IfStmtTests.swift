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

import SwiftFormat
import XCTest

final class IfStmtTests: PrettyPrintTestCase {
  func testIfStatement() {
    let input =
      """
      if var1 > var2 {
        let a = 23
        var b = "abc"
      }

      if var1 > var2 {
        let a = 23
        var b = "abc"
        if var3 {
          var c = 123
        }
      }

      if a123456 > b123456 {
        let a = 23
        var b = "abc"
      }

      if a123456789 > b123456 {
        let a = 23
        var b = "abc"
      }
      """

    let expected =
      """
      if var1 > var2 {
        let a = 23
        var b = "abc"
      }

      if var1 > var2 {
        let a = 23
        var b = "abc"
        if var3 {
          var c = 123
        }
      }

      if a123456 > b123456
      {
        let a = 23
        var b = "abc"
      }

      if a123456789
        > b123456
      {
        let a = 23
        var b = "abc"
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 20)
  }

  func testIfElseStatement_noBreakBeforeElse() {
    let input =
      """
      if var1 < var2 {
        let a = 23
      }
      else if d < e {
        var b = 123
      }
      else {
        var c = 456
      }

      if var1 < var2 {
        let a = 23
      }
      else if var3 < var4 {
        var b = 123
        var c = 456
      }
      """

    let expected =
      """
      if var1 < var2 {
        let a = 23
      } else if d < e {
        var b = 123
      } else {
        var c = 456
      }

      if var1 < var2 {
        let a = 23
      } else if var3 < var4 {
        var b = 123
        var c = 456
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 23)
  }

  func testIfElseStatement_breakBeforeElse() {
    let input =
      """
      if var1 < var2 {
        let a = 23
      } else if d < e {
        var b = 123
      } else {
        var c = 456
      }

      if var1 < var2 {
        let a = 23
      } else if var3 < var4 {
        var b = 123
        var c = 456
      }
      """

    let expected =
      """
      if var1 < var2 {
        let a = 23
      }
      else if d < e {
        var b = 123
      }
      else {
        var c = 456
      }

      if var1 < var2 {
        let a = 23
      }
      else if var3 < var4
      {
        var b = 123
        var c = 456
      }

      """

    var config = Configuration.forTesting
    config.lineBreakBeforeControlFlowKeywords = true
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 20, configuration: config)
  }

  func testIfExpression1() {
    let input =
      """
      func foo() -> Int {
        if var1 < var2 {
          23
        }
        else if d < e {
          24
        }
        else {
          0
        }
      }
      """

    let expected =
      """
      func foo() -> Int {
        if var1 < var2 {
          23
        } else if d < e {
          24
        } else {
          0
        }
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 23)
  }

  func testIfExpression2() {
    let input =
      """
      func foo() -> Int {
        let x = if var1 < var2 {
          23
        }
        else if d < e {
          24
        }
        else {
          0
        }
        return x
      }
      """

    let expected =
      """
      func foo() -> Int {
        let x =
          if var1 < var2 {
            23
          } else if d < e {
            24
          } else {
            0
          }
        return x
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 26)
  }

  func testIfExpression3() {
    let input =
      """
      let x = if a { b } else { c }
      xyzab = if a { b } else { c }
      """
    assertPrettyPrintEqual(input: input, expected: input + "\n", linelength: 80)

    let expected28 =
      """
      let x =
        if a { b } else { c }
      xyzab =
        if a { b } else { c }

      """
    assertPrettyPrintEqual(input: input, expected: expected28, linelength: 28)

    let expected22 =
      """
      let x =
        if a { b } else {
          c
        }
      xyzab =
        if a { b } else {
          c
        }

      """
    assertPrettyPrintEqual(input: input, expected: expected22, linelength: 22)
  }

  func testMatchingPatternConditions() {
    let input =
      """
      if case .foo = bar {
        let a = 123
        var b = "abc"
      }
      if case .reallyLongCaseName = reallyLongVariableName {
        let a = 123
        var b = "abc"
      }
      """

    let expected =
      """
      if case .foo = bar {
        let a = 123
        var b = "abc"
      }
      if case .reallyLongCaseName =
        reallyLongVariableName
      {
        let a = 123
        var b = "abc"
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 30)
  }

  func testIfLetStatements() {
    let input =
      """
      if let SomeReallyLongVar = Some.More.Stuff(), let a = myfunc() {
        // do stuff
      }

      if someCondition
        && someFunctionCall(arguments) {
        // do stuff
      }
      """

    let expected =
      """
      if let SomeReallyLongVar = Some.More
        .Stuff(), let a = myfunc()
      {
        // do stuff
      }

      if someCondition
        && someFunctionCall(arguments)
      {
        // do stuff
      }

      """

    // The line length ends on the last paren of .Stuff()
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 44)
  }

  func testContinuationLineBreakIndentation() {
    let input =
      """
      if let someObject = object as? Int,
        let anotherCastedObject = object as? SomeOtherSlightlyLongerType,
        let thirdObject = object as? Int {
        return nil
      }
      if let someObject = object as? SomeLongLineBreakingType,
        let anotherCastedObject = object as? SomeOtherSlightlyLongerType {
        return nil
      }
      if let someCastedObject = someFunc(foo, bar, baz, quxxe, far, fab, faz),
        let anotherCastedObject = object as? SomeOtherSlightlyLongerType {
        return nil
      }
      if let object1 = fetchingFunc(foo), let object2 = fetchingFunc(bar), let object3 = fetchingFunc(baz) {
        return nil
      }
      """

    let expected =
      """
      if let someObject = object as? Int,
        let anotherCastedObject = object
          as? SomeOtherSlightlyLongerType,
        let thirdObject = object as? Int
      {
        return nil
      }
      if let someObject = object
        as? SomeLongLineBreakingType,
        let anotherCastedObject = object
          as? SomeOtherSlightlyLongerType
      {
        return nil
      }
      if let someCastedObject = someFunc(
        foo, bar, baz, quxxe, far, fab, faz),
        let anotherCastedObject = object
          as? SomeOtherSlightlyLongerType
      {
        return nil
      }
      if let object1 = fetchingFunc(foo),
        let object2 = fetchingFunc(bar),
        let object3 = fetchingFunc(baz)
      {
        return nil
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 50)
  }

  func testHangingOpenBreakIsTreatedLikeContinuation() {
    let input =
      """
      if let foo = someFunction(someArgumentLabel: someValue) {
        // do stuff
      }
      """

    let expected =
      """
      if let foo = someFunction(
        someArgumentLabel: someValue)
      {
        // do stuff
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 50)
  }

  func testConditionExpressionOperatorGrouping() throws {
    let input =
      """
      if someObj is SuperVerboselyNamedType || someObj is AnotherPrettyLongType  || someObjc == "APlainString" || someObj == 4 {
        // do something
      }
      if someVeryLongFirstCondition || aCombination + ofVariousVariables + andOperators - thatBreak * onto % differentLines || anotherPrettyLongCondition || thatBinPacks {
        // do something else
      }
      """

    let expected =
      """
      if someObj is SuperVerboselyNamedType
        || someObj is AnotherPrettyLongType
        || someObjc == "APlainString" || someObj == 4
      {
        // do something
      }
      if someVeryLongFirstCondition
        || aCombination + ofVariousVariables
          + andOperators - thatBreak * onto
          % differentLines
        || anotherPrettyLongCondition || thatBinPacks
      {
        // do something else
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 50)
  }

  func testConditionExpressionOperatorGroupingMixedWithParentheses() throws {
    let input =
      """
      if (someObj is SuperVerboselyNamedType || someObj is AnotherPrettyLongType  || someObjc == "APlainString" || someObj == 4) {
        // do something
      }
      if (someVeryLongFirstCondition || (aCombination + ofVariousVariables + andOperators - thatBreak * onto % differentLines) || anotherPrettyLongCondition || thatBinPacks) {
        // do something else
      }
      """

    let expected =
      """
      if (someObj is SuperVerboselyNamedType
        || someObj is AnotherPrettyLongType
        || someObjc == "APlainString" || someObj == 4)
      {
        // do something
      }
      if (someVeryLongFirstCondition
        || (aCombination + ofVariousVariables
          + andOperators - thatBreak * onto
          % differentLines)
        || anotherPrettyLongCondition || thatBinPacks)
      {
        // do something else
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 50)
  }

  func testOptionalBindingConditions() {
    let input =
      """
      if let someObject: Foo = object as? Int {
        return nil
      }
      if let someObject: (foo: Foo, bar: SomeVeryLongTypeNameThatDefinitelyBreaks, baz: Baz) = foo(a, b, c, d) { return nil }
      """

    let expected =
      """
      if let someObject: Foo = object as? Int
      {
        return nil
      }
      if let someObject:
        (
          foo: Foo,
          bar:
            SomeVeryLongTypeNameThatDefinitelyBreaks,
          baz: Baz
        ) = foo(a, b, c, d)
      {
        return nil
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 40)
  }

  func testParenthesizedClauses() {
    let input =
      """
      if foo && (
          bar < 1 || bar > 1
        ) && baz {
        // do something
      }
      if muchLongerFoo && (
          muchLongerBar < 1 || muchLongerBar > 1
        ) && baz {
        // do something
      }
      if muchLongerFoo && (
          muchLongerBar < 1 || muchLongerBar > 100000000
        ) && baz {
        // do something
      }
      if muchLongerFoo && (
          muchLongerBar < 1 || muchLongerBar > 100000000 || (
            extraTerm1 + extraTerm2 + extraTerm3
          )
        ) && baz {
        // do something
      }
      """

    let expected =
      """
      if foo && (bar < 1 || bar > 1) && baz {
        // do something
      }
      if muchLongerFoo
        && (muchLongerBar < 1 || muchLongerBar > 1)
        && baz
      {
        // do something
      }
      if muchLongerFoo
        && (muchLongerBar < 1
          || muchLongerBar > 100000000)
        && baz
      {
        // do something
      }
      if muchLongerFoo
        && (muchLongerBar < 1
          || muchLongerBar > 100000000
          || (extraTerm1 + extraTerm2 + extraTerm3))
        && baz
      {
        // do something
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 50)
  }

  func testCompoundClauses() {
    let input =
      """
      if foo &&
          bar < 1 || bar
            > 1,
        let quxxe = 0
      {
        // do something
      }
      if bar < 1 && (
        baz
          > 1
        ),
      let quxxe = 0
      {
        // blah
      }
      """

    let expected =
      """
      if foo && bar < 1
        || bar
          > 1,
        let quxxe = 0
      {
        // do something
      }
      if bar < 1
        && (baz
          > 1),
        let quxxe = 0
      {
        // blah
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 50)
  }

  func testLabeledIfStmt() {
    let input =
      """
      someLabel:if foo && bar {
        // do something
      }
      anotherVeryLongLabelThatTakesUpTooManyCharacters: if foo && bar {
        // do something else
      }
      """

    let expected =
      """
      someLabel: if foo && bar {
        // do something
      }
      anotherVeryLongLabelThatTakesUpTooManyCharacters: if foo
        && bar
      {
        // do something else
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 50)
  }

  func testMultipleIfStmts() {
    let input =
      """
      func foo() {
        if foo && bar { baz() } else if bar { baz() } else if foo { baz() } else { blargh() }
        if foo && bar && quxxe { baz() } else if bar { baz() } else if foo { baz() } else if quxxe { baz() } else { blargh() }
        if let foo = getmyfoo(), let bar = getmybar(), foo.baz && bar.baz { foo() } else { bar() }
        if let foo = getmyfoo(), let bar = getmybar(), foo.baz && bar.baz && someOtherCondition { foo() } else { bar() }
        if let foo = getmyfoo(), let bar = getmybar(), foo.baz && bar.baz && someOtherCondition { foo() }
      }
      """

    let expected =
      """
      func foo() {
        if foo && bar { baz() } else if bar { baz() } else if foo { baz() } else { blargh() }
        if foo && bar && quxxe {
          baz()
        } else if bar {
          baz()
        } else if foo {
          baz()
        } else if quxxe {
          baz()
        } else {
          blargh()
        }
        if let foo = getmyfoo(), let bar = getmybar(), foo.baz && bar.baz {
          foo()
        } else {
          bar()
        }
        if let foo = getmyfoo(), let bar = getmybar(),
          foo.baz && bar.baz && someOtherCondition
        {
          foo()
        } else {
          bar()
        }
        if let foo = getmyfoo(), let bar = getmybar(),
          foo.baz && bar.baz && someOtherCondition
        {
          foo()
        }
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 87)
  }
}
