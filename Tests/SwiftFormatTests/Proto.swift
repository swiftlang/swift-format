import SwiftFormat

final class ProtocolDeclTests: PrettyPrintTestCase {
  func testBasicProtocolDeclarations() {
    let input =
      """
      protocol MyProtocol {
        var A: Int { get set }
        var B: Bool { get }
      }
      protocol MyProtocol {
        var VeryLongVariable: Int { get set }
        var B: Bool { get }
      }
      public protocol MyProtocol {
        var A: Int { get set }
        var B: Bool { get }
      }
      public protocol MyLongerProtocol {
        var A: Int { get set }
        var B: Bool { get }
      }
      """

    let expected =
      """
      protocol MyProtocol {
        var A: Int { get set }
        var B: Bool { get }
      }
      protocol MyProtocol {
        var VeryLongVariable: Int {
          get set
        }
        var B: Bool { get }
      }
      public protocol MyProtocol {
        var A: Int { get set }
        var B: Bool { get }
      }
      public protocol
        MyLongerProtocol
      {
        var A: Int { get set }
        var B: Bool { get }
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 30)
  }

  func testProtocolInheritance() {
    let input =
      """
      protocol MyProtocol: ProtoOne {
        var A: Int { get set }
        var B: Bool { get }
      }
      protocol MyProtocol: ProtoOne, ProtoTwo {
        var A: Int { get set }
        var B: Bool { get }
      }
      protocol MyProtocol: ProtoOne, ProtoTwo, ProtoThree {
        var A: Int { get set }
        var B: Bool { get }
      }
      """

    let expected =
      """
      protocol MyProtocol: ProtoOne {
        var A: Int { get set }
        var B: Bool { get }
      }
      protocol MyProtocol: ProtoOne, ProtoTwo {
        var A: Int { get set }
        var B: Bool { get }
      }
      protocol MyProtocol: ProtoOne, ProtoTwo,
        ProtoThree
      {
        var A: Int { get set }
        var B: Bool { get }
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 50)
  }

  func testProtocolAttributes() {
    let input =
      """
      @dynamicMemberLookup public protocol MyProtocol {
        var A: Int { get set }
        var B: Double { get }
      }
      @dynamicMemberLookup @objc public protocol MyProtocol {
        var A: Int { get set }
        var B: Double { get }
      }
      @dynamicMemberLookup @objc @objcMembers public protocol MyProtocol {
        var A: Int { get set }
        var B: Double { get }
      }
      @dynamicMemberLookup
      @available(swift 4.0)
      public protocol MyProtocol {
        var A: Int { get set }
        var B: Double { get }
      }
      """

    let expected =
      """
      @dynamicMemberLookup public protocol MyProtocol {
        var A: Int { get set }
        var B: Double { get }
      }
      @dynamicMemberLookup @objc public protocol MyProtocol {
        var A: Int { get set }
        var B: Double { get }
      }
      @dynamicMemberLookup @objc @objcMembers
      public protocol MyProtocol {
        var A: Int { get set }
        var B: Double { get }
      }
      @dynamicMemberLookup
      @available(swift 4.0)
      public protocol MyProtocol {
        var A: Int { get set }
        var B: Double { get }
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 60)
  }

  func testProtocolWithFunctions() {
    let input =
      """
      protocol MyProtocol {
        func foo(bar: Int) -> Int
        func reallyLongName(reallyLongLabel: Int, anotherLongLabel: Bool) -> Float
        func doAProtoThing(first: Foo, second s: Bar)
        func doAThing(first: Foo) -> ResultType
        func doSomethingElse(firstArg: Foo, second secondArg: Bar, third thirdArg: Baz)
        func doStuff(firstArg: Foo, second second: Bar, third third: Baz) -> Output
      }
      """

    let expected =
      """
      protocol MyProtocol {
        func foo(bar: Int) -> Int
        func reallyLongName(
          reallyLongLabel: Int,
          anotherLongLabel: Bool
        ) -> Float
        func doAProtoThing(
          first: Foo, second s: Bar)
        func doAThing(first: Foo)
          -> ResultType
        func doSomethingElse(
          firstArg: Foo,
          second secondArg: Bar,
          third thirdArg: Baz)
        func doStuff(
          firstArg: Foo,
          second second: Bar,
          third third: Baz
        ) -> Output
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 30)
  }

