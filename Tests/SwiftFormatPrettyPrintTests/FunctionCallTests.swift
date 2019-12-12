import SwiftFormatConfiguration

public class FunctionCallTests: PrettyPrintTestCase {

  public func testBasicFunctionCalls_noPackArguments() {
    let input =
      """
      let a = myFunc()
      let a = myFunc(var1: 123, var2: "abc")
      let a = myFunc(var1: 123, var2: "abc", var3: Bool, var4: (1, 2, 3))
      let a = myFunc(var1, var2, var3)
      let a = myFunc(var1, var2, var3, var4, var5, var6)
      let a = myFunc(var1, var2, var3, var4, var5, var6, var7, x)
      let a = myFunc(var1: 123, var2: someFun(var1: "abc", var2: 123, var3: Bool, var4: 1.23))
      """

    let expected =
      """
      let a = myFunc()
      let a = myFunc(var1: 123, var2: "abc")
      let a = myFunc(
        var1: 123,
        var2: "abc",
        var3: Bool,
        var4: (1, 2, 3)
      )
      let a = myFunc(var1, var2, var3)
      let a = myFunc(
        var1,
        var2,
        var3,
        var4,
        var5,
        var6
      )
      let a = myFunc(
        var1,
        var2,
        var3,
        var4,
        var5,
        var6,
        var7,
        x
      )
      let a = myFunc(
        var1: 123,
        var2: someFun(
          var1: "abc",
          var2: 123,
          var3: Bool,
          var4: 1.23
        )
      )

      """

    var config = Configuration()
    config.lineBreakBeforeEachArgument = true
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 45, configuration: config)
  }

  public func testBasicFunctionCalls_packArguments() {
    let input =
      """
      let a = myFunc()
      let a = myFunc(var1: 123, var2: "abc")
      let a = myFunc(var1: 123, var2: "abc", var3: Bool, var4: (1, 2, 3))
      let a = myFunc(var1, var2, var3)
      let a = myFunc(var1, var2, var3, var4, var5, var6)
      let a = myFunc(var1, var2, var3, var4, var5, var6, var7, x)
      let a = myFunc(var1: 123, var2: someFun(var1: "abc", var2: 123, var3: Bool, var4: 1.23))
      """

    let expected =
      """
      let a = myFunc()
      let a = myFunc(var1: 123, var2: "abc")
      let a = myFunc(
        var1: 123, var2: "abc", var3: Bool,
        var4: (1, 2, 3))
      let a = myFunc(var1, var2, var3)
      let a = myFunc(
        var1, var2, var3, var4, var5, var6)
      let a = myFunc(
        var1, var2, var3, var4, var5, var6, var7, x
      )
      let a = myFunc(
        var1: 123,
        var2: someFun(
          var1: "abc", var2: 123, var3: Bool,
          var4: 1.23))

      """

    var config = Configuration()
    config.lineBreakBeforeEachArgument = false
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 45, configuration: config)
  }

  public func testDiscretionaryLineBreakBeforeClosingParenthesis() {
    let input =
      """
      let a = myFunc(
        var1: 123,
        var2: "abc"
      )
      """
    assertPrettyPrintEqual(input: input, expected: input + "\n", linelength: 45)
  }

  public func testDiscretionaryLineBreaksAreSelfCorrecting() {
    // A discretionary line break should never permit a violation of the rule that says,
    // effectively, "if a closing delimiter does not fit on the same line as its matching open
    // delimiter, then the open delimiter is the last token on that line" (which is implemented in
    // Oppen using consistent breaking groups). The line break we insert, if working correctly,
    // should force the entire group to be moved down as we want.
    let input =
      """
      let a = myFunc(var1: 123, var2: "abc"
      )
      """

    let expected =
      """
      let a = myFunc(
        var1: 123, var2: "abc"
      )

      """
    var config = Configuration()
    config.lineBreakBeforeEachArgument = false
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 45, configuration: config)
  }

  public func testArgumentStartsWithOpenDelimiter() {
    let input =
      """
      myFunc(someArray: [1000, 2000, 3000, 4000, 5000, 6000, 7000, 8000])
      myFunc(someDictionary: ["foo": "bar", "baz": "quux", "glip": "glop"])
      myFunc(someClosure: { foo, bar in baz(1000, 2000, 3000, 4000, 5000) })
      myFunc(someArray: [1000, 2000, 3000, 4000, 5000, 6000, 7000, 8000]) { foo in bar() }
      myFunc(someArray: [1000, 2000, 3000, 4000, 5000, 6000, 7000, 8000]) { foo in someMuchLongerLineBreakingBarFunction() }
      """

    let expected =
      """
      myFunc(someArray: [
        1000, 2000, 3000, 4000, 5000, 6000, 7000,
        8000
      ])
      myFunc(someDictionary: [
        "foo": "bar", "baz": "quux", "glip": "glop"
      ])
      myFunc(someClosure: { foo, bar in
        baz(1000, 2000, 3000, 4000, 5000)
      })
      myFunc(someArray: [
        1000, 2000, 3000, 4000, 5000, 6000, 7000,
        8000
      ]) { foo in bar() }
      myFunc(someArray: [
        1000, 2000, 3000, 4000, 5000, 6000, 7000,
        8000
      ]) { foo in
        someMuchLongerLineBreakingBarFunction()
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 45)
  }

  public func testSingleUnlabeledArgumentWithDelimiters() {
    let input =
      """
      myFunc([1000, 2000, 3000, 4000, 5000, 6000, 7000, 8000])
      myFunc(["foo": "bar", "baz": "quux", "glip": "glop"])
      myFunc({ foo, bar in baz(1000, 2000, 3000, 4000, 5000) })
      myFunc([1000, 2000, 3000, 4000, 5000, 6000, 7000, 8000]) { foo in bar() }
      myFunc([1000, 2000, 3000, 4000, 5000, 6000, 7000, 8000]) { foo in someMuchLongerLineBreakingBarFunction() }
      """

    let expected =
      """
      myFunc([
        1000, 2000, 3000, 4000, 5000, 6000, 7000,
        8000
      ])
      myFunc([
        "foo": "bar", "baz": "quux", "glip": "glop"
      ])
      myFunc({ foo, bar in
        baz(1000, 2000, 3000, 4000, 5000)
      })
      myFunc([
        1000, 2000, 3000, 4000, 5000, 6000, 7000,
        8000
      ]) { foo in bar() }
      myFunc([
        1000, 2000, 3000, 4000, 5000, 6000, 7000,
        8000
      ]) { foo in
        someMuchLongerLineBreakingBarFunction()
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 45)
  }

  func testNestedFunctionCallExprSequences() {
    let input =
      """
      let result = firstObj.someOptionalReturningFunc(foo: arg) ?? (someOtherObj as SomeUsefulType).someGetterFunc()
      """

    let expected =
      """
      let result =
        firstObj.someOptionalReturningFunc(foo: arg)
        ?? (someOtherObj as SomeUsefulType).someGetterFunc()

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 60)
  }
}
