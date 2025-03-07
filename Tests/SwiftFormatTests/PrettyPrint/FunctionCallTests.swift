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

final class FunctionCallTests: PrettyPrintTestCase {
  func testBasicFunctionCalls_noPackArguments() {
    let input =
      """
      let a = myFunc()
      let a = myFunc(var1: 123, var2: "abc")
      let a = myFunc(var1: 123, var2: "abc", var3: Bool, var4: (1, 2, 3))
      let a = myFunc(var1, var2, var3)
      let a = myFunc(var1, var2, var3, var4, var5, var6)
      let a = myFunc(var1, var2, var3, var4, var5, var6, var7, x)
      let a = myFunc(var1: 123, var2: someFun(var1: "abc", var2: 123, var3: Bool, var4: 1.23))
      """

    let expected =
      """
      let a = myFunc()
      let a = myFunc(var1: 123, var2: "abc")
      let a = myFunc(
        var1: 123,
        var2: "abc",
        var3: Bool,
        var4: (1, 2, 3)
      )
      let a = myFunc(var1, var2, var3)
      let a = myFunc(
        var1,
        var2,
        var3,
        var4,
        var5,
        var6
      )
      let a = myFunc(
        var1,
        var2,
        var3,
        var4,
        var5,
        var6,
        var7,
        x
      )
      let a = myFunc(
        var1: 123,
        var2: someFun(
          var1: "abc",
          var2: 123,
          var3: Bool,
          var4: 1.23
        )
      )

      """

    var config = Configuration.forTesting
    config.lineBreakBeforeEachArgument = true
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 45, configuration: config)
  }

  func testBasicFunctionCalls_packArguments() {
    let input =
      """
      let a = myFunc()
      let a = myFunc(var1: 123, var2: "abc")
      let a = myFunc(var1: 123, var2: "abc", var3: Bool, var4: (1, 2, 3))
      let a = myFunc(var1, var2, var3)
      let a = myFunc(var1, var2, var3, var4, var5, var6)
      let a = myFunc(var1, var2, var3, var4, var5, var6, var7, x)
      let a = myFunc(var1: 123, var2: someFun(var1: "abc", var2: 123, var3: Bool, var4: 1.23))
      """

    let expected =
      """
      let a = myFunc()
      let a = myFunc(var1: 123, var2: "abc")
      let a = myFunc(
        var1: 123, var2: "abc", var3: Bool,
        var4: (1, 2, 3))
      let a = myFunc(var1, var2, var3)
      let a = myFunc(
        var1, var2, var3, var4, var5, var6)
      let a = myFunc(
        var1, var2, var3, var4, var5, var6, var7, x
      )
      let a = myFunc(
        var1: 123,
        var2: someFun(
          var1: "abc", var2: 123, var3: Bool,
          var4: 1.23))

      """

    var config = Configuration.forTesting
    config.lineBreakBeforeEachArgument = false
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 45, configuration: config)
  }

  func testDiscretionaryLineBreakBeforeClosingParenthesis() {
    let input =
      """
      let a = myFunc(
        var1: 123,
        var2: "abc"
      )
      """
    assertPrettyPrintEqual(input: input, expected: input + "\n", linelength: 45)
  }

  func testDiscretionaryLineBreaksAreSelfCorrecting() {
    // A discretionary line break should never permit a violation of the rule that says,
    // effectively, "if a closing delimiter does not fit on the same line as its matching open
    // delimiter, then the open delimiter is the last token on that line" (which is implemented in
    // Oppen using consistent breaking groups). The line break we insert, if working correctly,
    // should force the entire group to be moved down as we want.
    let input =
      """
      let a = myFunc(var1: 123, var2: "abc"
      )
      """

    let expected =
      """
      let a = myFunc(
        var1: 123, var2: "abc"
      )

      """
    var config = Configuration.forTesting
    config.lineBreakBeforeEachArgument = false
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 45, configuration: config)
  }

  func testArgumentStartsWithOpenDelimiter() {
    let input =
      """
      myFunc(someArray: [
      ])
      myFunc(someArray: [1000, 2000, 3000, 4000, 5000, 6000, 7000, 8000])
      myFunc(someDictionary: [
      :])
      myFunc(someDictionary: ["foo": "bar", "baz": "quux", "gli": "glop"])
      myFunc(someClosure: {
      })
      myFunc(someClosure: { (a, b, c) in
      })
      myFunc(someClosure: { foo, bar in baz(1000, 2000, 3000, 4000, 5000) })
      myFunc(someArray: [1000, 2000, 3000, 4000, 5000, 6000, 7000, 8000]) { foo in bar() }
      myFunc(someArray: [1000, 2000, 3000, 4000, 5000, 6000, 7000, 8000]) { foo in someMuchLongerLineBreakingBarFunction() }
      """

    let expected =
      """
      myFunc(someArray: [])
      myFunc(someArray: [
        1000, 2000, 3000, 4000, 5000, 6000, 7000,
        8000,
      ])
      myFunc(someDictionary: [:])
      myFunc(someDictionary: [
        "foo": "bar", "baz": "quux", "gli": "glop",
      ])
      myFunc(someClosure: {
      })
      myFunc(someClosure: { (a, b, c) in
      })
      myFunc(someClosure: { foo, bar in
        baz(1000, 2000, 3000, 4000, 5000)
      })
      myFunc(someArray: [
        1000, 2000, 3000, 4000, 5000, 6000, 7000,
        8000,
      ]) { foo in bar() }
      myFunc(someArray: [
        1000, 2000, 3000, 4000, 5000, 6000, 7000,
        8000,
      ]) { foo in
        someMuchLongerLineBreakingBarFunction()
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 45)
  }

  func testSingleUnlabeledArgumentWithDelimiters() {
    let input =
      """
      myFunc([1000, 2000, 3000, 4000, 5000, 6000, 7000, 8000])
      myFunc(["foo": "bar", "baz": "quux", "glip": "glop"])
      myFunc({ foo, bar in baz(1000, 2000, 3000, 4000, 5000) })
      myFunc([1000, 2000, 3000, 4000, 5000, 6000, 7000, 8000]) { foo in bar() }
      myFunc([1000, 2000, 3000, 4000, 5000, 6000, 7000, 8000]) { foo in someMuchLongerLineBreakingBarFunction() }
      """

    let expected =
      """
      myFunc([
        1000, 2000, 3000, 4000, 5000, 6000, 7000,
        8000,
      ])
      myFunc([
        "foo": "bar", "baz": "quux",
        "glip": "glop",
      ])
      myFunc({ foo, bar in
        baz(1000, 2000, 3000, 4000, 5000)
      })
      myFunc([
        1000, 2000, 3000, 4000, 5000, 6000, 7000,
        8000,
      ]) { foo in bar() }
      myFunc([
        1000, 2000, 3000, 4000, 5000, 6000, 7000,
        8000,
      ]) { foo in
        someMuchLongerLineBreakingBarFunction()
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 45)
  }

  func testNestedFunctionCallExprSequences() {
    let input =
      """
      let result = firstObj.someOptionalReturningFunc(foo: arg) ?? (someOtherObj as SomeUsefulType).someGetterFunc()
      """

    let expected =
      """
      let result =
        firstObj.someOptionalReturningFunc(foo: arg)
        ?? (someOtherObj as SomeUsefulType).someGetterFunc()

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 60)
  }

  func testDiscretionaryLineBreakAfterColon() {
    let input =
      """
      myFunc(
        a:
          foo,
        b:
          bar + baz + qux,
        c: Very.Deeply.Nested.Member,
        d:
          Very.Deeply.Nested.Member
      )
      """

    let expected =
      """
      myFunc(
        a:
          foo,
        b:
          bar + baz + qux,
        c: Very.Deeply
          .Nested.Member,
        d:
          Very.Deeply
          .Nested.Member
      )

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 20)
  }

  func testDiscretionaryLineBreakBeforeTrailingClosure() {
    let input =
      """
      foo(a, b, c)
      {
        blah()
      }
      foo(
        a, b, c
      )
      {
        blah()
      }
      foo(arg1, arg2, arg3, arg4, arg5, arg6, arg7)
      {
        blah()
      }
      foo(ab, arg1, arg2) {
        blah()
      }
      """

    let expected =
      """
      foo(a, b, c) {
        blah()
      }
      foo(
        a, b, c
      ) {
        blah()
      }
      foo(
        arg1, arg2, arg3,
        arg4, arg5, arg6,
        arg7
      ) {
        blah()
      }
      foo(ab, arg1, arg2)
      {
        blah()
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 20)
  }

  func testGroupsTrailingComma() {
    let input =
      """
      foo(
        image: useLongName ? image(named: .longNameImage) : image(named: .veryLongNameImageZ),
        bar: bar)
      """

    let expected =
      """
      foo(
        image: useLongName
          ? image(named: .longNameImage)
          : image(named: .veryLongNameImageZ),
        bar: bar)

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 70)
  }

  func testMultipleTrailingClosures() {
    let input =
      """
      a = f { b } c: { d }
      let a = f { b } c: { d }
      let a = foo { b in b } c: { d in d }
      let a = foo { abcdefg in b } c: { d in d }
      """

    let expected =
      """
      a = f {
        b
      } c: {
        d
      }
      let a = f {
        b
      } c: {
        d
      }
      let a = foo { b in
        b
      } c: { d in
        d
      }
      let a = foo {
        abcdefg in
        b
      } c: { d in
        d
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 23)
  }
}
