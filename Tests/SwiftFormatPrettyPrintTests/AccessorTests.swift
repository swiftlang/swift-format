public class AccessorTests: PrettyPrintTestCase {
  public func testBasicAccessors() {
    let input =
      """
      struct MyStruct {
        var memberValue: Int
        var someValue: Int { get { return memberValue + 2 } set(newValue) { memberValue = newValue } }
      }
      struct MyStruct {
        var memberValue: Int
        var someValue: Int { @objc get { return memberValue + 2 } @objc(isEnabled) set(newValue) { memberValue = newValue } }
      }
      struct MyStruct {
        var memberValue: Int
        var memberValue2: Int
        var someValue: Int {
          get {
            let A = 123
            return A
          }
          set(newValue) {
            memberValue = newValue && otherValue
            memberValue2 = newValue / 2 && andableValue
          }
        }
      }
      struct MyStruct {
        var memberValue: Int
        var SomeValue: Int { return 123 }
        var AnotherValue: Double {
          let out = 1.23
          return out
        }
      }
      """

    let expected =
      """
      struct MyStruct {
        var memberValue: Int
        var someValue: Int {
          get { return memberValue + 2 }
          set(newValue) { memberValue = newValue }
        }
      }
      struct MyStruct {
        var memberValue: Int
        var someValue: Int {
          @objc get { return memberValue + 2 }
          @objc(isEnabled) set(newValue) {
            memberValue = newValue
          }
        }
      }
      struct MyStruct {
        var memberValue: Int
        var memberValue2: Int
        var someValue: Int {
          get {
            let A = 123
            return A
          }
          set(newValue) {
            memberValue = newValue && otherValue
            memberValue2 =
              newValue / 2 && andableValue
          }
        }
      }
      struct MyStruct {
        var memberValue: Int
        var SomeValue: Int { return 123 }
        var AnotherValue: Double {
          let out = 1.23
          return out
        }
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 45)
  }

  public func testEmptyAccessorList() {
    // The comment inside the struct prevents it from *also* being collapsed onto a single line.
    let input = """
      struct Foo {
        //
        var x: Int {}
      }
      """
    assertPrettyPrintEqual(input: input, expected: input + "\n", linelength: 50)

    let wrapped = """
      struct Foo {
        //
        var x: Int {
        }
      }

      """
    assertPrettyPrintEqual(input: input, expected: wrapped, linelength: 14)
  }

  public func testEmptyAccessorBody() {
    // The comment inside the struct prevents it from *also* being collapsed onto a single line.
    let input = """
      struct Foo {
        //
        var x: Int { set(longNewValueName) {} }
      }
      """
    assertPrettyPrintEqual(input: input, expected: input + "\n", linelength: 50)

    let wrapped = """
      struct Foo {
        //
        var x: Int {
          set(longNewValueName) {
          }
        }
      }

      """
    assertPrettyPrintEqual(input: input, expected: wrapped, linelength: 27)
  }

  public func testEmptyAccessorBodyWithComment() {
    let input = """
      struct Foo {
        //
        var x: Int {
          get {
            // comment
          }
        }
      }
      """
    assertPrettyPrintEqual(input: input, expected: input + "\n", linelength: 50)
  }

  public func testSetModifier() {
    let input =
      """
      fileprivate(set) var somevar = 0
      struct MyStruct {
        private(set) var myvar = 0
        internal(set) var anothervar = 0
      }
      """

    assertPrettyPrintEqual(input: input, expected: input + "\n", linelength: 50)
  }

  public func testDefaultValueAndAccessor() {
    let input =
      """
      var property = defaultValue {
        didSet {
          foo()
          bar()
        }
      }
      """

    assertPrettyPrintEqual(input: input, expected: input + "\n", linelength: 80)

    let expected20 =
      """
      var property =
        defaultValue
      {
        didSet {
          foo()
          bar()
        }
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected20, linelength: 20)
  }

  public func testTypeDefaultValueAndAccessor() {
    let input =
      """
      var property: SomeType = defaultValue {
        didSet {
          foo()
          bar()
        }
      }
      """

    assertPrettyPrintEqual(input: input, expected: input + "\n", linelength: 80)

    let expected25 =
      """
      var property: SomeType =
        defaultValue
      {
        didSet {
          foo()
          bar()
        }
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected25, linelength: 25)

    let expected20 =
      """
      var property:
        SomeType =
          defaultValue
      {
        didSet {
          foo()
          bar()
        }
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected20, linelength: 20)
  }

  public func testMultipleBindingsWithAccessors() {
    // NOTE: These examples are not actually valid Swift! The syntax parser will allow a variable
    // declaration that has multiple comma-separated bindings that have accessors, but the compiler
    // rejects these at a later stage ("error: 'var' declarations with multiple variables cannot
    // have explicit getters/setters"). But since the parser allows it, we make an attempt to format
    // them correctly, rather than bail out and potentially leave the source code in a worse state
    // than the original.

    let input =
      """
      var property1: SomeType = defaultValue {
        didSet {
          foo()
          bar()
        }
      }, property2: SomeType = defaultValue {
        didSet {
          foo()
          bar()
        }
      }
      """

    let expected =
      """
      var
        property1: SomeType = defaultValue {
          didSet {
            foo()
            bar()
          }
        },
        property2: SomeType = defaultValue {
          didSet {
            foo()
            bar()
          }
        }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 80)

    let expected20 =
      """
      var
        property1:
          SomeType =
            defaultValue
        {
          didSet {
            foo()
            bar()
          }
        },
        property2:
          SomeType =
            defaultValue
        {
          didSet {
            foo()
            bar()
          }
        }

      """

    assertPrettyPrintEqual(input: input, expected: expected20, linelength: 20)
  }
}
