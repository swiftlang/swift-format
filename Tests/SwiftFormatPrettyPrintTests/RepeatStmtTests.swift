import SwiftFormatConfiguration

public class RepeatStmtTests: PrettyPrintTestCase {

  public func testBasicRepeatTests_noBreakBeforeWhile() {
    let input =
      """
      repeat {}
      while x
      repeat { f() }
      while x
      repeat { foo() }
      while longcondition
      repeat {
        let a = 123
        var b = "abc"
      }
      while condition
      repeat {
        let a = 123
        var b = "abc"
      }
      while condition && condition2
      """

    let expected =
      """
      repeat {} while x
      repeat { f() } while x
      repeat {
        foo()
      } while longcondition
      repeat {
        let a = 123
        var b = "abc"
      } while condition
      repeat {
        let a = 123
        var b = "abc"
      } while condition
        && condition2

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 25)
  }

  public func testBasicRepeatTests_breakBeforeWhile() {
    let input =
      """
      repeat {} while x
      repeat { f() } while x
      repeat { foo() } while longcondition
      repeat {
        let a = 123
        var b = "abc"
      }
      while condition
      repeat {
        let a = 123
        var b = "abc"
      }
      while condition && condition2
      """

    let expected =
      """
      repeat {} while x
      repeat { f() } while x
      repeat { foo() }
      while longcondition
      repeat {
        let a = 123
        var b = "abc"
      }
      while condition
      repeat {
        let a = 123
        var b = "abc"
      }
      while condition
        && condition2

      """

    var config = Configuration()
    config.lineBreakBeforeControlFlowKeywords = true
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 25, configuration: config)
  }

  public func testNestedRepeat() {
    // Avoid regressions in the case where a nested `repeat` block was getting shifted all the way
    // left.
    let input = """
      func foo() {
        repeat {
          bar()
          baz()
        } while condition
      }
      """
    assertPrettyPrintEqual(input: input, expected: input + "\n", linelength: 45)
  }
}
