import SwiftFormat

/// Basic checks and regression tests for the `respectsExistingLineBreaks` configuration setting
/// in both true and false states.
final class RespectsExistingLineBreaksTests: PrettyPrintTestCase {
  func testExpressions() {
    let input =
      """
      a = b + c
        + d
        + e + f + g
        + h + i
      """

    let expectedRespecting =
      """
      a =
        b + c
        + d
        + e + f
        + g
        + h + i

      """

    assertPrettyPrintEqual(
      input: input,
      expected: expectedRespecting,
      linelength: 12,
      configuration: configuration(respectingExistingLineBreaks: true)
    )

    let expectedNotRespecting =
      """
      a =
        b + c + d + e + f + g
        + h + i

      """

    assertPrettyPrintEqual(
      input: input,
      expected: expectedNotRespecting,
      linelength: 25,
      configuration: configuration(respectingExistingLineBreaks: false)
    )
  }

  func testCodeBlocksAndMemberDecls() {
    let input =
      """
      import Module
      import Other

      struct FitsOnOneLine {
        var x: Int
      }

      struct Foo {
        var storedProperty: Int =
          100
        var readOnlyProperty: Int {
          return
            200
        }
        var readWriteProperty: Int {
          get {
            return
              somethingElse
          }
          set {
            somethingElse =
              newValue
          }
        }

        func oneLiner() -> Int {
          return 500
        }
        func someFunction(
          x: Int
        ) {
          foo(x)
          bar(x)
        }
      }
      """

    // No changes expected when respecting existing newlines.
    assertPrettyPrintEqual(
      input: input,
      expected: input + "\n",
      linelength: 80,
      configuration: configuration(respectingExistingLineBreaks: true)
    )

    let expectedNotRespecting =
      """
      import Module
      import Other

      struct FitsOnOneLine { var x: Int }

      struct Foo {
        var storedProperty: Int = 100
        var readOnlyProperty: Int { return 200 }
        var readWriteProperty: Int {
          get { return somethingElse }
          set { somethingElse = newValue }
        }

        func oneLiner() -> Int { return 500 }
        func someFunction(x: Int) {
          foo(x)
          bar(x)
        }
      }

      """

    assertPrettyPrintEqual(
      input: input,
      expected: expectedNotRespecting,
      linelength: 80,
      configuration: configuration(respectingExistingLineBreaks: false)
    )
  }

  func testSemicolons() {
    let input =
      """
      foo(); bar();
      baz();

      struct Foo {
        var a: Int; var b: Int;
        var c: Int;
      }
      """

    // When respecting newlines, we should leave semicolon-delimited statements and declarations on
    // the same line if they were originally like that and likewise preserve newlines after
    // semicolons if present.
    assertPrettyPrintEqual(
      input: input,
      expected: input + "\n",
      linelength: 80,
      configuration: configuration(respectingExistingLineBreaks: true)
    )

    let expectedNotRespecting =
      """
      foo();
      bar();
      baz();

      struct Foo {
        var a: Int;
        var b: Int;
        var c: Int;
      }

      """

    // When not respecting newlines every semicolon-delimited statement or declaration should end up
    // on its own line.
    assertPrettyPrintEqual(
      input: input,
      expected: expectedNotRespecting,
      linelength: 80,
      configuration: configuration(respectingExistingLineBreaks: false)
    )
  }

  func testInvalidBreaksAreAlwaysRejected() {
    // Verify that newlines in places where a break would not be allowed are removed, regardless of
    // the configuration setting.
    let input =
      """
      func foo
        (bar
          : Int) ->
        Int {
        return bar * 2
      }
      """

    let expectedRespecting =
      """
      func foo(bar: Int) -> Int {
        return bar * 2
      }

      """

    assertPrettyPrintEqual(
      input: input,
      expected: expectedRespecting,
      linelength: 80,
      configuration: configuration(respectingExistingLineBreaks: true)
    )

    let expectedNotRespecting =
      """
      func foo(bar: Int) -> Int { return bar * 2 }

      """

    assertPrettyPrintEqual(
      input: input,
      expected: expectedNotRespecting,
      linelength: 80,
      configuration: configuration(respectingExistingLineBreaks: false)
    )
  }

  /// Creates a new configuration with the given value for `respectsExistingLineBreaks` and default
  /// values for everything else.
  private func configuration(respectingExistingLineBreaks: Bool) -> Configuration {
    var config = Configuration.forTesting
    config.respectsExistingLineBreaks = respectingExistingLineBreaks
    return config
  }
}
