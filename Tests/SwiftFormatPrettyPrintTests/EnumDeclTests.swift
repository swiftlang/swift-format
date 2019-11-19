import SwiftFormatConfiguration

public class EnumDeclTests: PrettyPrintTestCase {

  public func testBasicEnumDeclarations() {
    let input =
      """
      enum MyEnum {
        case firstCase
        case secondCase
      }
      public enum MyEnum {
        case firstCase
        case secondCase
      }
      public enum MyLongerEnum {
        case firstCase
        case secondCase
      }
      """

    let expected =
      """
      enum MyEnum {
        case firstCase
        case secondCase
      }
      public enum MyEnum {
        case firstCase
        case secondCase
      }
      public enum
        MyLongerEnum
      {
        case firstCase
        case secondCase
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 23)
  }

  public func testMixedEnumCaseStyles_noPackArguments() {
    let input =
      """
      enum MyEnum {
        case first
        case second, third
        case fourth(Int)
        case fifth(a: Int, b: Bool)
      }
      enum MyEnum {
        case first
        case second, third, fourth, fifth
        case sixth(Int)
        case seventh(a: Int, b: Bool, c: Double)
      }
      """

    let expected =
      """
      enum MyEnum {
        case first
        case second, third
        case fourth(Int)
        case fifth(a: Int, b: Bool)
      }
      enum MyEnum {
        case first
        case second, third, fourth,
          fifth
        case sixth(Int)
        case seventh(
          a: Int,
          b: Bool,
          c: Double
        )
      }

      """

    var config = Configuration()
    config.lineBreakBeforeEachArgument = true
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 30, configuration: config)
  }

  public func testMixedEnumCaseStyles_packArguments() {
    let input =
      """
      enum MyEnum {
        case first
        case second, third
        case fourth(Int)
        case fifth(a: Int, b: Bool)
      }
      enum MyEnum {
        case first
        case second, third, fourth, fifth
        case sixth(Int)
        case seventh(a: Int, b: Bool, c: Double)
      }
      """

    let expected =
      """
      enum MyEnum {
        case first
        case second, third
        case fourth(Int)
        case fifth(a: Int, b: Bool)
      }
      enum MyEnum {
        case first
        case second, third, fourth,
          fifth
        case sixth(Int)
        case seventh(
          a: Int, b: Bool, c: Double
        )
      }

      """

    var config = Configuration()
    config.lineBreakBeforeEachArgument = false
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 30, configuration: config)
  }

  public func testIndirectEnum() {
    let input =
      """
      enum MyEnum {
        indirect case first
        case second
      }
      indirect enum MyEnum {
        case first
        case second
      }
      public indirect enum MyEnum {
        case first
        case second
      }
      """

    let expected =
      """
      enum MyEnum {
        indirect case first
        case second
      }
      indirect enum MyEnum {
        case first
        case second
      }
      public indirect enum MyEnum {
        case first
        case second
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 30)
  }

