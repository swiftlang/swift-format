import SwiftFormat

final class AttributeTests: PrettyPrintTestCase {
  func testAttributeParamSpacing() {
    let input =
      """
      @available( iOS 9.0,* )
      func f() {}
      @available(*, unavailable ,renamed:"MyRenamedProtocol")
      func f() {}
      @available(iOS 10.0, macOS 10.12, *)
      func f() {}
      """

    let expected =
      """
      @available(iOS 9.0, *)
      func f() {}
      @available(*, unavailable, renamed: "MyRenamedProtocol")
      func f() {}
      @available(iOS 10.0, macOS 10.12, *)
      func f() {}

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 60)
  }

  func testAttributeParamSpacingInOriginallyDefinedIn() {
    let input =
      """
      @_originallyDefinedIn( module  :"SwiftUI" , iOS 10.0  )
      func f() {}
      """

    let expected =
      """
      @_originallyDefinedIn(module: "SwiftUI", iOS 10.0)
      func f() {}

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 60)
  }

  func testAttributeParamSpacingInDocVisibility() {
    let input =
      """
      @_documentation(  visibility   :private )
      func f() {}
      """

    let expected =
      """
      @_documentation(visibility: private)
      func f() {}

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 60)
  }

  func testAttributeBinPackedWrapping() {
    let input =
      """
      @available(iOS 9.0, *)
      func f() {}
      @available(*,unavailable, renamed:"MyRenamedProtocol")
      func f() {}
      @available(iOS 10.0, macOS 10.12, *)
      func f() {}
      """

    let expected =
      """
      @available(iOS 9.0, *)
      func f() {}
      @available(
        *, unavailable,
        renamed: "MyRenamedProtocol"
      )
      func f() {}
      @available(
        iOS 10.0, macOS 10.12, *
      )
      func f() {}

      """

    // Attributes should wrap to avoid overflowing the line length, using the following priorities:
    // 1. Keep the entire attribute together, on 1 line.
    // 2. Otherwise, try to keep the entire attribute argument list together on 1 line.
    // 3. Otherwise, use argument list consistency (default: inconsistent) for the arguments.
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 32)
  }

  func testAttributeArgumentPerLineWrapping() {
    let input =
      """
      @available(iOS 9.0, *)
      func f() {}
      @available(*,unavailable, renamed:"MyRenamedProtocol")
      func f() {}
      @available(iOS 10.0, macOS 10.12, *)
      func f() {}
      """

    let expected =
      """
      @available(iOS 9.0, *)
      func f() {}
      @available(
        *,
        unavailable,
        renamed: "MyRenamedProtocol"
      )
      func f() {}
      @available(
        iOS 10.0,
        macOS 10.12,
        *
      )
      func f() {}

      """

    var configuration = Configuration.forTesting
    configuration.lineBreakBeforeEachArgument = true
    assertPrettyPrintEqual(
      input: input,
      expected: expected,
      linelength: 32,
      configuration: configuration
    )
  }

  func testAttributeFormattingRespectsDiscretionaryLineBreaks() {
    let input =
      """
      @available(
        iOSApplicationExtension,
        introduced: 10.0,
        deprecated: 11.0,
        message:
          "Use something else because this is definitely deprecated.")
      func f2() {}
      """

    let expected =
      """
      @available(
        iOSApplicationExtension,
        introduced: 10.0,
        deprecated: 11.0,
        message:
          "Use something else because this is definitely deprecated."
      )
      func f2() {}

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 40)
  }

  func testAttributeInterArgumentBinPackedLineBreaking() {
    let input =
      """
      @available(iOSApplicationExtension, introduced: 10.0, deprecated: 11.0, message: "Use something else because this is definitely deprecated.")
      func f2() {}
      """

    let expected =
      """
      @available(
        iOSApplicationExtension,
        introduced: 10.0, deprecated: 11.0,
        message:
          "Use something else because this is definitely deprecated."
      )
      func f2() {}

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 40)
  }

  func testAttributArgumentPerLineBreaking() {
    let input =
      """
      @available(iOSApplicationExtension, introduced: 10.0, deprecated: 11.0, message: "Use something else because this is definitely deprecated.")
      func f2() {}
      """

    let expected =
      """
      @available(
        iOSApplicationExtension,
        introduced: 10.0,
        deprecated: 11.0,
        message:
          "Use something else because this is definitely deprecated."
      )
      func f2() {}

      """

    var configuration = Configuration.forTesting
    configuration.lineBreakBeforeEachArgument = true
    assertPrettyPrintEqual(
      input: input,
      expected: expected,
      linelength: 40,
      configuration: configuration
    )
  }

  func testObjCBinPackedAttributes() {
    let input =
      """
      @objc func f() {}
      @objc(foo:bar:baz:)
      func f() {}
      @objc(thisMethodHasAVeryLongName:foo:bar:)
      func f() {}
      @objc(thisMethodHasAVeryLongName:andThisArgumentHasANameToo:soDoesThisOne:bar:)
      func f() {}
      """

    let expected =
      """
      @objc func f() {}
      @objc(foo:bar:baz:)
      func f() {}
      @objc(
        thisMethodHasAVeryLongName:foo:bar:
      )
      func f() {}
      @objc(
        thisMethodHasAVeryLongName:
        andThisArgumentHasANameToo:
        soDoesThisOne:bar:
      )
      func f() {}

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 40)
  }

  func testObjCAttributesPerLineBreaking() {
    let input =
      """
      @objc func f() {}
      @objc(foo:bar:baz)
      func f() {}
      @objc(thisMethodHasAVeryLongName:foo:bar:)
      func f() {}
      @objc(thisMethodHasAVeryLongName:andThisArgumentHasANameToo:soDoesThisOne:bar:)
      func f() {}
      """

    let expected =
      """
      @objc func f() {}
      @objc(foo:bar:baz)
      func f() {}
      @objc(
        thisMethodHasAVeryLongName:
        foo:
        bar:
      )
      func f() {}
      @objc(
        thisMethodHasAVeryLongName:
        andThisArgumentHasANameToo:
        soDoesThisOne:
        bar:
      )
      func f() {}

      """

    var configuration = Configuration.forTesting
    configuration.lineBreakBeforeEachArgument = true
    assertPrettyPrintEqual(
      input: input,
      expected: expected,
      linelength: 40,
      configuration: configuration
    )
  }

  func testObjCAttributesDiscretionaryLineBreaking() {
    // The discretionary newlines in the 3rd function declaration are invalid, because new lines
    // should be after the ":" character in Objective-C selector pieces, so they should be removed.
    let input =
      """
      @objc
      func f() {}
      @objc(foo:
            bar:
            baz:)
      func f() {}
      @objc(foo
            :bar
            :baz:)
      func f() {}
      @objc(
        thisMethodHasAVeryLongName:
        foo:
        bar:
      )
      func f() {}
      """

    let expected =
      """
      @objc
      func f() {}
      @objc(
        foo:
        bar:
        baz:
      )
      func f() {}
      @objc(foo:bar:baz:)
      func f() {}
      @objc(
        thisMethodHasAVeryLongName:
        foo:
        bar:
      )
      func f() {}

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 80)
  }

  func testIgnoresDiscretionaryLineBreakAfterColon() {
    let input =
      """
      @available(
        *, unavailable,
        renamed:
          "MyRenamedFunction"
      )
      func f() {}
      """

    let expected =
      """
      @available(
        *, unavailable,
        renamed: "MyRenamedFunction"
      )
      func f() {}

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 30)
  }

  func testPropertyWrappers() {
    let input =
      """
      struct X {
        @Wrapper var value: String

        @Wrapper ( ) var value: String

        @Wrapper (arg1:"value")var value: String

        @Wrapper (arg1:"value")
        var value: String

        @Wrapper (arg1:"value",arg2:otherValue)
        var value: String
      }
      """

    let expected =
      """
      struct X {
        @Wrapper var value: String

        @Wrapper() var value: String

        @Wrapper(arg1: "value")
        var value: String

        @Wrapper(arg1: "value")
        var value: String

        @Wrapper(
          arg1: "value",
          arg2: otherValue)
        var value: String
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 32)
  }

  func testMultilineStringLiteralInCustomAttribute() {
    let input =
      #"""
      @CustomAttribute(message: """
      This is a
      multiline
      string
      """)
      public func f() {}
      """#

    let expected =
      #"""
      @CustomAttribute(
        message: """
          This is a
          multiline
          string
          """)
      public func f() {}

      """#

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 100)
  }

  func testMultilineStringLiteralInAvailableAttribute() {
    let input =
      #"""
      @available(*, deprecated, message: """
      This is a
      multiline
      string
      """)
      public func f() {}
      """#

    let expected =
      #"""
      @available(
        *, deprecated,
        message: """
          This is a
          multiline
          string
          """
      )
      public func f() {}

      """#

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 100)
  }

  func testAttributeParamSpacingInExpose() {
    let input =
      """
      @_expose( wasm  , "foo"  )
      func f() {}

      @_expose( Cxx  ,   "bar")
      func b() {}

      """

    let expected =
      """
      @_expose(wasm, "foo")
      func f() {}

      @_expose(Cxx, "bar")
      func b() {}

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 100)
  }

  func testLineBreakBetweenDeclarationAttributes() {
    let input =
      """
      @_spi(Private) @_spi(InviteOnly) import SwiftFormat

      @available(iOS 14.0, *) @available(macOS 11.0, *)
      public protocol P {
        @available(iOS 16.0, *) @available(macOS 14.0, *)
        #if DEBUG
          @available(tvOS 17.0, *) @available(watchOS 10.0, *)
        #endif
        @available(visionOS 1.0, *)
        associatedtype ID
      }

      @available(iOS 14.0, *) @available(macOS 11.0, *)
      public enum Dimension {
        case x
        case y
        @available(iOS 17.0, *) @available(visionOS 1.0, *)
        case z
      }

      @available(iOS 16.0, *) @available(macOS 14.0, *)
      @available(tvOS 16.0, *) @frozen
      struct X {
        @available(iOS 17.0, *) @available(macOS 15.0, *)
        typealias ID = UUID

        @available(iOS 17.0, *) @available(macOS 15.0, *)
        var callMe: @MainActor @Sendable () -> Void

        @available(iOS 17.0, *) @available(macOS 15.0, *)
        @MainActor @discardableResult
        func f(@_inheritActorContext body: @MainActor @Sendable () -> Void) {}

        @available(iOS 17.0, *) @available(macOS 15.0, *) @MainActor
        var foo: Foo {
          get { Foo() }
          @available(iOS, obsoleted: 17.0) @available(macOS 15.0, obsoleted: 15.0)
          set { fatalError() }
        }
      }
      """

    let expected =
      """
      @_spi(Private) @_spi(InviteOnly) import SwiftFormat

      @available(iOS 14.0, *)
      @available(macOS 11.0, *)
      public protocol P {
        @available(iOS 16.0, *)
        @available(macOS 14.0, *)
        #if DEBUG
          @available(tvOS 17.0, *)
          @available(watchOS 10.0, *)
        #endif
        @available(visionOS 1.0, *)
        associatedtype ID
      }

      @available(iOS 14.0, *)
      @available(macOS 11.0, *)
      public enum Dimension {
        case x
        case y
        @available(iOS 17.0, *)
        @available(visionOS 1.0, *)
        case z
      }

      @available(iOS 16.0, *)
      @available(macOS 14.0, *)
      @available(tvOS 16.0, *)
      @frozen
      struct X {
        @available(iOS 17.0, *)
        @available(macOS 15.0, *)
        typealias ID = UUID

        @available(iOS 17.0, *)
        @available(macOS 15.0, *)
        var callMe: @MainActor @Sendable () -> Void

        @available(iOS 17.0, *)
        @available(macOS 15.0, *)
        @MainActor
        @discardableResult
        func f(@_inheritActorContext body: @MainActor @Sendable () -> Void) {}

        @available(iOS 17.0, *)
        @available(macOS 15.0, *)
        @MainActor
        var foo: Foo {
          get { Foo() }
          @available(iOS, obsoleted: 17.0)
          @available(macOS 15.0, obsoleted: 15.0)
          set { fatalError() }
        }
      }

      """
    var configuration = Configuration.forTesting
    configuration.lineBreakBetweenDeclarationAttributes = true
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 80, configuration: configuration)
  }

  func testAttributesStartWithPoundIf() {
    let input =
      """
      #if os(macOS)
      @available(macOS, unavailable)
      @_spi(Foo)
      #endif
      public let myVar = "Test"

      """
    let expected =
      """
      #if os(macOS)
        @available(macOS, unavailable)
        @_spi(Foo)
      #endif
      public let myVar = "Test"

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 45)
  }
}
