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

final class IfConfigTests: PrettyPrintTestCase {
  func testBasicIfConfig() {
    let input =
      """
      #if someCondition
        let a = 123
        let b = "abc"
      #endif

      #if someCondition
        let a = 123
        let b = "abc"
      #else
        let c = 456
        let d = "def"
      #endif

      #if swift(>=4.0)
        print("Stuff")
      #endif
      #if swift(>=4.0)
        print("Stuff")
      #elseif compiler(>=3.0)
        print("More Stuff")
        print("Another Line")
      #endif
      """

    let expected =
      """
      #if someCondition
        let a = 123
        let b = "abc"
      #endif

      #if someCondition
        let a = 123
        let b = "abc"
      #else
        let c = 456
        let d = "def"
      #endif

      #if swift(>=4.0)
        print("Stuff")
      #endif
      #if swift(>=4.0)
        print("Stuff")
      #elseif compiler(>=3.0)
        print("More Stuff")
        print("Another Line")
      #endif

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 45)
  }

  func testIfConfigNoIndentation() {
    let input =
      """
      #if someCondition
        let a = 123
        let b = "abc"
      #endif

      #if someCondition
        let a = 123
        let b = "abc"
      #else
        let c = 456
        let d = "def"
      #endif

      #if swift(>=4.0)
        print("Stuff")
      #endif
      #if swift(>=4.0)
        print("Stuff")
      #elseif compiler(>=3.0)
        print("More Stuff")
        print("Another Line")
      #endif
      """

    let expected =
      """
      #if someCondition
      let a = 123
      let b = "abc"
      #endif

      #if someCondition
      let a = 123
      let b = "abc"
      #else
      let c = 456
      let d = "def"
      #endif

      #if swift(>=4.0)
      print("Stuff")
      #endif
      #if swift(>=4.0)
      print("Stuff")
      #elseif compiler(>=3.0)
      print("More Stuff")
      print("Another Line")
      #endif

      """

    var config = Configuration.forTesting
    config.indentConditionalCompilationBlocks = false
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 45, configuration: config)
  }

  func testPoundIfAroundMembers() {
    let input =
      """
      class Foo {
      #if DEBUG
        var bar: String
        var baz: String
      #endif
      }
      """

    let expected =
      """
      class Foo {
        #if DEBUG
          var bar: String
          var baz: String
        #endif
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 45)
  }