  public func testGenericEnumDeclarations() {
    let input =
      """
      enum MyEnum<T> {
        case firstCase
        case secondCase
      }
      enum MyEnum<T, S> {
        case firstCase
        case secondCase
      }
      enum MyEnum<One, Two, Three, Four> {
        case firstCase
        case secondCase
      }
      """

    let expected =
      """
      enum MyEnum<T> {
        case firstCase
        case secondCase
      }
      enum MyEnum<T, S> {
        case firstCase
        case secondCase
      }
      enum MyEnum<
        One, Two, Three, Four
      > {
        case firstCase
        case secondCase
      }

      """

    var config = Configuration()
    config.lineBreakBeforeEachArgument = false
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 30, configuration: config)
  }

  public func testEnumInheritance() {
    let input =
      """
      enum MyEnum: ProtoOne {
        case firstCase
        case secondCase
      }
      enum MyEnum: ProtoOne, ProtoTwo {
        case firstCase
        case secondCase
      }
      enum MyEnum: ProtoOne, ProtoTwo, ProtoThree {
        case firstCase
        case secondCase
      }
      """

    let expected =
      """
      enum MyEnum: ProtoOne {
        case firstCase
        case secondCase
      }
      enum MyEnum: ProtoOne, ProtoTwo {
        case firstCase
        case secondCase
      }
      enum MyEnum: ProtoOne, ProtoTwo,
        ProtoThree
      {
        case firstCase
        case secondCase
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 40)
  }

  public func testEnumWhereClause() {
    let input =
      """
      enum MyEnum<S, T> where S: Collection {
        case firstCase
        let B: Double
      }
      enum MyEnum<S, T> where S: Collection, T: ReallyLongEnumName {
        case firstCase
        let B: Double
      }
      enum MyEnum<S, T> where S: Collection, T: ReallyLongEnumName, U: AnotherLongEnum {
        case firstCase
        let B: Double
      }
      """

    let expected =
      """
      enum MyEnum<S, T> where S: Collection {
        case firstCase
        let B: Double
      }
      enum MyEnum<S, T>
      where S: Collection, T: ReallyLongEnumName {
        case firstCase
        let B: Double
      }
      enum MyEnum<S, T>
      where
        S: Collection, T: ReallyLongEnumName, U: AnotherLongEnum
      {
        case firstCase
        let B: Double
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 60)
  }

  public func testEnumWhereClause_lineBreakBeforeEachGenericRequirement() {
    let input =
    """
      enum MyEnum<S, T> where S: Collection {
        case firstCase
        let B: Double
      }
      enum MyEnum<S, T> where S: Collection, T: ReallyLongEnumName {
        case firstCase
        let B: Double
      }
      enum MyEnum<S, T> where S: Collection, T: ReallyLongEnumName, U: AnotherLongEnum, W: AnotherReallyLongEnumName {
        case firstCase
        let B: Double
      }
      """

    let expected =
    """
      enum MyEnum<S, T> where S: Collection {
        case firstCase
        let B: Double
      }
      enum MyEnum<S, T>
      where S: Collection, T: ReallyLongEnumName {
        case firstCase
        let B: Double
      }
      enum MyEnum<S, T>
      where
        S: Collection,
        T: ReallyLongEnumName,
        U: AnotherLongEnum,
        W: AnotherReallyLongEnumName
      {
        case firstCase
        let B: Double
      }

      """

    var config = Configuration()
    config.lineBreakBeforeEachGenericRequirement = true
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 60, configuration: config)
  }

  public func testEnumWhereClauseWithInheritance() {
    let input =
      """
      enum MyEnum<S, T>: ProtoOne where S: Collection {
        case firstCase
        let B: Double
      }
      enum MyEnum<S, T>: ProtoOne, ProtoTwo where S: Collection, T: Protocol {
        case firstCase
        let B: Double
      }
      enum MyEnum<S, T>: ProtoOne, ProtoTwo where S: Collection, T: Protocol, T: ReallyLongEnumName, U: LongerEnumName, W: AnotherReallyLongEnumName {
        case firstCase
        let B: Double
      }
      """

    let expected =
      """
      enum MyEnum<S, T>: ProtoOne where S: Collection {
        case firstCase
        let B: Double
      }
      enum MyEnum<S, T>: ProtoOne, ProtoTwo
      where S: Collection, T: Protocol {
        case firstCase
        let B: Double
      }
      enum MyEnum<S, T>: ProtoOne, ProtoTwo
      where
        S: Collection, T: Protocol, T: ReallyLongEnumName,
        U: LongerEnumName, W: AnotherReallyLongEnumName
      {
        case firstCase
        let B: Double
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 60)
  }

  public func testEnumWhereClauseWithInheritance_lineBreakBeforeEachGenericRequirement() {
    let input =
    """
      enum MyEnum<S, T>: ProtoOne where S: Collection {
        case firstCase
        let B: Double
      }
      enum MyEnum<S, T>: ProtoOne, ProtoTwo where S: Collection, T: Protocol {
        case firstCase
        let B: Double
      }
      enum MyEnum<S, T>: ProtoOne, ProtoTwo where S: Collection, T: Protocol, T: ReallyLongEnumName, U: LongerEnumName, W: AnotherReallyLongEnumName {
        case firstCase
        let B: Double
      }
      """

    let expected =
    """
      enum MyEnum<S, T>: ProtoOne where S: Collection {
        case firstCase
        let B: Double
      }
      enum MyEnum<S, T>: ProtoOne, ProtoTwo
      where S: Collection, T: Protocol {
        case firstCase
        let B: Double
      }
      enum MyEnum<S, T>: ProtoOne, ProtoTwo
      where
        S: Collection,
        T: Protocol,
        T: ReallyLongEnumName,
        U: LongerEnumName,
        W: AnotherReallyLongEnumName
      {
        case firstCase
        let B: Double
      }

      """

    var config = Configuration()
    config.lineBreakBeforeEachGenericRequirement = true
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 60, configuration: config)
  }

  public func testEnumAttributes() {
    let input =
      """
      @dynamicMemberLookup public enum MyEnum {
        case firstCase
        let B: Double
      }
      @dynamicMemberLookup @objc public enum MyEnum {
        case firstCase
        let B: Double
      }
      @dynamicMemberLookup @objc @objcMembers public enum MyEnum {
        case firstCase
        let B: Double
      }
      @dynamicMemberLookup @available(swift 4.0)
      public enum MyEnum {
        case firstCase
        let B: Double
      }
      """

    let expected =
      """
      @dynamicMemberLookup public enum MyEnum {
        case firstCase
        let B: Double
      }
      @dynamicMemberLookup @objc public enum MyEnum {
        case firstCase
        let B: Double
      }
      @dynamicMemberLookup @objc @objcMembers
      public enum MyEnum {
        case firstCase
        let B: Double
      }
      @dynamicMemberLookup @available(swift 4.0)
      public enum MyEnum {
        case firstCase
        let B: Double
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 55)
  }

  public func testEnumFullWrap() {
    let input =
      """
      public enum MyEnum<BaseCollection, SecondCollection>: MyContainerProtocolOne, MyContainerProtocolTwo, SomeoneElsesContainerProtocol, SomeFrameworkContainerProtocol where BaseCollection: Collection, BaseCollection: P, BaseCollection.Element: Equatable, BaseCollection.Element: SomeOtherProtocol {
        case firstCase
        let B: Double
      }
      """

    let expected =

      """
      public enum MyEnum<
        BaseCollection, SecondCollection
      >: MyContainerProtocolOne, MyContainerProtocolTwo,
        SomeoneElsesContainerProtocol,
        SomeFrameworkContainerProtocol
      where
        BaseCollection: Collection, BaseCollection: P,
        BaseCollection.Element: Equatable,
        BaseCollection.Element: SomeOtherProtocol
      {
        case firstCase
        let B: Double
      }

      """

    var config = Configuration()
    config.lineBreakBeforeEachArgument = false
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 50, configuration: config)
  }

  public func testEnumFullWrap_lineBreakBeforeEachGenericRequirement() {
    let input =
    """
      public enum MyEnum<BaseCollection, SecondCollection>: MyContainerProtocolOne, MyContainerProtocolTwo, SomeoneElsesContainerProtocol, SomeFrameworkContainerProtocol where BaseCollection: Collection, BaseCollection: P, BaseCollection.Element: Equatable, BaseCollection.Element: SomeOtherProtocol {
        case firstCase
        let B: Double
      }
      """

    let expected =

    """
      public enum MyEnum<
        BaseCollection, SecondCollection
      >: MyContainerProtocolOne, MyContainerProtocolTwo,
        SomeoneElsesContainerProtocol,
        SomeFrameworkContainerProtocol
      where
        BaseCollection: Collection,
        BaseCollection: P,
        BaseCollection.Element: Equatable,
        BaseCollection.Element: SomeOtherProtocol
      {
        case firstCase
        let B: Double
      }

      """

    var config = Configuration()
    config.lineBreakBeforeEachArgument = false
    config.lineBreakBeforeEachGenericRequirement = true
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 50, configuration: config)
  }

  public func testEmptyEnum() {
    let input = "enum Foo {}"
    assertPrettyPrintEqual(input: input, expected: input + "\n", linelength: 50)

    let wrapped = """
      enum Foo {
      }

      """
    assertPrettyPrintEqual(input: input, expected: wrapped, linelength: 10)
  }

  public func testEmptyEnumWithComment() {
    let input = """
      enum Foo {
        // foo
      }
      """
    assertPrettyPrintEqual(input: input, expected: input + "\n", linelength: 50)
  }

  public func testOneMemberEnum() {
    let input = "enum Foo { var bar: Int }"
    assertPrettyPrintEqual(input: input, expected: input + "\n", linelength: 50)
  }
}
