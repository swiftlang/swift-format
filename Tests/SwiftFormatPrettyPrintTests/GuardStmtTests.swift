public class GuardStmtTests: PrettyPrintTestCase {
  public func testGuardStatement() {
    let input =
      """
      guard var1 > var2 else {
        let a = 23
        var b = "abc"
      }
      guard var1, var2 > var3 else {
        let a = 23
        var b = "abc"
      }
      guard let var1 = someFunction(), let var2 = myFun() else {
        let a = 23
        var b = "abc"
      }
      guard let var1 = someFunction(), let var2 = myLongFunction() else {
        let a = 23
        var b = "abc"
      }
      """

    let expected =
      """
      guard var1 > var2 else {
        let a = 23
        var b = "abc"
      }
      guard var1, var2 > var3 else {
        let a = 23
        var b = "abc"
      }
      guard let var1 = someFunction(),
        let var2 = myFun()
      else {
        let a = 23
        var b = "abc"
      }
      guard let var1 = someFunction(),
        let var2 = myLongFunction()
      else {
        let a = 23
        var b = "abc"
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 35)
  }

  public func testGuardWithFuncCall() {
    let input =
      """
      guard let myvar = myClass.itsFunc(first: .someStuff, second: .moreStuff).first else {
        // do stuff
      }
      guard let myvar1 = myClass.itsFunc(first: .someStuff, second: .moreStuff).first,
      let myvar2 = myClass.diffFunc(first: .someStuff, second: .moreStuff).first else {
        // do stuff
      }
      """

    let expected =
      """
      guard
        let myvar = myClass.itsFunc(
          first: .someStuff,
          second: .moreStuff).first
      else {
        // do stuff
      }
      guard
        let myvar1 = myClass.itsFunc(
          first: .someStuff,
          second: .moreStuff).first,
        let myvar2 = myClass.diffFunc(
          first: .someStuff,
          second: .moreStuff).first
      else {
        // do stuff
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 35)
  }

  public func testOpenBraceIsGluedToElseKeyword() {
    let input =
      """
      guard let foo = something,
        let bar = somethingElse else
      {
        body()
      }
      """

    let expected =
      """
      guard let foo = something,
        let bar = somethingElse
      else {
        body()
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 60)
  }

  public func testContinuationLineBreaking() {
    let input =
      """
      guard let someObject = object as? Int,
        let anotherCastedObject = object as? SomeOtherSlightlyLongerType else {
        return nil
      }
      guard let someObject = object as? SomeLongLineBreakingType,
        let anotherCastedObject = object as? SomeOtherSlightlyLongerType else {
        return nil
      }
      guard let someCastedObject = someFunc(foo, bar, baz, quxxe, far, fab, faz),
        let anotherCastedObject = object as? SomeOtherSlightlyLongerType else {
        return nil
      }
      guard let object1 = fetchingFunc(foo), let object2 = fetchingFunc(bar), let object3 = fetchingFunc(baz) else {
        return nil
      }
      """

    let expected =
      """
      guard let someObject = object as? Int,
        let anotherCastedObject = object
          as? SomeOtherSlightlyLongerType
      else {
        return nil
      }
      guard
        let someObject = object
          as? SomeLongLineBreakingType,
        let anotherCastedObject = object
          as? SomeOtherSlightlyLongerType
      else {
        return nil
      }
      guard
        let someCastedObject = someFunc(
          foo, bar, baz, quxxe, far, fab, faz),
        let anotherCastedObject = object
          as? SomeOtherSlightlyLongerType
      else {
        return nil
      }
      guard let object1 = fetchingFunc(foo),
        let object2 = fetchingFunc(bar),
        let object3 = fetchingFunc(baz)
      else {
        return nil
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 40)
  }

  public func testOptionalBindingConditions() {
    let input =
      """
      guard let someObject: Foo = object as? Int else {
        return nil
      }
      guard let someObject: (foo: Foo, bar: SomeVeryLongTypeNameThatBreaks, baz: Baz) = foo(a, b, c, d) else { return nil }
      """

    let expected =
      """
      guard
        let someObject: Foo = object as? Int
      else {
        return nil
      }
      guard
        let someObject:
          (
            foo: Foo,
            bar:
              SomeVeryLongTypeNameThatBreaks,
            baz: Baz
          ) = foo(a, b, c, d)
      else { return nil }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 40)
  }
}
