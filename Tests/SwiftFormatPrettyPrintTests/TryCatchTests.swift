import SwiftFormatConfiguration

public class TryCatchTests: PrettyPrintTestCase {
  public func testBasicTries() {
    let input =
      """
      let a = try possiblyFailingFunc()
      let a = try? possiblyFailingFunc()
      let a = try! possiblyFailingFunc()
      """

    let expected =
      """
      let a = try possiblyFailingFunc()
      let a = try? possiblyFailingFunc()
      let a = try! possiblyFailingFunc()

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 40)
  }

  public func testDoTryCatch_noBreakBeforeCatch() {
    let input =
      """
      do { try thisFuncMightFail() } catch error1 { print("Nope") }
      do { try thisFuncMightFail() } catch error1 { print("Nope") } catch error2 { print("Nope") }
      do { try thisFuncMightFail() } catch error1 { print("Nope") } catch error2(let someVar) { print("Nope") }
      do { try thisFuncMightFail() } catch error1 { print("Nope") }
      catch error2(let someVar) {
        print(someVar)
        print("Don't do it!")
      }
      do { try thisFuncMightFail() } catch is ABadError{ print("Nope") }
      """

    let expected =
      """
      do {
        try thisFuncMightFail()
      } catch error1 { print("Nope") }
      do {
        try thisFuncMightFail()
      } catch error1 {
        print("Nope")
      } catch error2 { print("Nope") }
      do {
        try thisFuncMightFail()
      } catch error1 {
        print("Nope")
      } catch error2(let someVar) {
        print("Nope")
      }
      do {
        try thisFuncMightFail()
      } catch error1 {
        print("Nope")
      } catch error2(let someVar) {
        print(someVar)
        print("Don't do it!")
      }
      do {
        try thisFuncMightFail()
      } catch is ABadError { print("Nope") }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 40)
  }

  public func testDoTryCatch_breakBeforeCatch() {
    let input =
      """
      do { try thisFuncMightFail() } catch error1 { print("Nope") }
      do { try thisFuncMightFail() } catch error1 { print("Nope") } catch error2 { print("Nope") }
      do { try thisFuncMightFail() } catch error1 { print("Nope") } catch error2(let someVar) { print("Nope") }
      do { try thisFuncMightFail() } catch error1 { print("Nope") }
      catch error2(let someVar) {
        print(someVar)
        print("Don't do it!")
      }
      do { try thisFuncMightFail() } catch is ABadError{ print("Nope") }
      """

    let expected =
      """
      do { try thisFuncMightFail() }
      catch error1 { print("Nope") }
      do { try thisFuncMightFail() }
      catch error1 { print("Nope") }
      catch error2 { print("Nope") }
      do { try thisFuncMightFail() }
      catch error1 { print("Nope") }
      catch error2(let someVar) {
        print("Nope")
      }
      do { try thisFuncMightFail() }
      catch error1 { print("Nope") }
      catch error2(let someVar) {
        print(someVar)
        print("Don't do it!")
      }
      do { try thisFuncMightFail() }
      catch is ABadError { print("Nope") }

      """

    var config = Configuration()
    config.lineBreakBeforeControlFlowKeywords = true
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 40, configuration: config)
  }

  public func testCatchWhere_noBreakBeforeCatch() {
    let input =
      """
      do { try thisFuncMightFail() } catch error1 where error1 is ErrorType { print("Nope") }
      do { try thisFuncMightFail() } catch error1 where error1 is LongerErrorType { print("Nope") }
      """

    let expected =
      """
      do {
        try thisFuncMightFail()
      } catch error1 where error1 is ErrorType {
        print("Nope")
      }
      do {
        try thisFuncMightFail()
      } catch error1
        where error1 is LongerErrorType
      { print("Nope") }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 42)
  }

  public func testCatchWhere_breakBeforeCatch() {
    let input =
      """
      do { try thisFuncMightFail() } catch error1 where error1 is ErrorType { print("Nope") }
      do { try thisFuncMightFail() } catch error1 where error1 is LongerErrorType { print("Nope") }
      """

    let expected =
      """
      do { try thisFuncMightFail() }
      catch error1 where error1 is ErrorType {
        print("Nope")
      }
      do { try thisFuncMightFail() }
      catch error1
      where error1 is LongerErrorType {
        print("Nope")
      }

      """

    var config = Configuration()
    config.lineBreakBeforeControlFlowKeywords = true
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 42, configuration: config)
  }

  public func testNestedDo() {
    // Avoid regressions in the case where a nested `do` block was getting shifted all the way left.
    let input = """
      func foo() {
        do {
          bar()
          baz()
        }
      }
      """
    assertPrettyPrintEqual(input: input, expected: input + "\n", linelength: 45)
  }
}
