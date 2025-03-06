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

final class DeclNameArgumentTests: PrettyPrintTestCase {
  func testSelectors_noPackArguments() {
    let input =
      """
      let selector = #selector(FooClass.method(firstArg:secondArg:thirdArg:fourthArg:fifthArg:))
      let selector = #selector(FooClass.method(firstArg:secondArg:))
      let selector = #selector(FooClass.VeryDeeply.NestedInner.Member.foo(firstArg:secondArg:))
      let selector = #selector(FooClass.VeryDeeply.NestedInner.Member.foo(firstArg:secondArg:thirdArg:fourthArg:fifthArg:))
      """

    let expected =
      """
      let selector = #selector(
        FooClass.method(
          firstArg:
          secondArg:
          thirdArg:
          fourthArg:
          fifthArg:
        )
      )
      let selector = #selector(
        FooClass.method(firstArg:secondArg:)
      )
      let selector = #selector(
        FooClass.VeryDeeply.NestedInner.Member
          .foo(firstArg:secondArg:)
      )
      let selector = #selector(
        FooClass.VeryDeeply.NestedInner.Member
          .foo(
            firstArg:
            secondArg:
            thirdArg:
            fourthArg:
            fifthArg:
          )
      )

      """

    var config = Configuration.forTesting
    config.lineBreakBeforeEachArgument = true
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 40, configuration: config)
  }

  func testSelectors_packArguments() {
    let input =
      """
      let selector = #selector(FooClass.method(firstArg:secondArg:thirdArg:fourthArg:fifthArg:))
      let selector = #selector(FooClass.method(firstArg:secondArg:))
      let selector = #selector(FooClass.VeryDeeply.NestedInner.Member.foo(firstArg:secondArg:))
      let selector = #selector(FooClass.VeryDeeply.NestedInner.Member.foo(firstArg:secondArg:thirdArg:fourthArg:fifthArg:))
      """

    let expected =
      """
      let selector = #selector(
        FooClass.method(
          firstArg:secondArg:thirdArg:
          fourthArg:fifthArg:))
      let selector = #selector(
        FooClass.method(firstArg:secondArg:))
      let selector = #selector(
        FooClass.VeryDeeply.NestedInner.Member
          .foo(firstArg:secondArg:))
      let selector = #selector(
        FooClass.VeryDeeply.NestedInner.Member
          .foo(
            firstArg:secondArg:thirdArg:
            fourthArg:fifthArg:))

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 40)
  }

  func testFunctions_noPackArguments() {
    let input =
      """
      someArray.map(foo(firstArg:secondArg:))
      someArray.map(foo(firstArg:secondArg:thirdArg:))
      someArray.map(globalFuncFoo(firstArg:secondArg:thirdArg:fourthArg:fifthArg:))
      someArray.map(obj.DeeplyNested.Inner.MemberWith.funcFoo(firstArg:secondArg:thirdArg:fourthArg:fifthArg:))
      """

    let expected =
      """
      someArray.map(foo(firstArg:secondArg:))
      someArray.map(
        foo(firstArg:secondArg:thirdArg:)
      )
      someArray.map(
        globalFuncFoo(
          firstArg:
          secondArg:
          thirdArg:
          fourthArg:
          fifthArg:
        )
      )
      someArray.map(
        obj.DeeplyNested.Inner.MemberWith
          .funcFoo(
            firstArg:
            secondArg:
            thirdArg:
            fourthArg:
            fifthArg:
          )
      )

      """

    var config = Configuration.forTesting
    config.lineBreakBeforeEachArgument = true
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 40, configuration: config)
  }

  func testFunctions_packArguments() {
    let input =
      """
      someArray.map(foo(firstArg:secondArg:))
      someArray.map(foo(firstArg:secondArg:thirdArg:))
      someArray.map(globalFuncFoo(firstArg:secondArg:thirdArg:fourthArg:fifthArg:))
      someArray.map(obj.DeeplyNested.Inner.MemberWith.funcFoo(firstArg:secondArg:thirdArg:fourthArg:fifthArg:))
      """

    let expected =
      """
      someArray.map(foo(firstArg:secondArg:))
      someArray.map(
        foo(firstArg:secondArg:thirdArg:))
      someArray.map(
        globalFuncFoo(
          firstArg:secondArg:thirdArg:
          fourthArg:fifthArg:))
      someArray.map(
        obj.DeeplyNested.Inner.MemberWith
          .funcFoo(
            firstArg:secondArg:thirdArg:
            fourthArg:fifthArg:))

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 40)
  }
}
