import SwiftFormatConfiguration

public class AttributeTests: PrettyPrintTestCase {
  public func testAttributeParamSpacing() {
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

  public func testAttributeBinPackedWrapping() {
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

  public func testAttributeArgumentPerLineWrapping() {
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

    var configuration = Configuration()
    configuration.lineBreakBeforeEachArgument = true
    assertPrettyPrintEqual(
      input: input, expected: expected, linelength: 32, configuration: configuration)
  }

  public func testAttributeFormattingRespectsDiscretionaryLineBreaks() {
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

  public func testAttributeInterArgumentBinPackedLineBreaking() {
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

  public func testAttributArgumentPerLineBreaking() {
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

    var configuration = Configuration()
    configuration.lineBreakBeforeEachArgument = true
    assertPrettyPrintEqual(
      input: input, expected: expected, linelength: 40, configuration: configuration)
  }

  public func testObjCBinPackedAttributes() {
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

  public func testObjCAttributesPerLineBreaking() {
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

     var configuration = Configuration()
     configuration.lineBreakBeforeEachArgument = true
     assertPrettyPrintEqual(
       input: input, expected: expected, linelength: 40, configuration: configuration)
   }

  public func testObjCAttributesDiscretionaryLineBreaking() {
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
}