  func testPrettyPrintLineBreaksDisabled() {
    let input =
      """
      #if canImport(SwiftUI) && !(os(iOS)&&arch( arm ) )&&( (canImport(AppKit) || canImport(UIKit)) && !os(watchOS))
        conditionalFunc(foo, bar, baz)
      #endif
      """

    let expected =
      """
      #if canImport(SwiftUI) && !(os(iOS) && arch(arm)) && ((canImport(AppKit) || canImport(UIKit)) && !os(watchOS))
        conditionalFunc(foo, bar, baz)
      #endif

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 40)
  }

  func testInvalidDiscretionaryLineBreaksRemoved() {
    let input =
      """
      #if (canImport(SwiftUI) &&
      !(os(iOS) &&
       arch(arm)) &&
         ((canImport(AppKit) ||
      canImport(UIKit)) && !os(watchOS)))
      conditionalFunc(foo, bar, baz)
        #endif
      """

    let expected =
      """
      #if (canImport(SwiftUI) && !(os(iOS) && arch(arm)) && ((canImport(AppKit) || canImport(UIKit)) && !os(watchOS)))
        conditionalFunc(foo, bar, baz)
      #endif

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 40)
  }

  func testValidDiscretionaryLineBreaksRetained() {
    let input =
      """
      #if (canImport(SwiftUI)
      && !(os(iOS)
      && arch(arm))
      && ((canImport(AppKit)
      || canImport(UIKit)) && !os(watchOS))
      && canImport(Foundation))
        conditionalFunc(foo, bar, baz)
      #endif

      #if (canImport(SwiftUI)
        && os(iOS)
        && arch(arm)
        && canImport(AppKit)
        || canImport(UIKit) && !os(watchOS)
        && canImport(Foundation))
        conditionalFunc(foo, bar, baz)
      #endif
      """

    let expected =
      """
      #if (canImport(SwiftUI)
        && !(os(iOS)
          && arch(arm))
        && ((canImport(AppKit)
          || canImport(UIKit)) && !os(watchOS))
        && canImport(Foundation))
        conditionalFunc(foo, bar, baz)
      #endif

      #if (canImport(SwiftUI)
        && os(iOS)
        && arch(arm)
        && canImport(AppKit)
        || canImport(UIKit) && !os(watchOS)
          && canImport(Foundation))
        conditionalFunc(foo, bar, baz)
      #endif

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 40)
  }

  func testPostfixPoundIfAfterParentheses() {
    let input =
      """
      VStack {
        Text("something")
        #if os(iOS)
        .iOSSpecificModifier()
        #endif
        .commonModifier()
      }
      """

    let expected =
      """
      VStack {
        Text("something")
          #if os(iOS)
            .iOSSpecificModifier()
          #endif
          .commonModifier()
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 45)
  }

  func testPostfixPoundIfAfterParenthesesMultipleMembers() {
    let input =
      """
      VStack {
        Text("something")
        #if os(iOS)
        .iOSSpecificModifier()
        .anotherModifier()
        .anotherAnotherModifier()
        #endif
        .commonModifier()
        .anotherCommonModifier()
      }
      """

    let expected =
      """
      VStack {
        Text("something")
          #if os(iOS)
            .iOSSpecificModifier()
            .anotherModifier()
            .anotherAnotherModifier()
          #endif
          .commonModifier()
          .anotherCommonModifier()
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 45)
  }

  func testPostfixPoundIfNested() {
    let input =
      """
      VStack {
        Text("something")
        #if os(iOS) || os(watchOS)
          #if os(iOS)
          .iOSModifier()
          #elseif os(tvOS)
          .tvOSModifier()
          #else
          .watchOSModifier()
          #endif
        .iOSAndWatchOSModifier()
        #endif
      }
      """

    let expected =
      """
      VStack {
        Text("something")
          #if os(iOS) || os(watchOS)
            #if os(iOS)
              .iOSModifier()
            #elseif os(tvOS)
              .tvOSModifier()
            #else
              .watchOSModifier()
            #endif
            .iOSAndWatchOSModifier()
          #endif
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 45)
  }

  func testPostfixPoundIfAfterVariables() {
    let input =
      """
      VStack {
        textView
        #if os(iOS)
        .iOSSpecificModifier()
        #endif
        .commonModifier()
      }
      """

    let expected =
      """
      VStack {
        textView
          #if os(iOS)
            .iOSSpecificModifier()
          #endif
          .commonModifier()
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 45)
  }

  func testPostfixPoundIfAfterClosingBrace() {
    let input =
      """
      HStack {
          Toggle(isOn: binding) {
              Text("Some text")
          }
          #if !os(tvOS)
          .toggleStyle(SwitchToggleStyle(tint: Color.blue))
          #endif
          .accessibilityValue(
              binding.wrappedValue == true ? "On" : "Off"
          )
      }
      """

    let expected =
      """
      HStack {
        Toggle(isOn: binding) {
          Text("Some text")
        }
        #if !os(tvOS)
          .toggleStyle(
            SwitchToggleStyle(tint: Color.blue))
        #endif
        .accessibilityValue(
          binding.wrappedValue == true
            ? "On" : "Off"
        )
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 45)
  }

  func testPostfixPoundIfBetweenOtherModifiers() {
    let input =
      """
      EmptyView()
        .padding([.vertical])
      #if os(iOS)
        .iOSSpecificModifier()
        .anotherIOSSpecificModifier()
      #endif
        .commonModifier()
      """

    let expected =
      """
      EmptyView()
        .padding([.vertical])
        #if os(iOS)
          .iOSSpecificModifier()
          .anotherIOSSpecificModifier()
        #endif
        .commonModifier()

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 45)
  }

  func testPostfixPoundIfWithTypeInModifier() {
    let input =
      """
      EmptyView()
        .padding([.vertical])
      #if os(iOS)
        .iOSSpecificModifier(
          SpecificType()
            .onChanged { _ in
              // do things
            }
            .onEnded { _ in
              // do things
            }
        )
      #endif
      """

    let expected =
      """
      EmptyView()
        .padding([.vertical])
        #if os(iOS)
          .iOSSpecificModifier(
            SpecificType()
              .onChanged { _ in
                // do things
              }
              .onEnded { _ in
                // do things
              }
          )
        #endif

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 45)
  }

  func testPostfixPoundIfNotIndentedIfClosingParenOnOwnLine() {
    let input =
      """
      SomeFunction(
        foo,
        bar
      )
      #if os(iOS)
      .iOSSpecificModifier()
      #endif
      .commonModifier()
      """

    let expected =
      """
      SomeFunction(
        foo,
        bar
      )
      #if os(iOS)
        .iOSSpecificModifier()
      #endif
      .commonModifier()

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 45)
  }

  func testPostfixPoundIfForcesPrecedingClosingParenOntoNewLine() {
    let input =
      """
      SomeFunction(
        foo,
        bar)
        #if os(iOS)
        .iOSSpecificModifier()
        #endif
        .commonModifier()
      """

    let expected =
      """
      SomeFunction(
        foo,
        bar
      )
      #if os(iOS)
        .iOSSpecificModifier()
      #endif
      .commonModifier()

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 45)
  }

  func testPostfixPoundIfInParameterList() {
    let input =
      """
      print(
        32
          #if true
            .foo
          #endif
        , 22
      )

      """
    assertPrettyPrintEqual(input: input, expected: input, linelength: 45)
  }

  func testNestedPoundIfInSwitchStatement() {
    let input =
      """
      switch self {
      #if os(iOS) || os(tvOS) || os(watchOS)
      case .a:
        return 40
      #if os(iOS) || os(tvOS)
      case .e:
        return 30
      #endif
      #if os(iOS)
      case .g:
        return 2
      #endif
      #endif
      default:
        return nil
      }

      """
    var configuration = Configuration.forTesting
    configuration.indentConditionalCompilationBlocks = false
    assertPrettyPrintEqual(input: input, expected: input, linelength: 45, configuration: configuration)
  }
}
