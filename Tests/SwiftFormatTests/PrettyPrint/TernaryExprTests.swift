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

final class TernaryExprTests: PrettyPrintTestCase {
  func testTernaryExprs() {
    let input =
      """
      let x = a ? b : c
      let y = a ?b:c
      let z = a ? b: c
      let reallyLongName = a ? longTruePart : longFalsePart
      let reallyLongName = reallyLongCondition ? reallyLongTruePart : reallyLongFalsePart
      let reallyLongName = reallyLongCondition ? reallyReallyReallyLongTruePart : reallyLongFalsePart
      let reallyLongName = someCondition ? firstFunc(foo: arg) : secondFunc(bar: arg)
      """

    let expected =
      """
      let x = a ? b : c
      let y = a ? b : c
      let z = a ? b : c
      let reallyLongName =
        a ? longTruePart : longFalsePart
      let reallyLongName =
        reallyLongCondition
        ? reallyLongTruePart : reallyLongFalsePart
      let reallyLongName =
        reallyLongCondition
        ? reallyReallyReallyLongTruePart
        : reallyLongFalsePart
      let reallyLongName =
        someCondition
        ? firstFunc(foo: arg)
        : secondFunc(bar: arg)

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 45)
  }

  func testTernaryExprsWithMultiplePartChoices() {
    let input =
      """
      let someLocalizedText =
        shouldUseTheFirstOption ? stringFunc(name: "Name1", comment: "short comment") :
        stringFunc(name: "Name2", comment: "Some very, extremely long comment", details: "Another comment")
      """
    let expected =
      """
      let someLocalizedText =
        shouldUseTheFirstOption
        ? stringFunc(name: "Name1", comment: "short comment")
        : stringFunc(
          name: "Name2", comment: "Some very, extremely long comment",
          details: "Another comment")

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 80)
  }

  func testTernaryWithWrappingExpressions() {
    let input =
      """
      foo = firstTerm + secondTerm + thirdTerm ? firstTerm + secondTerm + thirdTerm : firstTerm + secondTerm + thirdTerm
      let foo = firstTerm + secondTerm + thirdTerm ? firstTerm + secondTerm + thirdTerm : firstTerm + secondTerm + thirdTerm
      foo = firstTerm || secondTerm && thirdTerm ? firstTerm + secondTerm + thirdTerm : firstTerm + secondTerm + thirdTerm
      let foo = firstTerm || secondTerm && thirdTerm ? firstTerm + secondTerm + thirdTerm : firstTerm + secondTerm + thirdTerm
      """

    let expected =
      """
      foo =
        firstTerm
          + secondTerm
          + thirdTerm
        ? firstTerm
          + secondTerm
          + thirdTerm
        : firstTerm
          + secondTerm
          + thirdTerm
      let foo =
        firstTerm
          + secondTerm
          + thirdTerm
        ? firstTerm
          + secondTerm
          + thirdTerm
        : firstTerm
          + secondTerm
          + thirdTerm
      foo =
        firstTerm
          || secondTerm
            && thirdTerm
        ? firstTerm
          + secondTerm
          + thirdTerm
        : firstTerm
          + secondTerm
          + thirdTerm
      let foo =
        firstTerm
          || secondTerm
            && thirdTerm
        ? firstTerm
          + secondTerm
          + thirdTerm
        : firstTerm
          + secondTerm
          + thirdTerm

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 15)
  }

  func testNestedTernaries() {
    let input =
      """
      a = b ? c : d ? e : f
      let a = b ? c : d ? e : f
      a = b ? c0 + c1 : d ? e : f
      let a = b ? c0 + c1 : d ? e : f
      a = b ? c0 + c1 + c2 + c3 : d ? e : f
      let a = b ? c0 + c1 + c2 + c3 : d ? e : f
      foo = testA ? testB ? testC : testD : testE ? testF : testG
      let foo = testA ? testB ? testC : testD : testE ? testF : testG
      """

    let expected =
      """
      a =
        b
        ? c
        : d ? e : f
      let a =
        b
        ? c
        : d ? e : f
      a =
        b
        ? c0 + c1
        : d ? e : f
      let a =
        b
        ? c0 + c1
        : d ? e : f
      a =
        b
        ? c0 + c1
          + c2 + c3
        : d ? e : f
      let a =
        b
        ? c0 + c1
          + c2 + c3
        : d ? e : f
      foo =
        testA
        ? testB
          ? testC
          : testD
        : testE
          ? testF
          : testG
      let foo =
        testA
        ? testB
          ? testC
          : testD
        : testE
          ? testF
          : testG

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 15)
  }

  func testExpressionStartsWithTernary() {
    // When the ternary itself doesn't already start on a continuation line, we don't have a way
    // to indent the continuation of the condition differently from the first and second choices,
    // because we don't want to double-indent the condition's continuation lines, and we don't want
    // to keep put the choices at the same indentation level as the condition (because that would
    // be the start of the statement). Neither of these choices is really ideal, unfortunately.
    let input =
      """
      condition ? callSomething() : callSomethingElse()
      condition && otherCondition ? callSomething() : callSomethingElse()
      (condition && otherCondition) ? callSomething() : callSomethingElse()
      """

    let expected =
      """
      condition
        ? callSomething()
        : callSomethingElse()
      condition
        && otherCondition
        ? callSomething()
        : callSomethingElse()
      (condition
        && otherCondition)
        ? callSomething()
        : callSomethingElse()

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 25)
  }

  func testParenthesizedTernary() {
    let input =
      """
      let a = (
          foo ?
            bar : baz
        )
      a = (
          foo ?
            bar : baz
        )
      b = foo ? (
        bar
        ) : (
        baz
        )
      c = foo ?
        (
          foo2 ? nestedBar : nestedBaz
        ) : (baz)
      """

    let expected =
      """
      let a = (foo ? bar : baz)
      a = (foo ? bar : baz)
      b = foo ? (bar) : (baz)
      c = foo ? (foo2 ? nestedBar : nestedBaz) : (baz)

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 50)
  }
}
