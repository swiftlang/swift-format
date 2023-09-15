import SwiftFormatConfiguration

final class RepeatStmtTests: PrettyPrintTestCase {
  func testBasicRepeatTests_noBreakBeforeWhile() {
    let input =
      """
      repeat {}
      while x
      repeat { f() }
      while x
      repeat { foo() }
      while longcondition
      repeat { f() }
      while long.condition
      repeat { f() } while long.condition
      repeat { f() } while long.condition.that.ison.many.lines
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
        f()
      } while long.condition
      repeat {
        f()
      } while long.condition
      repeat {
        f()
      } while long.condition
        .that.ison.many.lines
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

  func testBasicRepeatTests_breakBeforeWhile() {
    let input =
      """
      repeat {} while x
      repeat { f() } while x
      repeat { foo() } while longcondition
      repeat { f() }
      while long.condition
      repeat { f() } while long.condition
      repeat { f() } while long.condition.that.ison.many.lines
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
      repeat { f() }
      while long.condition
      repeat { f() }
      while long.condition
      repeat { f() }
      while long.condition.that
        .ison.many.lines
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

  func testNestedRepeat() {
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

  func testLabeledRepeat() {
    let input = """
      someLabel:repeat {
        bar()
        baz()
      } while condition
      somePrettyLongLabelThatTakesUpManyColumns: repeat {
        bar()
        baz()
      } while condition
      """

    let expected = """
      someLabel: repeat {
        bar()
        baz()
      } while condition
      somePrettyLongLabelThatTakesUpManyColumns: repeat
      {
        bar()
        baz()
      } while condition

      """
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 45)
  }
}
