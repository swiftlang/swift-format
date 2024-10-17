import SwiftFormat

final class ExtensionDeclTests: PrettyPrintTestCase {
  func testBasicExtensionDeclarations() {
    let input =
      """
      extension MyExtension {
        let A: Int
        let B: Bool
      }
      public extension MyExtension {
        let A: Int
        let B: Bool
      }
      public extension MyLongerExtension {
        let A: Int
        let B: Bool
      }
      """

    let expected =
      """
      extension MyExtension {
        let A: Int
        let B: Bool
      }
      public extension MyExtension {
        let A: Int
        let B: Bool
      }
      public extension
        MyLongerExtension
      {
        let A: Int
        let B: Bool
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 33)
  }

  func testExtensionInheritance() {
    let input =
      """
      extension MyExtension: ProtoOne {
        let A: Int
        let B: Bool
      }
      extension MyExtension: ProtoOne, ProtoTwo {
        let A: Int
        let B: Bool
      }
      extension MyExtension: ProtoOne, ProtoTwo, ProtoThree {
        let A: Int
        let B: Bool
      }
      """

    let expected =
      """
      extension MyExtension: ProtoOne {
        let A: Int
        let B: Bool
      }
      extension MyExtension: ProtoOne, ProtoTwo {
        let A: Int
        let B: Bool
      }
      extension MyExtension: ProtoOne, ProtoTwo,
        ProtoThree
      {
        let A: Int
        let B: Bool
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 50)
  }

  func testExtensionWhereClause() {
    let input =
      """
      extension MyExtension where S: Collection {
        let A: Int
        let B: Double
      }
      extension MyExtension where S: Collection, T: ReallyLongExtensionName {
        let A: Int
        let B: Double
      }
      extension MyExtension where S: Collection, T: ReallyLongExtensionName, U: AnotherLongExtension {
        let A: Int
        let B: Double
      }
      """

    let expected =
      """
      extension MyExtension where S: Collection {
        let A: Int
        let B: Double
      }
      extension MyExtension
      where S: Collection, T: ReallyLongExtensionName {
        let A: Int
        let B: Double
      }
      extension MyExtension
      where
        S: Collection, T: ReallyLongExtensionName, U: AnotherLongExtension
      {
        let A: Int
        let B: Double
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 70)
  }

  func testExtensionWhereClause_lineBreakBeforeEachGenericRequirement() {
    let input =
      """
      extension MyExtension where S: Collection {
        let A: Int
        let B: Double
      }
      extension MyExtension where S: Collection, T: ReallyLongExtensionName {
        let A: Int
        let B: Double
      }
      extension MyExtension where S: Collection, T: ReallyLongExtensionName, U: AnotherLongExtension, W: AnotherReallyLongExtensionName {
        let A: Int
        let B: Double
      }
      """

    let expected =
      """
      extension MyExtension where S: Collection {
        let A: Int
        let B: Double
      }
      extension MyExtension
      where S: Collection, T: ReallyLongExtensionName {
        let A: Int
        let B: Double
      }
      extension MyExtension
      where
        S: Collection,
        T: ReallyLongExtensionName,
        U: AnotherLongExtension,
        W: AnotherReallyLongExtensionName
      {
        let A: Int
        let B: Double
      }

      """

    var config = Configuration.forTesting
    config.lineBreakBeforeEachGenericRequirement = true
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 70, configuration: config)
  }

  func testExtensionWhereClauseWithInheritance() {
    let input =
      """
      extension MyExtension: ProtoOne where S: Collection {
        let A: Int
        let B: Double
      }
      extension MyExtension: ProtoOne, ProtoTwo where S: Collection, T: Protocol {
        let A: Int
        let B: Double
      }
      extension MyExtension: ProtoOne, ProtoTwo where S: Collection, T: Protocol, T: ReallyLongExtensionName, U: LongerExtensionName {
        let A: Int
        let B: Double
      }
      """

    let expected =
      """
      extension MyExtension: ProtoOne where S: Collection {
        let A: Int
        let B: Double
      }
      extension MyExtension: ProtoOne, ProtoTwo
      where S: Collection, T: Protocol {
        let A: Int
        let B: Double
      }
      extension MyExtension: ProtoOne, ProtoTwo
      where
        S: Collection, T: Protocol, T: ReallyLongExtensionName,
        U: LongerExtensionName
      {
        let A: Int
        let B: Double
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 70)
  }