  func testProtocolWithInitializers() {
    let input =
      """
      protocol MyProtocol {
        init(bar: Int)
        init(reallyLongLabel: Int, anotherLongLabel: Bool)
      }
      """

    let expected =
      """
      protocol MyProtocol {
        init(bar: Int)
        init(
          reallyLongLabel: Int,
          anotherLongLabel: Bool)
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 30)
  }

  func testProtocolWithAssociatedtype() {
    let input =
      """
      protocol MyProtocol {
        var A: Int
        associatedtype TypeOne
        associatedtype TypeTwo: AnotherType
        associatedtype TypeThree: SomeType where TypeThree.Item == Item
        @available(swift 4.0)
        associatedtype TypeFour
      }
      """

    let expected =
      """
      protocol MyProtocol {
        var A: Int
        associatedtype TypeOne
        associatedtype TypeTwo: AnotherType
        associatedtype TypeThree: SomeType where TypeThree.Item == Item
        @available(swift 4.0)
        associatedtype TypeFour
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 65)
  }

  func testEmptyProtocol() {
    let input = "protocol Foo {}"
    assertPrettyPrintEqual(input: input, expected: input + "\n", linelength: 50)

    let wrapped = """
      protocol Foo {
      }

      """
    assertPrettyPrintEqual(input: input, expected: wrapped, linelength: 14)
  }

  func testEmptyProtocolWithComment() {
    let input = """
      protocol Foo {
        // foo
      }
      """
    assertPrettyPrintEqual(input: input, expected: input + "\n", linelength: 50)
  }

  func testOneMemberProtocol() {
    let input = "protocol Foo { var bar: Int { get } }"
    assertPrettyPrintEqual(input: input, expected: input + "\n", linelength: 50)
  }

  func testPrimaryAssociatedTypes_noPackArguments() {
    let input =
      """
      protocol MyProtocol<T> {
        var a: Int { get }
        var b: Bool { get }
      }
      protocol MyProtocol<T, S> {
        var a: Int { get }
        var b: Bool { get }
      }
      protocol MyProtocol<One, Two, Three, Four> {
        var a: Int { get }
        var b: Bool { get }
      }
      """

    let expected =
      """
      protocol MyProtocol<T> {
        var a: Int { get }
        var b: Bool { get }
      }
      protocol MyProtocol<T, S> {
        var a: Int { get }
        var b: Bool { get }
      }
      protocol MyProtocol<
        One,
        Two,
        Three,
        Four
      > {
        var a: Int { get }
        var b: Bool { get }
      }

      """

    var config = Configuration.forTesting
    config.lineBreakBeforeEachArgument = true
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 30, configuration: config)
  }

  func testPrimaryAssociatedTypes_packArguments() {
    let input =
      """
      protocol MyProtocol<T> {
        var a: Int { get }
        var b: Bool { get }
      }
      protocol MyProtocol<T, S> {
        var a: Int { get }
        var b: Bool { get }
      }
      protocol MyProtocol<One, Two, Three, Four> {
        var a: Int { get }
        var b: Bool { get }
      }
      """

    let expected =
      """
      protocol MyProtocol<T> {
        var a: Int { get }
        var b: Bool { get }
      }
      protocol MyProtocol<T, S> {
        var a: Int { get }
        var b: Bool { get }
      }
      protocol MyProtocol<
        One, Two, Three, Four
      > {
        var a: Int { get }
        var b: Bool { get }
      }

      """

    var config = Configuration.forTesting
    config.lineBreakBeforeEachArgument = false
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 30, configuration: config)
  }
}
