import SwiftFormatConfiguration

public class SubscriptDeclTests: PrettyPrintTestCase {

  public func testBasicSubscriptDeclarations() {
    let input =
      """
      struct MyStruct {
        subscript(index: Int) -> Int {
          return self.values[index]
        }
        subscript(row: Int, col: Int) -> Int {
          return self.values[row][col]
        }
        subscript(index: Int) -> Int {
          get { return self.value[index] }
          set(newValue) { self.value[index] = newValue } 
        }
      }
      """

    let expected =
      """
      struct MyStruct {
        subscript(index: Int) -> Int {
          return self.values[index]
        }
        subscript(row: Int, col: Int) -> Int {
          return self.values[row][col]
        }
        subscript(index: Int) -> Int {
          get { return self.value[index] }
          set(newValue) { self.value[index] = newValue }
        }
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 50)
  }

  public func testSubscriptGenerics_noPackArguments() {
    let input =
      """
      struct MyStruct {
        subscript<T>(index: T) -> Double {
          return 1.23
        }
        subscript<S, T>(row: S, col: T) -> Double {
          return self.values[row][col]
        }
        subscript<LongTypeName1, LongTypeName2, LongTypeName3>(var1: LongTypeName1, var2: LongTypeName2, var3: LongTypeName3) -> Int {
          return self.values[var1][var2][var3]
        }
      }
      """

    let expected =
      """
      struct MyStruct {
        subscript<T>(index: T) -> Double {
          return 1.23
        }
        subscript<S, T>(row: S, col: T) -> Double {
          return self.values[row][col]
        }
        subscript<
          LongTypeName1,
          LongTypeName2,
          LongTypeName3
        >(
          var1: LongTypeName1,
          var2: LongTypeName2,
          var3: LongTypeName3
        ) -> Int {
          return self.values[var1][var2][var3]
        }
      }

      """

    let config = Configuration()
    config.lineBreakBeforeEachArgument = true
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 50, configuration: config)
  }

  public func testSubscriptGenerics_packArguments() {
    let input =
      """
      struct MyStruct {
        subscript<T>(index: T) -> Double {
          return 1.23
        }
        subscript<S, T>(row: S, col: T) -> Double {
          return self.values[row][col]
        }
        subscript<LongTypeName1, LongTypeName2, LongTypeName3>(var1: LongTypeName1, var2: LongTypeName2, var3: LongTypeName3) -> Int {
          return self.values[var1][var2][var3]
        }
      }
      """

    let expected =
      """
      struct MyStruct {
        subscript<T>(index: T) -> Double {
          return 1.23
        }
        subscript<S, T>(row: S, col: T) -> Double {
          return self.values[row][col]
        }
        subscript<
          LongTypeName1, LongTypeName2, LongTypeName3
        >(
          var1: LongTypeName1, var2: LongTypeName2,
          var3: LongTypeName3
        ) -> Int {
          return self.values[var1][var2][var3]
        }
      }

      """

    let config = Configuration()
    config.lineBreakBeforeEachArgument = false
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 50, configuration: config)
  }

  public func testSubscriptGenericWhere() {
    let input =
      """
      struct MyStruct {
        subscript<Elements: Collection, Element>(var1: Element, var2: Elements) -> Double where Elements.Element == Element {
          return 1.23
        }
        subscript<Elements: Collection, Element>(var1: Element, var2: Elements) -> Double where Elements.Element == Element, Element: Equatable {
          return 1.23
        }
      }
      """

    let expected =
      """
      struct MyStruct {
        subscript<Elements: Collection, Element>(
          var1: Element, var2: Elements
        ) -> Double where Elements.Element == Element {
          return 1.23
        }
        subscript<Elements: Collection, Element>(
          var1: Element, var2: Elements
        ) -> Double
        where Elements.Element == Element,
          Element: Equatable
        {
          return 1.23
        }
      }

      """

    let config = Configuration()
    config.lineBreakBeforeEachArgument = false
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 50, configuration: config)
  }

  public func testSubscriptAttributes() {
    let input =
      """
      struct MyStruct {
        @discardableResult subscript(index: Int) -> Int {
          let a = 123
          return a
        }
        @discardableResult @objc subscript(index: Int) -> Int {
          let a = 123
          return a
        }
        @discardableResult @objc @inlinable subscript(index: Int) -> Int {
          let a = 123
          return a
        }
        @discardableResult @objc
        @inlinable
        @available(swift 4.0)
        subscript(index: Int) -> Int {
          let a = 123
          return a
        }
      }
      """

    let expected =
      """
      struct MyStruct {
        @discardableResult subscript(index: Int) -> Int {
          let a = 123
          return a
        }
        @discardableResult @objc subscript(index: Int) -> Int {
          let a = 123
          return a
        }
        @discardableResult @objc @inlinable subscript(index: Int) -> Int {
          let a = 123
          return a
        }
        @discardableResult @objc
        @inlinable
        @available(swift 4.0)
        subscript(index: Int) -> Int {
          let a = 123
          return a
        }
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 70)
  }

  public func testSubscriptFullWrap() {
    let input =
    """
    struct MyStruct {
      @discardableResult @objc
      subscript<ManyElements: Collection, Element>(var1: Element, var2: ManyElements) -> ManyElements.Index? where ManyElements.Element == Element, Element: Equatable {
        get {
          let out = vals[var1][var2]
          return out
        }
        set(newValue) {
          let tmp = compute(newValue)
          vals[var1][var2] = tmp
        }
      }
    }
    """

    let expected =
    """
    struct MyStruct {
      @discardableResult @objc
      subscript<
        ManyElements: Collection,
        Element
      >(
        var1: Element,
        var2: ManyElements
      ) -> ManyElements.Index?
      where
        ManyElements.Element
          == Element,
        Element: Equatable
      {
        get {
          let out = vals[var1][var2]
          return out
        }
        set(newValue) {
          let tmp = compute(newValue)
          vals[var1][var2] = tmp
        }
      }
    }

    """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 34)
  }

  public func testEmptySubscript() {
    // The comment inside the struct prevents it from *also* being collapsed onto a single line.
    let input = """
      struct X {
        //
        subscript(i: Int) -> Int {}
      }
      """
    assertPrettyPrintEqual(input: input, expected: input + "\n", linelength: 50)
    
    let wrapped = """
      struct X {
        //
        subscript(i: Int) -> Int {
        }
      }

      """
    assertPrettyPrintEqual(input: input, expected: wrapped, linelength: 28)
  }
}
