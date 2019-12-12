import SwiftFormatConfiguration

public class FunctionDeclTests: PrettyPrintTestCase {

  public func testBasicFunctionDeclarations_noPackArguments() {
    let input =
      """
      func myFun(var1: Int, var2: Double) {
        print("Hello World")
        let a = 23
      }
      func reallyLongName(var1: Int, var2: Double, var3: Bool) {
        print("Hello World")
        let a = 23
      }
      func myFun() {
        let a = 23
      }
      func myFun() { let a = "AAAA BBBB CCCC DDDD EEEE FFFF" }
      """

    let expected =
      """
      func myFun(var1: Int, var2: Double) {
        print("Hello World")
        let a = 23
      }
      func reallyLongName(
        var1: Int,
        var2: Double,
        var3: Bool
      ) {
        print("Hello World")
        let a = 23
      }
      func myFun() {
        let a = 23
      }
      func myFun() {
        let a = "AAAA BBBB CCCC DDDD EEEE FFFF"
      }

      """

    var config = Configuration()
    config.lineBreakBeforeEachArgument = true
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 50, configuration: config)
  }

  public func testBasicFunctionDeclarations_packArguments() {
    let input =
      """
      func myFun(var1: Int, var2: Double) {
        print("Hello World")
        let a = 23
      }
      func reallyLongName(var1: Int, var2: Double, var3: Bool) {
        print("Hello World")
        let a = 23
      }
      func myFun() {
        let a = 23
      }
      func myFun() { let a = "AAAA BBBB CCCC DDDD EEEE FFFF" }
      """

    let expected =
      """
      func myFun(var1: Int, var2: Double) {
        print("Hello World")
        let a = 23
      }
      func reallyLongName(
        var1: Int, var2: Double, var3: Bool
      ) {
        print("Hello World")
        let a = 23
      }
      func myFun() {
        let a = 23
      }
      func myFun() {
        let a = "AAAA BBBB CCCC DDDD EEEE FFFF"
      }

      """

    var config = Configuration()
    config.lineBreakBeforeEachArgument = false
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 50, configuration: config)
  }

  public func testFunctionDeclReturns() {
    // TODO: The tuple return case needs a lot of work.
    let input =
      """
      func myFun(var1: Int, var2: Double) -> Double {
        print("Hello World")
        return 1.0
      }
      func reallyLongName(var1: Int, var2: Double, var3: Bool) -> Double {
        print("Hello World")
        return 1.0
      }
      func tupleFunc() throws -> (one: Int, two: Double, three: Bool, four: String) {
        return (one: 1, two: 2.0, three: true, four: "four")
      }
      """

    let expected =
      """
      func myFun(var1: Int, var2: Double) -> Double {
        print("Hello World")
        return 1.0
      }
      func reallyLongName(
        var1: Int, var2: Double, var3: Bool
      ) -> Double {
        print("Hello World")
        return 1.0
      }
      func tupleFunc() throws -> (
        one: Int, two: Double, three: Bool, four: String
      ) {
        return (
          one: 1, two: 2.0, three: true, four: "four"
        )
      }

      """

    var config = Configuration()
    config.lineBreakBeforeEachArgument = false
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 50, configuration: config)
  }

  public func testFunctionDeclThrows() {
    let input =
      """
      func myFun(var1: Int) throws -> Double {
        print("Hello World")
        if badCondition {
          throw Error
        }
        return 1.0
      }
      func reallyLongName(var1: Int, var2: Double, var3: Bool) throws -> Double {
        print("Hello World")
        if badCondition {
          throw Error
        }
        return 1.0
      }
      """

    let expected =
      """
      func myFun(var1: Int) throws -> Double {
        print("Hello World")
        if badCondition {
          throw Error
        }
        return 1.0
      }
      func reallyLongName(
        var1: Int, var2: Double, var3: Bool
      ) throws -> Double {
        print("Hello World")
        if badCondition {
          throw Error
        }
        return 1.0
      }

      """

    var config = Configuration()
    config.lineBreakBeforeEachArgument = false
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 50, configuration: config)
  }

  public func testFunctionGenericParameters_noPackArguments() {
    let input =
      """
      func myFun<S, T>(var1: S, var2: T) {
        let a = 123
        print("Hello World")
      }

      func myFun<S: T & U>(var1: S) {
        // do stuff
      }

      func longerNameFun<ReallyLongTypeName: Conform, TypeName>(var1: ReallyLongTypeName, var2: TypeName) {
        let a = 123
        let b = 456
      }
      """

    let expected =
      """
      func myFun<S, T>(var1: S, var2: T) {
        let a = 123
        print("Hello World")
      }

      func myFun<S: T & U>(var1: S) {
        // do stuff
      }

      func longerNameFun<
        ReallyLongTypeName: Conform,
        TypeName
      >(
        var1: ReallyLongTypeName,
        var2: TypeName
      ) {
        let a = 123
        let b = 456
      }

      """

    var config = Configuration()
    config.lineBreakBeforeEachArgument = true
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 40, configuration: config)
  }

  public func testFunctionGenericParameters_packArguments() {
    let input =
      """
      func myFun<S, T>(var1: S, var2: T) {
        let a = 123
        print("Hello World")
      }

      func myFun<S: T & U>(var1: S) {
        // do stuff
      }

      func longerNameFun<ReallyLongTypeName: Conform, TypeName>(var1: ReallyLongTypeName, var2: TypeName) {
        let a = 123
        let b = 456
      }
      """

    let expected =
      """
      func myFun<S, T>(var1: S, var2: T) {
        let a = 123
        print("Hello World")
      }

      func myFun<S: T & U>(var1: S) {
        // do stuff
      }

      func longerNameFun<
        ReallyLongTypeName: Conform, TypeName
      >(
        var1: ReallyLongTypeName,
        var2: TypeName
      ) {
        let a = 123
        let b = 456
      }

      """

    var config = Configuration()
    config.lineBreakBeforeEachArgument = false
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 40, configuration: config)
  }

  public func testFunctionWhereClause() {
    let input =
      """
      public func index<Elements: Collection, Element>(
        of element: Element, in collection: Elements
      ) -> Elements.Index? where Elements.Element == Element {
        let a = 123
        let b = "abc"
      }

      public func index<Elements: Collection, Element>(
        of element: Element,
        in collection: Elements
      ) -> Elements.Index? where Elements.Element == Element, Element: Equatable {
        let a = 123
        let b = "abc"
      }

      public func index<Elements: Collection, Element>(
        of element: Element,
        in collection: Elements
      ) -> Elements.Index? where Elements.Element == Element, Element: Equatable, Element: ReallyLongProtocolName {
        let a = 123
        let b = "abc"
      }
      """

    let expected =
      """
      public func index<Elements: Collection, Element>(
        of element: Element, in collection: Elements
      ) -> Elements.Index?
      where Elements.Element == Element {
        let a = 123
        let b = "abc"
      }

      public func index<Elements: Collection, Element>(
        of element: Element,
        in collection: Elements
      ) -> Elements.Index?
      where
        Elements.Element == Element, Element: Equatable
      {
        let a = 123
        let b = "abc"
      }

      public func index<Elements: Collection, Element>(
        of element: Element,
        in collection: Elements
      ) -> Elements.Index?
      where
        Elements.Element == Element, Element: Equatable,
        Element: ReallyLongProtocolName
      {
        let a = 123
        let b = "abc"
      }

      """

    var config = Configuration()
    config.lineBreakBeforeEachArgument = false
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 50, configuration: config)
  }

  public func testFunctionWhereClause_lineBreakBeforeEachGenericRequirement() {
    let input =
    """
      public func index<Elements: Collection, Element>(
        of element: Element, in collection: Elements
      ) -> Elements.Index? where Elements.Element == Element {
        let a = 123
        let b = "abc"
      }

      public func index<Elements: Collection, Element>(
        of element: Element,
        in collection: Elements
      ) -> Elements.Index? where Elements.Element == Element, Element: Equatable {
        let a = 123
        let b = "abc"
      }

      public func index<Elements: Collection, Element>(
        of element: Element,
        in collection: Elements
      ) -> Elements.Index? where Elements.Element == Element, Element: Equatable, Element: ReallyLongProtocolName {
        let a = 123
        let b = "abc"
      }
      """

    let expected =
    """
      public func index<Elements: Collection, Element>(
        of element: Element, in collection: Elements
      ) -> Elements.Index?
      where Elements.Element == Element {
        let a = 123
        let b = "abc"
      }

      public func index<Elements: Collection, Element>(
        of element: Element,
        in collection: Elements
      ) -> Elements.Index?
      where
        Elements.Element == Element,
        Element: Equatable
      {
        let a = 123
        let b = "abc"
      }

      public func index<Elements: Collection, Element>(
        of element: Element,
        in collection: Elements
      ) -> Elements.Index?
      where
        Elements.Element == Element,
        Element: Equatable,
        Element: ReallyLongProtocolName
      {
        let a = 123
        let b = "abc"
      }

      """

    var config = Configuration()
    config.lineBreakBeforeEachArgument = false
    config.lineBreakBeforeEachGenericRequirement = true
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 50, configuration: config)
  }

  public func testFunctionWithDefer() {
    let input =
      """
      func myFun() {
        defer { print("Hello world") }
        return 0
      }
      func myFun() {
        defer { print("Hello world with longer message") }
        return 0
      }
      func myFun() {
        defer {
          print("First message")
          print("Second message")
        }
        return 0
      }
      """


    let expected =
      """
      func myFun() {
        defer { print("Hello world") }
        return 0
      }
      func myFun() {
        defer {
          print("Hello world with longer message")
        }
        return 0
      }
      func myFun() {
        defer {
          print("First message")
          print("Second message")
        }
        return 0
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 48)
  }

  public func testFunctionAttributes() {
    let input =
      """
      @discardableResult public func MyFun() {
        let a = 123
        let b = "abc"
      }
      @discardableResult @objc public func MyFun() {
        let a = 123
        let b = "abc"
      }
      @discardableResult @objc @inlinable public func MyFun() {
        let a = 123
        let b = "abc"
      }
      @discardableResult
      @available(swift 4.0)
      public func MyFun() {
        let a = 123
        let b = "abc"
      }
      """

    let expected =
      """
      @discardableResult public func MyFun() {
        let a = 123
        let b = "abc"
      }
      @discardableResult @objc public func MyFun() {
        let a = 123
        let b = "abc"
      }
      @discardableResult @objc @inlinable
      public func MyFun() {
        let a = 123
        let b = "abc"
      }
      @discardableResult
      @available(swift 4.0)
      public func MyFun() {
        let a = 123
        let b = "abc"
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 50)
  }

  public func testBodilessFunctionDecl() {
    let input =
      """
      func myFun()

      func myFun(arg1: Int)

      func myFun() -> Int

      func myFun<T>(arg1: Int)

      func myFun<T>(arg1: Int) where T: S
      """

    let expected =
      """
      func myFun()

      func myFun(arg1: Int)

      func myFun() -> Int

      func myFun<T>(arg1: Int)

      func myFun<T>(arg1: Int) where T: S

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 50)
  }

  public func testFunctionFullWrap() {
    let input =
    """
    @discardableResult @objc
    public func index<Elements: Collection, Element>(of element: Element, in collection: Elements) -> Elements.Index? where Element: Foo, Element: Bar, Elements.Element == Element  {
      let a = 123
      let b = "abc"
    }
    """

    let expected =
    """
    @discardableResult @objc
    public func index<
      Elements: Collection,
      Element
    >(
      of element: Element,
      in collection: Elements
    ) -> Elements.Index?
    where
      Element: Foo, Element: Bar,
      Elements.Element == Element
    {
      let a = 123
      let b = "abc"
    }

    """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 30)
  }

  public func testFunctionFullWrap_lineBreakBeforeEachGenericRequirement() {
    let input =
    """
    @discardableResult @objc
    public func index<Elements: Collection, Element>(of element: Element, in collection: Elements) -> Elements.Index? where Element: Foo, Element: Bar, Elements.Element == Element  {
      let a = 123
      let b = "abc"
    }
    """

    let expected =
    """
    @discardableResult @objc
    public func index<
      Elements: Collection,
      Element
    >(
      of element: Element,
      in collection: Elements
    ) -> Elements.Index?
    where
      Element: Foo,
      Element: Bar,
      Elements.Element == Element
    {
      let a = 123
      let b = "abc"
    }

    """

    var config = Configuration()
    config.lineBreakBeforeEachGenericRequirement = true
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 30, configuration: config)
  }

  public func testEmptyFunction() {
    let input = "func foo() {}"
    assertPrettyPrintEqual(input: input, expected: input + "\n", linelength: 50)
    
    let wrapped = """
      func foo() {
      }

      """
    assertPrettyPrintEqual(input: input, expected: wrapped, linelength: 12)
  }

  public func testOperatorOverloads() {
    let input =
      """
      struct X {
        static func + (lhs: X, rhs: X) -> X {}
        static func +(lhs: X, rhs: X) -> X {}
        static func ⊕ (lhs: X, rhs: X) -> X {}
        static func ⊕(lhs: X, rhs: X) -> X {}
        static func * <T>(lhs: X, rhs: T) -> T {}
        static func *<T>(lhs: X, rhs: T) -> T {}
      }
      """

    let expected =
      """
      struct X {
        static func + (
          lhs: X, rhs: X
        ) -> X {}
        static func + (
          lhs: X, rhs: X
        ) -> X {}
        static func ⊕ (
          lhs: X, rhs: X
        ) -> X {}
        static func ⊕ (
          lhs: X, rhs: X
        ) -> X {}
        static func * <T>(
          lhs: X, rhs: T
        ) -> T {}
        static func * <T>(
          lhs: X, rhs: T
        ) -> T {}
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 20)
  }

  public func testBreaksBeforeOrInsideOutput() {
    let input =
      """
      func name<R>(_ x: Int) throws -> R

      func name<R>(_ x: Int) throws -> R {
        statement
        statement
      }
      """

    var expected =
      """
      func name<R>(_ x: Int)
        throws -> R

      func name<R>(_ x: Int)
        throws -> R
      {
        statement
        statement
      }

      """
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 23)

    expected =
    """
      func name<R>(_ x: Int) throws
        -> R

      func name<R>(_ x: Int) throws
        -> R
      {
        statement
        statement
      }

      """
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 30)
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 33)
  }

  public func testBreaksBeforeOrInsideOutput_prioritizingKeepingOutputTogether() {
    let input =
    """
      func name<R>(_ x: Int) throws -> R

      func name<R>(_ x: Int) throws -> R {
        statement
        statement
      }
      """

    var expected =
    """
      func name<R>(
        _ x: Int
      ) throws -> R

      func name<R>(
        _ x: Int
      ) throws -> R {
        statement
        statement
      }

      """
    var config = Configuration()
    config.prioritizeKeepingFunctionOutputTogether = true
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 23, configuration: config)

    expected =
    """
    func name<R>(
      _ x: Int
    ) throws -> R

    func name<R>(
      _ x: Int
    ) throws -> R {
      statement
      statement
    }

    """
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 30, configuration: config)
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 33, configuration: config)
  }

  public func testBreaksBeforeOrInsideOutputWithAttributes() {
    let input =
      """
      @objc @discardableResult
      func name<R>(_ x: Int) throws -> R

      @objc @discardableResult
      func name<R>(_ x: Int) throws -> R {
        statement
        statement
      }
      """

    let expected =
      """
      @objc
      @discardableResult
      func name<R>(_ x: Int)
        throws -> R

      @objc
      @discardableResult
      func name<R>(_ x: Int)
        throws -> R
      {
        statement
        statement
      }

      """
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 23)
  }

  public func testBreaksBeforeOrInsideOutputWithAttributes_prioritizingKeepingOutputTogether() {
    let input =
    """
      @objc @discardableResult
      func name<R>(_ x: Int) throws -> R

      @objc @discardableResult
      func name<R>(_ x: Int) throws -> R {
        statement
        statement
      }
      """

    let expected =
    """
      @objc
      @discardableResult
      func name<R>(
        _ x: Int
      ) throws -> R

      @objc
      @discardableResult
      func name<R>(
        _ x: Int
      ) throws -> R {
        statement
        statement
      }

      """
    var config = Configuration()
    config.prioritizeKeepingFunctionOutputTogether = true
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 23, configuration: config)
  }

  public func testBreaksBeforeOrInsideOutputWithWhereClause() {
    var input =
      """
      func name<R>(_ x: Int) throws -> R where Foo == Bar

      func name<R>(_ x: Int) throws -> R where Foo == Bar {
        statement
        statement
      }
      """

    var expected =
      """
      func name<R>(_ x: Int)
        throws -> R
      where Foo == Bar

      func name<R>(_ x: Int)
        throws -> R
      where Foo == Bar {
        statement
        statement
      }

      """
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 23)

    input =
      """
      func name<R>(_ x: Int) throws -> R where Fooooooo == Barrrrr

      func name<R>(_ x: Int) throws -> R where Fooooooo == Barrrrr {
        statement
        statement
      }
      """

    expected =
      """
      func name<R>(_ x: Int)
        throws -> R
      where
        Fooooooo == Barrrrr

      func name<R>(_ x: Int)
        throws -> R
      where
        Fooooooo == Barrrrr
      {
        statement
        statement
      }

      """
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 23)
  }

  public func testBreaksBeforeOrInsideOutputWithWhereClause_prioritizingKeepingOutputTogether() {
    var input =
    """
      func name<R>(_ x: Int) throws -> R where Foo == Bar

      func name<R>(_ x: Int) throws -> R where Foo == Bar {
        statement
        statement
      }
      """

    var expected =
    """
      func name<R>(
        _ x: Int
      ) throws -> R
      where Foo == Bar

      func name<R>(
        _ x: Int
      ) throws -> R
      where Foo == Bar {
        statement
        statement
      }

      """
    var config = Configuration()
    config.prioritizeKeepingFunctionOutputTogether = true
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 23, configuration: config)

    input =
    """
    func name<R>(_ x: Int) throws -> R where Fooooooo == Barrrrr

    func name<R>(_ x: Int) throws -> R where Fooooooo == Barrrrr {
    statement
    statement
    }
    """

    expected =
    """
    func name<R>(
      _ x: Int
    ) throws -> R
    where
      Fooooooo == Barrrrr

    func name<R>(
      _ x: Int
    ) throws -> R
    where
      Fooooooo == Barrrrr
    {
      statement
      statement
    }

    """
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 23, configuration: config)
  }

  public func testAttributedTypes() {
    let input =
      """
      func MyFun(myvar: @escaping MyType)

      func MyFun(myvar1: Int, myvar2: Double, myvar3: @escaping MyType) -> Bool {
        // do stuff
        return false
      }
      """

    let expected =
      """
      func MyFun(myvar: @escaping MyType)

      func MyFun(
        myvar1: Int, myvar2: Double,
        myvar3: @escaping MyType
      ) -> Bool {
        // do stuff
        return false
      }

      """

    var config = Configuration()
    config.lineBreakBeforeEachArgument = false
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 35, configuration: config)
  }

  public func testRemovesLineBreakBeforeOpenBraceUnlessAbsolutelyNecessary() {
    let input =
      """
      func foo(bar: Int)
      {
        baz()
      }

      func foo(longer: Int)
      {
        baz()
      }
      """

    let expected =
      """
      func foo(bar: Int) {
        baz()
      }

      func foo(longer: Int)
      {
        baz()
      }

      """
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 21)
  }

  func testDoesNotCollapseFunctionParameterAttributes() {
    let input =
    """
    func foo<Content: View>(@ViewBuilder bar: () -> View) {
      bar()
    }

    """

    assertPrettyPrintEqual(input: input, expected: input, linelength: 60)
  }

  func testDoesNotCollapseStackedFunctionParameterAttributes() {
    let input =
    """
    func foo<Content: View>(@FakeAttr @ViewBuilder bar: () -> View) {
      bar()
    }

    """

    assertPrettyPrintEqual(input: input, expected: input, linelength: 80)
  }

  func testDoesNotBreakInsideEmptyParens() {
    // If the function name is so long that the parentheses of a no-argument parameter list would
    // be pushed past the margin, don't break inside them.
    let input =
      """
      func fooBarBaz() {}

      """

    let expected =
      """
      func
        fooBarBaz()
      {}

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 14)
  }
}
