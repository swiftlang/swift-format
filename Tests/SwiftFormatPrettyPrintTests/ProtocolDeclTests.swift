public class ProtocolDeclTests: PrettyPrintTestCase {
  public func testBasicProtocolDeclarations() {
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

  public func testProtocolInheritance() {
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


  public func testProtocolAttributes() {
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

  public func testProtocolWithFunctions() {
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

  public func testProtocolWithInitializers() {
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

  public func testProtocolWithAssociatedtype() {
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

  public func testEmptyProtocol() {
    let input = "protocol Foo {}"
    assertPrettyPrintEqual(input: input, expected: input + "\n", linelength: 50)

    let wrapped = """
      protocol Foo {
      }

      """
    assertPrettyPrintEqual(input: input, expected: wrapped, linelength: 14)
  }

  public func testEmptyProtocolWithComment() {
    let input = """
      protocol Foo {
        // foo
      }
      """
    assertPrettyPrintEqual(input: input, expected: input + "\n", linelength: 50)
  }

  public func testOneMemberProtocol() {
    let input = "protocol Foo { var bar: Int { get } }"
    assertPrettyPrintEqual(input: input, expected: input + "\n", linelength: 50)
  }
}
