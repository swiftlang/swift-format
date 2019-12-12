import SwiftFormatConfiguration

public class IfStmtTests: PrettyPrintTestCase {
  public func testIfStatement() {
    let input =
      """
      if var1 > var2 {
        let a = 23
        var b = "abc"
      }

      if var1 > var2 {
        let a = 23
        var b = "abc"
        if var3 {
          var c = 123
        }
      }

      if a123456 > b123456 {
        let a = 23
        var b = "abc"
      }

      if a123456789 > b123456 {
        let a = 23
        var b = "abc"
      }
      """

    let expected =
      """
      if var1 > var2 {
        let a = 23
        var b = "abc"
      }

      if var1 > var2 {
        let a = 23
        var b = "abc"
        if var3 {
          var c = 123
        }
      }

      if a123456 > b123456
      {
        let a = 23
        var b = "abc"
      }

      if a123456789
        > b123456
      {
        let a = 23
        var b = "abc"
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 20)
  }

  public func testIfElseStatement_noBreakBeforeElse() {
    let input =
      """
      if var1 < var2 {
        let a = 23
      }
      else if d < e {
        var b = 123
      }
      else {
        var c = 456
      }

      if var1 < var2 {
        let a = 23
      }
      else if var3 < var4 {
        var b = 123
        var c = 456
      }
      """

    let expected =
      """
      if var1 < var2 {
        let a = 23
      } else if d < e {
        var b = 123
      } else {
        var c = 456
      }

      if var1 < var2 {
        let a = 23
      } else if var3 < var4 {
        var b = 123
        var c = 456
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 23)
  }

  public func testIfElseStatement_breakBeforeElse() {
    let input =
      """
      if var1 < var2 {
        let a = 23
      } else if d < e {
        var b = 123
      } else {
        var c = 456
      }

      if var1 < var2 {
        let a = 23
      } else if var3 < var4 {
        var b = 123
        var c = 456
      }
      """

    let expected =
      """
      if var1 < var2 {
        let a = 23
      }
      else if d < e {
        var b = 123
      }
      else {
        var c = 456
      }

      if var1 < var2 {
        let a = 23
      }
      else if var3 < var4
      {
        var b = 123
        var c = 456
      }

      """

    var config = Configuration()
    config.lineBreakBeforeControlFlowKeywords = true
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 20, configuration: config)
  }

  public func testMatchingPatternConditions() {
    let input =
      """
      if case .foo = bar {
        let a = 123
        var b = "abc"
      }
      if case .reallyLongCaseName = reallyLongVariableName {
        let a = 123
        var b = "abc"
      }
      """

    let expected =
      """
      if case .foo = bar {
        let a = 123
        var b = "abc"
      }
      if case .reallyLongCaseName =
        reallyLongVariableName
      {
        let a = 123
        var b = "abc"
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 30)
  }

  public func testIfLetStatements() {
    let input =
      """
      if let SomeReallyLongVar = Some.More.Stuff(), let a = myfunc() {
        // do stuff
      }

      if someCondition
        && someFunctionCall(arguments) {
        // do stuff
      }
      """

    let expected =
      """
      if let SomeReallyLongVar = Some.More
        .Stuff(), let a = myfunc()
      {
        // do stuff
      }

      if someCondition
        && someFunctionCall(arguments)
      {
        // do stuff
      }

      """

    // The line length ends on the last paren of .Stuff()
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 44)
  }

  public func testContinuationLineBreakIndentation() {
    let input =
      """
      if let someObject = object as? Int,
        let anotherCastedObject = object as? SomeOtherSlightlyLongerType,
        let thirdObject = object as? Int {
        return nil
      }
      if let someObject = object as? SomeLongLineBreakingType,
        let anotherCastedObject = object as? SomeOtherSlightlyLongerType {
        return nil
      }
      if let someCastedObject = someFunc(foo, bar, baz, quxxe, far, fab, faz),
        let anotherCastedObject = object as? SomeOtherSlightlyLongerType {
        return nil
      }
      if let object1 = fetchingFunc(foo), let object2 = fetchingFunc(bar), let object3 = fetchingFunc(baz) {
        return nil
      }
      """

    let expected =
      """
      if let someObject = object as? Int,
        let anotherCastedObject = object
          as? SomeOtherSlightlyLongerType,
        let thirdObject = object as? Int
      {
        return nil
      }
      if let someObject = object
        as? SomeLongLineBreakingType,
        let anotherCastedObject = object
          as? SomeOtherSlightlyLongerType
      {
        return nil
      }
      if let someCastedObject = someFunc(
        foo, bar, baz, quxxe, far, fab, faz),
        let anotherCastedObject = object
          as? SomeOtherSlightlyLongerType
      {
        return nil
      }
      if let object1 = fetchingFunc(foo),
        let object2 = fetchingFunc(bar),
        let object3 = fetchingFunc(baz)
      {
        return nil
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 50)
  }

  public func testHangingOpenBreakIsTreatedLikeContinuation() {
    let input =
      """
      if let foo = someFunction(someArgumentLabel: someValue) {
        // do stuff
      }
      """

    let expected =
      """
      if let foo = someFunction(
        someArgumentLabel: someValue)
      {
        // do stuff
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 50)
  }

  public func testConditionExpressionOperatorGrouping() {
    let input =
      """
      if someObj is SuperVerboselyNamedType || someObj is AnotherPrettyLongType  || someObjc == "APlainString" || someObj == 4 {
        // do something
      }
      if someVeryLongFirstCondition || aCombination + ofVariousVariables + andOperators - thatBreak * onto % differentLines || anotherPrettyLongCondition || thatBinPacks {
        // do something else
      }
      """

    let expected =
      """
      if someObj is SuperVerboselyNamedType
        || someObj is AnotherPrettyLongType
        || someObjc == "APlainString" || someObj == 4
      {
        // do something
      }
      if someVeryLongFirstCondition
        || aCombination + ofVariousVariables
          + andOperators - thatBreak * onto
          % differentLines
        || anotherPrettyLongCondition || thatBinPacks
      {
        // do something else
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 50)
  }

  public func testConditionExpressionOperatorGroupingMixedWithParentheses() {
    let input =
      """
      if (someObj is SuperVerboselyNamedType || someObj is AnotherPrettyLongType  || someObjc == "APlainString" || someObj == 4) {
        // do something
      }
      if (someVeryLongFirstCondition || (aCombination + ofVariousVariables + andOperators - thatBreak * onto % differentLines) || anotherPrettyLongCondition || thatBinPacks) {
        // do something else
      }
      """

    let expected =
      """
      if (someObj is SuperVerboselyNamedType
        || someObj is AnotherPrettyLongType
        || someObjc == "APlainString" || someObj == 4)
      {
        // do something
      }
      if (someVeryLongFirstCondition
        || (aCombination + ofVariousVariables
          + andOperators - thatBreak * onto
          % differentLines)
        || anotherPrettyLongCondition || thatBinPacks)
      {
        // do something else
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 50)
  }

  public func testOptionalBindingConditions() {
    let input =
      """
      if let someObject: Foo = object as? Int {
        return nil
      }
      if let someObject: (foo: Foo, bar: SomeVeryLongTypeNameThatDefinitelyBreaks, baz: Baz) = foo(a, b, c, d) { return nil }
      """

    let expected =
      """
      if let someObject: Foo = object as? Int
      {
        return nil
      }
      if let someObject:
        (
          foo: Foo,
          bar:
            SomeVeryLongTypeNameThatDefinitelyBreaks,
          baz: Baz
        ) = foo(a, b, c, d)
      { return nil }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 40)
  }
}
