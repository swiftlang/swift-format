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

final class MacroDeclTests: PrettyPrintTestCase {
  func testBasicMacroDeclarations_noPackArguments() {
    let input =
      """
      macro myFun(var1: Int, var2: Double) = #externalMacro(module: "Foo", type: "Bar")
      macro reallyLongName(var1: Int, var2: Double, var3: Bool) = #externalMacro(module: "Foo", type: "Bar")
      macro myFun() = #externalMacro(module: "Foo", type: "Bar")
      """

    let expected =
      """
      macro myFun(var1: Int, var2: Double) =
        #externalMacro(module: "Foo", type: "Bar")
      macro reallyLongName(
        var1: Int,
        var2: Double,
        var3: Bool
      ) = #externalMacro(module: "Foo", type: "Bar")
      macro myFun() = #externalMacro(module: "Foo", type: "Bar")

      """

    var config = Configuration.forTesting
    config.lineBreakBeforeEachArgument = true
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 58, configuration: config)
  }

  func testBasicMacroDeclarations_packArguments() {
    let input =
      """
      macro myFun(var1: Int, var2: Double) = #externalMacro(module: "Foo", type: "Bar")
      macro reallyLongName(var1: Int, var2: Double, var3: Bool) = #externalMacro(module: "Foo", type: "Bar")
      macro myFun() = #externalMacro(module: "Foo", type: "Bar")
      """

    let expected =
      """
      macro myFun(var1: Int, var2: Double) =
        #externalMacro(module: "Foo", type: "Bar")
      macro reallyLongName(
        var1: Int, var2: Double, var3: Bool
      ) = #externalMacro(module: "Foo", type: "Bar")
      macro myFun() = #externalMacro(module: "Foo", type: "Bar")

      """

    var config = Configuration.forTesting
    config.lineBreakBeforeEachArgument = false
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 58, configuration: config)
  }

  func testMacroDeclReturns() {
    let input =
      """
      macro myFun(var1: Int, var2: Double) -> Double = #externalMacro(module: "Foo", type: "Bar")
      macro reallyLongName(var1: Int, var2: Double, var3: Bool) -> Double = #externalMacro(module: "Foo", type: "Bar")
      macro reallyReallyLongName(var1: Int, var2: Double, var3: Bool) -> Double = #externalMacro(module: "Foo", type: "Bar")
      macro tupleFunc() -> (one: Int, two: Double, three: Bool, four: String) = #externalMacro(module: "Foo", type: "Bar")
      macro memberTypeReallyReallyLongNameFunc() -> Type.InnerMember = #externalMacro(module: "Foo", type: "Bar")
      macro tupleMembersReallyLongNameFunc() -> (Type.Inner, Type2.Inner2) = #externalMacro(module: "Foo", type: "Bar")
      """

    let expected =
      """
      macro myFun(var1: Int, var2: Double) -> Double =
        #externalMacro(module: "Foo", type: "Bar")
      macro reallyLongName(var1: Int, var2: Double, var3: Bool)
        -> Double = #externalMacro(module: "Foo", type: "Bar")
      macro reallyReallyLongName(
        var1: Int, var2: Double, var3: Bool
      ) -> Double = #externalMacro(module: "Foo", type: "Bar")
      macro tupleFunc() -> (
        one: Int, two: Double, three: Bool, four: String
      ) = #externalMacro(module: "Foo", type: "Bar")
      macro memberTypeReallyReallyLongNameFunc()
        -> Type.InnerMember =
        #externalMacro(module: "Foo", type: "Bar")
      macro tupleMembersReallyLongNameFunc() -> (
        Type.Inner, Type2.Inner2
      ) = #externalMacro(module: "Foo", type: "Bar")

      """

    var config = Configuration.forTesting
    config.lineBreakBeforeEachArgument = false
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 58, configuration: config)
  }

  func testMacroGenericParameters_noPackArguments() {
    let input =
      """
      macro myFun<S, T>(var1: S, var2: T) = #externalMacro(module: "Foo", type: "Bar")
      macro myFun<S: T & U>(var1: S) = #externalMacro(module: "Foo", type: "Bar")
      macro longerNameFun<ReallyLongTypeName: Conform, TypeName>(var1: ReallyLongTypeName, var2: TypeName) = #externalMacro(module: "Foo", type: "Bar")
      """

    let expected =
      """
      macro myFun<S, T>(var1: S, var2: T) =
        #externalMacro(module: "Foo", type: "Bar")
      macro myFun<S: T & U>(var1: S) =
        #externalMacro(module: "Foo", type: "Bar")
      macro longerNameFun<
        ReallyLongTypeName: Conform,
        TypeName
      >(
        var1: ReallyLongTypeName,
        var2: TypeName
      ) =
        #externalMacro(module: "Foo", type: "Bar")

      """

    var config = Configuration.forTesting
    config.lineBreakBeforeEachArgument = true
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 44, configuration: config)
  }

  func testMacroGenericParameters_packArguments() {
    let input =
      """
      macro myFun<S, T>(var1: S, var2: T) = #externalMacro(module: "Foo", type: "Bar")
      macro myFun<S: T & U>(var1: S) = #externalMacro(module: "Foo", type: "Bar")
      macro longerNameFun<ReallyLongTypeName: Conform, TypeName>(var1: ReallyLongTypeName, var2: TypeName) = #externalMacro(module: "Foo", type: "Bar")
      """

    let expected =
      """
      macro myFun<S, T>(var1: S, var2: T) =
        #externalMacro(module: "Foo", type: "Bar")
      macro myFun<S: T & U>(var1: S) =
        #externalMacro(module: "Foo", type: "Bar")
      macro longerNameFun<
        ReallyLongTypeName: Conform, TypeName
      >(
        var1: ReallyLongTypeName, var2: TypeName
      ) =
        #externalMacro(module: "Foo", type: "Bar")

      """

    var config = Configuration.forTesting
    config.lineBreakBeforeEachArgument = false
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 44, configuration: config)
  }

  func testMacroWhereClause() {
    let input =
      """
      macro index<Elements: Collection, Element>(
        of element: Element, in collection: Elements
      ) -> Elements.Index? = #externalMacro(module: "Foo", type: "Bar") where Elements.Element == Element

      macro index<Elements: Collection, Element>(
        of element: Element,
        in collection: Elements
      ) -> Elements.Index? = #externalMacro(module: "Foo", type: "Bar") where Elements.Element == Element, Element: Equatable

      macro index<Elements: Collection, Element>(
        of element: Element,
        in collection: Elements
      ) -> Elements.Index? = #externalMacro(module: "Foo", type: "Bar") where Elements.Element == Element, Element: Equatable, Element: ReallyLongProtocolName
      """

    let expected =
      """
      macro index<Elements: Collection, Element>(
        of element: Element, in collection: Elements
      ) -> Elements.Index? =
        #externalMacro(module: "Foo", type: "Bar")
      where Elements.Element == Element

      macro index<Elements: Collection, Element>(
        of element: Element,
        in collection: Elements
      ) -> Elements.Index? =
        #externalMacro(module: "Foo", type: "Bar")
      where
        Elements.Element == Element, Element: Equatable

      macro index<Elements: Collection, Element>(
        of element: Element,
        in collection: Elements
      ) -> Elements.Index? =
        #externalMacro(module: "Foo", type: "Bar")
      where
        Elements.Element == Element, Element: Equatable,
        Element: ReallyLongProtocolName

      """

    var config = Configuration.forTesting
    config.lineBreakBeforeEachArgument = false
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 51, configuration: config)
  }

  func testMacroWhereClause_lineBreakBeforeEachGenericRequirement() {
    let input =
      """
      public macro index<Elements: Collection, Element>(
        of element: Element, in collection: Elements
      ) -> Elements.Index? = #externalMacro(module: "Foo", type: "Bar") where Elements.Element == Element

      public macro index<Elements: Collection, Element>(
        of element: Element,
        in collection: Elements
      ) -> Elements.Index? = #externalMacro(module: "Foo", type: "Bar") where Elements.Element == Element, Element: Equatable

      public macro index<Elements: Collection, Element>(
        of element: Element,
        in collection: Elements
      ) -> Elements.Index? = #externalMacro(module: "Foo", type: "Bar") where Elements.Element == Element, Element: Equatable, Element: ReallyLongProtocolName
      """

    let expected =
      """
      public macro index<Elements: Collection, Element>(
        of element: Element, in collection: Elements
      ) -> Elements.Index? =
        #externalMacro(module: "Foo", type: "Bar")
      where Elements.Element == Element

      public macro index<Elements: Collection, Element>(
        of element: Element,
        in collection: Elements
      ) -> Elements.Index? =
        #externalMacro(module: "Foo", type: "Bar")
      where
        Elements.Element == Element,
        Element: Equatable

      public macro index<Elements: Collection, Element>(
        of element: Element,
        in collection: Elements
      ) -> Elements.Index? =
        #externalMacro(module: "Foo", type: "Bar")
      where
        Elements.Element == Element,
        Element: Equatable,
        Element: ReallyLongProtocolName

      """

    var config = Configuration.forTesting
    config.lineBreakBeforeEachArgument = false
    config.lineBreakBeforeEachGenericRequirement = true
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 50, configuration: config)
  }

  func testMacroAttributes() {
    let input =
      """
      @attached(accessor) public macro MyFun() = #externalMacro(module: "Foo", type: "Bar")
      @attached(accessor) @attached(memberAttribute) public macro MyFun() = #externalMacro(module: "Foo", type: "Bar")
      @attached(accessor) @attached(member, names: named(_storage)) public macro MyFun() = #externalMacro(module: "Foo", type: "Bar")
      @attached(accessor)
      @attached(member, names: named(_storage))
      public macro MyFun() = #externalMacro(module: "Foo", type: "Bar")
      """

    let expected =
      """
      @attached(accessor) public macro MyFun() =
        #externalMacro(module: "Foo", type: "Bar")
      @attached(accessor) @attached(memberAttribute) public macro MyFun() =
        #externalMacro(module: "Foo", type: "Bar")
      @attached(accessor) @attached(member, names: named(_storage))
      public macro MyFun() = #externalMacro(module: "Foo", type: "Bar")
      @attached(accessor)
      @attached(member, names: named(_storage))
      public macro MyFun() = #externalMacro(module: "Foo", type: "Bar")

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 69)
  }

  func testMacroDeclWithoutDefinition() {
    let input =
      """
      macro myFun()
      macro myFun(arg1: Int)
      macro myFun() -> Int
      macro myFun<T>(arg1: Int)
      macro myFun<T>(arg1: Int) where T: S
      """

    let expected =
      """
      macro myFun()
      macro myFun(arg1: Int)
      macro myFun() -> Int
      macro myFun<T>(arg1: Int)
      macro myFun<T>(arg1: Int) where T: S

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 50)
  }

  func testBreaksBeforeOrInsideOutput() {
    let input =
      """
      macro name<R>(_ x: Int) -> R
      """

    let expected =
      """
      macro name<R>(_ x: Int)
        -> R

      """
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 23)
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 24)
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 27)
  }

  func testBreaksBeforeOrInsideOutput_prioritizingKeepingOutputTogether() {
    let input =
      """
      macro name<R>(_ x: Int) -> R
      """

    let expected =
      """
      macro name<R>(
        _ x: Int
      ) -> R

      """
    var config = Configuration.forTesting
    config.prioritizeKeepingFunctionOutputTogether = true
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 23, configuration: config)
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 24, configuration: config)
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 27, configuration: config)
  }

  func testBreaksBeforeOrInsideOutputWithAttributes() {
    let input =
      """
      @attached(member) @attached(memberAttribute)
      macro name<R>(_ x: Int) -> R
      """

    let expected =
      """
      @attached(member)
      @attached(memberAttribute)
      macro name<R>(_ x: Int)
        -> R

      """
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 26)
  }

  func testBreaksBeforeOrInsideOutputWithAttributes_prioritizingKeepingOutputTogether() {
    let input =
      """
      @attached(member) @attached(memberAttribute)
      macro name<R>(_ x: Int) -> R
      """

    let expected =
      """
      @attached(member)
      @attached(memberAttribute)
      macro name<R>(
        _ x: Int
      ) -> R

      """
    var config = Configuration.forTesting
    config.prioritizeKeepingFunctionOutputTogether = true
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 26, configuration: config)
  }

  func testDoesNotBreakInsideEmptyParens() {
    // If the macro name is so long that the parentheses of a no-argument parameter list would
    // be pushed past the margin, don't break inside them.
    let input =
      """
      macro fooBarBaz()

      """

    let expected =
      """
      macro
        fooBarBaz()

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 16)
  }
}
