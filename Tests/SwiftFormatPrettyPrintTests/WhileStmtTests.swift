public class WhileStmtTests: PrettyPrintTestCase {
  public func testBasicWhileLoops() {
    let input =
      """
      while condition {
        let a = 123
        var b = "abc"
      }
      while var1, var2 {
        let a = 123
        var b = "abc"
      }
      while var123, var456 {
        let a = 123
        var b = "abc"
      }
      while condition1 && condition2 || condition3 {
        let a = 123
        var b = "abc"
      }
      """

    let expected =
      """
      while condition {
        let a = 123
        var b = "abc"
      }
      while var1, var2 {
        let a = 123
        var b = "abc"
      }
      while var123, var456
      {
        let a = 123
        var b = "abc"
      }
      while condition1
        && condition2
        || condition3
      {
        let a = 123
        var b = "abc"
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 20)
  }

  public func testLabeledWhileLoops() {
    let input =
      """
      myLabel: while condition {
        let a = 123
        var b = "abc"
      }
      myLabel: while var123, var456 {
        let a = 123
        var b = "abc"
      }
      myLabel: while condition1 && condition2 || condition3 || condition4 {
        let a = 123
        var b = "abc"
      }
      """

    let expected =
      """
      myLabel: while condition {
        let a = 123
        var b = "abc"
      }
      myLabel: while var123, var456
      {
        let a = 123
        var b = "abc"
      }
      myLabel: while condition1
        && condition2 || condition3
        || condition4
      {
        let a = 123
        var b = "abc"
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 29)
  }
}
