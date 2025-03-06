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

final class InitializerDeclTests: PrettyPrintTestCase {
  func testBasicInitializerDeclarations_noPackArguments() {
    let input =
      """
      struct Struct {
        init(var1: Int, var2: Double) {
            print("Hello World")
            let a = 23
        }
        init(reallyLongLabelVar1: Int, var2: Double, var3: Bool) {
            print("Hello World")
            let a = 23
        }
        init() { let a = 23 }
        init() { let a = "AAAA BBBB CCCC DDDD EEEE FFFF" }
      }
      """

    let expected =
      """
      struct Struct {
        init(var1: Int, var2: Double) {
          print("Hello World")
          let a = 23
        }
        init(
          reallyLongLabelVar1: Int,
          var2: Double,
          var3: Bool
        ) {
          print("Hello World")
          let a = 23
        }
        init() { let a = 23 }
        init() {
          let a = "AAAA BBBB CCCC DDDD EEEE FFFF"
        }
      }

      """

    var config = Configuration.forTesting
    config.lineBreakBeforeEachArgument = true
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 50, configuration: config)
  }

  func testBasicInitializerDeclarations_packArguments() {
    let input =
      """
      struct Struct {
        init(var1: Int, var2: Double) {
            print("Hello World")
            let a = 23
        }
        init(reallyLongLabelVar1: Int, var2: Double, var3: Bool) {
            print("Hello World")
            let a = 23
        }
        init() { let a = 23 }
        init() { let a = "AAAA BBBB CCCC DDDD EEEE FFFF" }
      }
      """

    let expected =
      """
      struct Struct {
        init(var1: Int, var2: Double) {
          print("Hello World")
          let a = 23
        }
        init(
          reallyLongLabelVar1: Int, var2: Double,
          var3: Bool
        ) {
          print("Hello World")
          let a = 23
        }
        init() { let a = 23 }
        init() {
          let a = "AAAA BBBB CCCC DDDD EEEE FFFF"
        }
      }

      """

    var config = Configuration.forTesting
    config.lineBreakBeforeEachArgument = false
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 50, configuration: config)
  }

  func testInitializerOptionality() {
    let input =
      """
      struct Struct {
        init? (var1: Int, var2: Double) {
            print("Hello World")
            let a = 23
        }
        init! (reallyLongLabelVar1: Int, var2: Double, var3: Bool) {
            print("Hello World")
            let a = 23
        }
        init?() { let a = 23 }
        init!() { let a = "AAAA BBBB CCCC DDDD EEEE FFFF" }
      }
      """

    let expected =
      """
      struct Struct {
        init?(var1: Int, var2: Double) {
          print("Hello World")
          let a = 23
        }
        init!(
          reallyLongLabelVar1: Int, var2: Double,
          var3: Bool
        ) {
          print("Hello World")
          let a = 23
        }
        init?() { let a = 23 }
        init!() {
          let a = "AAAA BBBB CCCC DDDD EEEE FFFF"
        }
      }

      """

    var config = Configuration.forTesting
    config.lineBreakBeforeEachArgument = false
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 50, configuration: config)
  }

  func testInitializerDeclThrows() {
    let input =
      """
      struct Struct {
        init(var1: Int, var2: Double) throws {
          print("Hello World")
        }
        init(reallyLongLabelVar1: Int, var2: Double, var3: Bool) throws {
          print("Hello World")
        }
      }
      """

    let expected =
      """
      struct Struct {
        init(var1: Int, var2: Double) throws {
          print("Hello World")
        }
        init(
          reallyLongLabelVar1: Int, var2: Double,
          var3: Bool
        ) throws {
          print("Hello World")
        }
      }

      """

    var config = Configuration.forTesting
    config.lineBreakBeforeEachArgument = false
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 50, configuration: config)
  }

  func testInitializerGenericParameters() {
    let input =
      """
      struct Struct {
        init<S, T>(var1: S, var2: T) {
          let a = 123
          print("Hello World")
        }
        init<ReallyLongTypeName: Conform, TypeName>(var1: ReallyLongTypeName, var2: TypeName) {
          let a = 123
          let b = 456
        }
      }
      """

    let expected =
      """
      struct Struct {
        init<S, T>(var1: S, var2: T) {
          let a = 123
          print("Hello World")
        }
        init<
          ReallyLongTypeName: Conform,
          TypeName
        >(
          var1: ReallyLongTypeName,
          var2: TypeName
        ) {
          let a = 123
          let b = 456
        }
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 40)
  }

  func testInitializerWhereClause() {
    let input =
      """
      struct Struct {
        public init<Elements: Collection, Element>(element: Element, in collection: Elements) where Elements.Element == Element {
          let a = 123
          let b = "abc"
        }
        public init<Elements: Collection, Element>(element: Element, in collection: Elements) where Elements.Element == Element, Element: P, Element: Equatable {
          let a = 123
          let b = "abc"
        }
      }
      """

    let expected =
      """
      struct Struct {
        public init<Elements: Collection, Element>(
          element: Element, in collection: Elements
        ) where Elements.Element == Element {
          let a = 123
          let b = "abc"
        }
        public init<Elements: Collection, Element>(
          element: Element, in collection: Elements
        )
        where
          Elements.Element == Element, Element: P,
          Element: Equatable
        {
          let a = 123
          let b = "abc"
        }
      }

      """

    var config = Configuration.forTesting
    config.lineBreakBeforeEachArgument = false
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 50, configuration: config)
  }

  func testInitializerWhereClause_lineBreakBeforeEachGenericRequirement() {
    let input =
      """
      struct Struct {
        public init<Elements: Collection, Element>(element: Element, in collection: Elements) where Elements.Element == Element {
          let a = 123
          let b = "abc"
        }
        public init<Elements: Collection, Element>(element: Element, in collection: Elements) where Elements.Element == Element, Element: P, Element: Equatable {
          let a = 123
          let b = "abc"
        }
      }
      """

    let expected =
      """
      struct Struct {
        public init<Elements: Collection, Element>(
          element: Element, in collection: Elements
        ) where Elements.Element == Element {
          let a = 123
          let b = "abc"
        }
        public init<Elements: Collection, Element>(
          element: Element, in collection: Elements
        )
        where
          Elements.Element == Element,
          Element: P,
          Element: Equatable
        {
          let a = 123
          let b = "abc"
        }
      }

      """

    var config = Configuration.forTesting
    config.lineBreakBeforeEachArgument = false
    config.lineBreakBeforeEachGenericRequirement = true
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 50, configuration: config)
  }

  func testInitializerAttributes() {
    let input =
      """
      struct Struct {
        @objc public init() {
          let a = 123
          let b = "abc"
        }
        @objc @inlinable public init() {
          let a = 123
          let b = "abc"
        }
        @objc @available(swift 4.0) public init() {
          let a = 123
          let b = "abc"
        }
      }
      """

    let expected =
      """
      struct Struct {
        @objc public init() {
          let a = 123
          let b = "abc"
        }
        @objc @inlinable public init() {
          let a = 123
          let b = "abc"
        }
        @objc @available(swift 4.0)
        public init() {
          let a = 123
          let b = "abc"
        }
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 35)
  }

  func testInitializerFullWrap() {
    let input =
      """
      struct Struct {
        @objc @inlinable public init<Elements: Collection, Element>(element: Element, in collection: Elements) where Elements.Element == Element, Element: Equatable, Element: P {
          let a = 123
          let b = "abc"
        }
      }
      """

    let expected =
      """
      struct Struct {
        @objc @inlinable
        public init<
          Elements: Collection, Element
        >(
          element: Element,
          in collection: Elements
        )
        where
          Elements.Element == Element,
          Element: Equatable, Element: P
        {
          let a = 123
          let b = "abc"
        }
      }

      """

    var config = Configuration.forTesting
    config.lineBreakBeforeEachArgument = false
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 40, configuration: config)
  }

  func testInitializerFullWrap_lineBreakBeforeEachGenericRequirement() {
    let input =
      """
      struct Struct {
        @objc @inlinable public init<Elements: Collection, Element>(element: Element, in collection: Elements) where Elements.Element == Element, Element: Equatable, Element: P {
          let a = 123
          let b = "abc"
        }
      }
      """

    let expected =
      """
      struct Struct {
        @objc @inlinable
        public init<
          Elements: Collection, Element
        >(
          element: Element,
          in collection: Elements
        )
        where
          Elements.Element == Element,
          Element: Equatable,
          Element: P
        {
          let a = 123
          let b = "abc"
        }
      }

      """

    var config = Configuration.forTesting
    config.lineBreakBeforeEachArgument = false
    config.lineBreakBeforeEachGenericRequirement = true
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 40, configuration: config)
  }

  func testEmptyInitializer() {
    // The comment inside the struct prevents it from *also* being collapsed onto a single line.
    let input = """
      struct X {
        //
        init() {}
      }
      """
    assertPrettyPrintEqual(input: input, expected: input + "\n", linelength: 50)

    let wrapped = """
      struct X {
        //
        init() {
        }
      }

      """
    assertPrettyPrintEqual(input: input, expected: wrapped, linelength: 10)
  }
}