  func testExtensionWhereClauseWithInheritance_lineBreakBeforeEachGenericRequirement() {
    let input =
      """
      extension MyExtension: ProtoOne where S: Collection {
        let A: Int
        let B: Double
      }
      extension MyExtension: ProtoOne, ProtoTwo where S: Collection, T: Protocol {
        let A: Int
        let B: Double
      }
      extension MyExtension: ProtoOne, ProtoTwo where S: Collection, T: Protocol, T: ReallyLongExtensionName, U: LongerExtensionName {
        let A: Int
        let B: Double
      }
      """

    let expected =
      """
      extension MyExtension: ProtoOne where S: Collection {
        let A: Int
        let B: Double
      }
      extension MyExtension: ProtoOne, ProtoTwo
      where S: Collection, T: Protocol {
        let A: Int
        let B: Double
      }
      extension MyExtension: ProtoOne, ProtoTwo
      where
        S: Collection,
        T: Protocol,
        T: ReallyLongExtensionName,
        U: LongerExtensionName
      {
        let A: Int
        let B: Double
      }

      """

    var config = Configuration.forTesting
    config.lineBreakBeforeEachGenericRequirement = true
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 70, configuration: config)
  }

  func testExtensionAttributes() {
    let input =
      """
      @dynamicMemberLookup public extension MyExtension {
        let A: Int
        let B: Double
      }
      @dynamicMemberLookup @objc public extension MyExtension {
        let A: Int
        let B: Double
      }
      @dynamicMemberLookup @objc @objcMembers public extension MyExtension {
        let A: Int
        let B: Double
      }
      @dynamicMemberLookup
      @available(swift 4.0)
      public extension MyExtension {
        let A: Int
        let B: Double
      }
      """

    let expected =
      """
      @dynamicMemberLookup public extension MyExtension {
        let A: Int
        let B: Double
      }
      @dynamicMemberLookup @objc public extension MyExtension {
        let A: Int
        let B: Double
      }
      @dynamicMemberLookup @objc @objcMembers
      public extension MyExtension {
        let A: Int
        let B: Double
      }
      @dynamicMemberLookup
      @available(swift 4.0)
      public extension MyExtension {
        let A: Int
        let B: Double
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 60)
  }

  func testExtensionFullWrap() {
    let input =
      """
      public extension MyContainer: MyContainerProtocolOne, MyContainerProtocolTwo, SomeoneElsesContainerProtocol, SomeFrameworkContainerProtocol where BaseCollection: Collection, BaseCollection: P, BaseCollection.Element: Equatable, BaseCollection.Element: SomeOtherProtocol {
        let A: Int
        let B: Double
      }
      """

    let expected =

      """
      public extension MyContainer:
        MyContainerProtocolOne, MyContainerProtocolTwo,
        SomeoneElsesContainerProtocol,
        SomeFrameworkContainerProtocol
      where
        BaseCollection: Collection, BaseCollection: P,
        BaseCollection.Element: Equatable,
        BaseCollection.Element: SomeOtherProtocol
      {
        let A: Int
        let B: Double
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 50)
  }

  func testExtensionFullWrap_lineBreakBeforeEachGenericRequirement() {
    let input =
      """
      public extension MyContainer: MyContainerProtocolOne, MyContainerProtocolTwo, SomeoneElsesContainerProtocol, SomeFrameworkContainerProtocol where BaseCollection: Collection, BaseCollection: P, BaseCollection.Element: Equatable, BaseCollection.Element: SomeOtherProtocol {
        let A: Int
        let B: Double
      }
      """

    let expected =

      """
      public extension MyContainer:
        MyContainerProtocolOne, MyContainerProtocolTwo,
        SomeoneElsesContainerProtocol,
        SomeFrameworkContainerProtocol
      where
        BaseCollection: Collection,
        BaseCollection: P,
        BaseCollection.Element: Equatable,
        BaseCollection.Element: SomeOtherProtocol
      {
        let A: Int
        let B: Double
      }

      """

    var config = Configuration.forTesting
    config.lineBreakBeforeEachGenericRequirement = true
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 50, configuration: config)
  }

  func testEmptyExtension() {
    let input = "extension Foo {}"
    assertPrettyPrintEqual(input: input, expected: input + "\n", linelength: 50)

    let wrapped = """
      extension Foo {
      }

      """
    assertPrettyPrintEqual(input: input, expected: wrapped, linelength: 15)
  }

  func testEmptyExtensionWithComment() {
    let input = """
      extension Foo {
        // foo
      }
      """
    assertPrettyPrintEqual(input: input, expected: input + "\n", linelength: 50)
  }

  func testOneMemberExtension() {
    let input = "extension Foo { var bar: Int { return 0 } }"
    assertPrettyPrintEqual(input: input, expected: input + "\n", linelength: 50)
  }
}
