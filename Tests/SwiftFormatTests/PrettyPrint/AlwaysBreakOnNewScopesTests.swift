import SwiftFormat

final class AlwaysBreakOnNewScopesTests: PrettyPrintTestCase {
  func testAlwaysBreakOnNewScopesEnabled() {
    let input =
      """
      class A {
        func foo() -> Int { return 1 }
      }
      """

    let expected =
      """
      class A {
        func foo() -> Int {
          return 1
        }
      }

      """
    var config = Configuration.forTesting
    config.alwaysBreakOnNewScopes = true
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 80, configuration: config)
  }

  func testAlwaysBreakOnNewScopesDisabled() {
    let input =
      """
      class A {
        func foo() -> Int { return 1 }
      }
      """

    let expected =
      """
      class A {
        func foo() -> Int { return 1 }
      }

      """
    var config = Configuration.forTesting
    config.alwaysBreakOnNewScopes = false
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 80, configuration: config)
  }

  func testAlwaysBreakOnNewScopesUnlessScopeIsEmpty() {
    let input =
      """
      class A {
        func foo() -> Int { }
      }
      """

    let expected =
      """
      class A {
        func foo() -> Int {}
      }

      """
    var config = Configuration.forTesting
    config.alwaysBreakOnNewScopes = true
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 80, configuration: config)
  }

  func testAlwaysBreakOnNewScopesNestedScopes() {
    let input =
      """
      class A {
        func foo() -> Int { if true { 1 } else { 2 } }
      }
      """

    let expected =
      """
      class A {
        func foo() -> Int {
          if true {
            1
          } else {
            2
          }
        }
      }

      """
    var config = Configuration.forTesting
    config.alwaysBreakOnNewScopes = true
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 80, configuration: config)
  }
}
