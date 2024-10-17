import SwiftFormat

final class ClassDeclTests: PrettyPrintTestCase {
  func testBasicClassDeclarations() {
    let input =
      """
      class MyClass {
        let A: Int
        let B: Bool
      }
      public class MyClass {
        let A: Int
        let B: Bool
      }
      public class MyLongerClass {
        let A: Int
        let B: Bool
      }
      """

    let expected =
      """
      class MyClass {
        let A: Int
        let B: Bool
      }
      public class MyClass {
        let A: Int
        let B: Bool
      }
      public class
        MyLongerClass
      {
        let A: Int
        let B: Bool
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 25)
  }

  func testGenericClassDeclarations_noPackArguments() {
    let input =
      """
      class MyClass<T> {
        let A: Int
        let B: Bool
      }
      class MyClass<T, S> {
        let A: Int
        let B: Bool
      }
      class MyClass<One, Two, Three, Four> {
        let A: Int
        let B: Bool
      }
      """

    let expected =
      """
      class MyClass<T> {
        let A: Int
        let B: Bool
      }
      class MyClass<T, S> {
        let A: Int
        let B: Bool
      }
      class MyClass<
        One,
        Two,
        Three,
        Four
      > {
        let A: Int
        let B: Bool
      }

      """

    var config = Configuration.forTesting
    config.lineBreakBeforeEachArgument = true
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 30, configuration: config)
  }

  func testGenericClassDeclarations_packArguments() {
    let input =
      """
      class MyClass<T> {
        let A: Int
        let B: Bool
      }
      class MyClass<T, S> {
        let A: Int
        let B: Bool
      }
      class MyClass<One, Two, Three, Four> {
        let A: Int
        let B: Bool
      }
      """

    let expected =
      """
      class MyClass<T> {
        let A: Int
        let B: Bool
      }
      class MyClass<T, S> {
        let A: Int
        let B: Bool
      }
      class MyClass<
        One, Two, Three, Four
      > {
        let A: Int
        let B: Bool
      }

      """

    var config = Configuration.forTesting
    config.lineBreakBeforeEachArgument = false
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 30, configuration: config)
  }

  func testClassInheritance() {
    let input =
      """
      class MyClass: SuperOne {
        let A: Int
        let B: Bool
      }
      class MyClass: SuperOne, SuperTwo {
        let A: Int
        let B: Bool
      }
      class MyClass: SuperOne, SuperTwo, SuperThree {
        let A: Int
        let B: Bool
      }
      class MyClass:
        SuperOne, SuperTwo, SuperThree {
        let A: Int
        let B: Bool
      }
      class MyClassWhoseNameIsVeryLong: SuperOne, SuperTwo, SuperThree {
        let A: Int
        let B: Bool
      }
      """

    let expected =
      """
      class MyClass: SuperOne {
        let A: Int
        let B: Bool
      }
      class MyClass: SuperOne, SuperTwo {
        let A: Int
        let B: Bool
      }
      class MyClass: SuperOne, SuperTwo,
        SuperThree
      {
        let A: Int
        let B: Bool
      }
      class MyClass:
        SuperOne, SuperTwo, SuperThree
      {
        let A: Int
        let B: Bool
      }
      class MyClassWhoseNameIsVeryLong:
        SuperOne, SuperTwo, SuperThree
      {
        let A: Int
        let B: Bool
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 40)
  }

  func testClassWhereClause() {
    let input =
      """
      class MyClass<S, T> where S: Collection {
        let A: Int
        let B: Double
      }
      class MyClass<S, T> where S: Collection, T: ReallyLongClassName {
        let A: Int
        let B: Double
      }
      class MyClass<S, T> where S: Collection, T: ReallyLongClassName, U: LongerClassName {
        let A: Int
        let B: Double
      }
      """

    let expected =
      """
      class MyClass<S, T> where S: Collection {
        let A: Int
        let B: Double
      }
      class MyClass<S, T>
      where S: Collection, T: ReallyLongClassName {
        let A: Int
        let B: Double
      }
      class MyClass<S, T>
      where
        S: Collection, T: ReallyLongClassName, U: LongerClassName
      {
        let A: Int
        let B: Double
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 60)
  }

  func testClassWhereClause_lineBreakAfterGenericWhereClause() {
    let input =
      """
      class MyClass<S, T> where S: Collection {
        let A: Int
        let B: Double
      }
      class MyClass<S, T> where S: Collection, T: ReallyLongClassName {
        let A: Int
        let B: Double
      }
      class MyClass<S, T> where S: Collection, T: ReallyLongClassName, U: LongerClassName, W: AnotherLongClassName {
        let A: Int
        let B: Double
      }
      """

    let expected =
      """
      class MyClass<S, T> where S: Collection {
        let A: Int
        let B: Double
      }
      class MyClass<S, T>
      where S: Collection, T: ReallyLongClassName {
        let A: Int
        let B: Double
      }
      class MyClass<S, T>
      where
        S: Collection,
        T: ReallyLongClassName,
        U: LongerClassName,
        W: AnotherLongClassName
      {
        let A: Int
        let B: Double
      }

      """

    var config = Configuration.forTesting
    config.lineBreakBeforeEachGenericRequirement = true
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 60, configuration: config)
  }

  func testClassWhereClauseWithInheritance() {
    let input =
      """
      class MyClass<S, T>: SuperOne where S: Collection {
        let A: Int
        let B: Double
      }
      class MyClass<S, T>: SuperOne, SuperTwo where S: Collection, T: Protocol {
        let A: Int
        let B: Double
      }
      """

    let expected =
      """
      class MyClass<S, T>: SuperOne where S: Collection {
        let A: Int
        let B: Double
      }
      class MyClass<S, T>: SuperOne, SuperTwo
      where S: Collection, T: Protocol {
        let A: Int
        let B: Double
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 60)
  }

  func testClassWhereClauseWithInheritance_lineBreakAfterGenericWhereClause() {
    let input =
      """
      class MyClass<S, T>: SuperOne where S: Collection {
        let A: Int
        let B: Double
      }
      class MyClass<S, T>: SuperOne, SuperTwo where S: Collection, T: Protocol {
        let A: Int
        let B: Double
      }
      class MyClass<S, T>: SuperOne, SuperTwo where S: Collection, T: Protocol, T: ReallyLongClassName, U: LongerClassName {
        let A: Int
        let B: Double
      }
      """

    let expected =
      """
      class MyClass<S, T>: SuperOne where S: Collection {
        let A: Int
        let B: Double
      }
      class MyClass<S, T>: SuperOne, SuperTwo
      where S: Collection, T: Protocol {
        let A: Int
        let B: Double
      }
      class MyClass<S, T>: SuperOne, SuperTwo
      where
        S: Collection,
        T: Protocol,
        T: ReallyLongClassName,
        U: LongerClassName
      {
        let A: Int
        let B: Double
      }

      """

    var config = Configuration.forTesting
    config.lineBreakBeforeEachGenericRequirement = true
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 60, configuration: config)
  }

  func testClassAttributes() {
    let input =
      """
      @dynamicMemberLookup public class MyClass {
        let A: Int
        let B: Double
      }
      @dynamicMemberLookup @objc public class MyClass {
        let A: Int
        let B: Double
      }
      @dynamicMemberLookup @objc @objcMembers public class MyClass {
        let A: Int
        let B: Double
      }
      @dynamicMemberLookup @available(swift 4.0)
      public class MyClass {
        let A: Int
        let B: Double
      }
      """

    let expected =
      """
      @dynamicMemberLookup public class MyClass {
        let A: Int
        let B: Double
      }
      @dynamicMemberLookup @objc public class MyClass {
        let A: Int
        let B: Double
      }
      @dynamicMemberLookup @objc @objcMembers
      public class MyClass {
        let A: Int
        let B: Double
      }
      @dynamicMemberLookup @available(swift 4.0)
      public class MyClass {
        let A: Int
        let B: Double
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 55)
  }

  func testClassFullWrap() {
    let input =
      """
      public class MyContainer<BaseCollection, SecondCollection>: MyContainerSuperclass, MyContainerProtocol, SomeoneElsesContainerProtocol, SomeFrameworkContainerProtocol where BaseCollection: Collection, BaseCollection: P, BaseCollection.Element: Equatable, BaseCollection.Element: SomeOtherProtocol {
        let A: Int
        let B: Double
      }
      """

    let expected =

      """
      public class MyContainer<
        BaseCollection, SecondCollection
      >: MyContainerSuperclass, MyContainerProtocol,
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

    var config = Configuration.forTesting
    config.lineBreakBeforeEachArgument = false
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 50, configuration: config)
  }

  func testClassFullWrap_lineBreakAfterGenericWhereClause() {
    let input =
      """
      public class MyContainer<BaseCollection, SecondCollection>: MyContainerSuperclass, MyContainerProtocol, SomeoneElsesContainerProtocol, SomeFrameworkContainerProtocol where BaseCollection: Collection, BaseCollection: P, BaseCollection.Element: Equatable, BaseCollection.Element: SomeOtherProtocol {
        let A: Int
        let B: Double
      }
      """

    let expected =

      """
      public class MyContainer<
        BaseCollection, SecondCollection
      >: MyContainerSuperclass, MyContainerProtocol,
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
    config.lineBreakBeforeEachArgument = false
    config.lineBreakBeforeEachGenericRequirement = true
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 50, configuration: config)
  }

  func testEmptyClass() {
    let input = "class Foo {}"
    assertPrettyPrintEqual(input: input, expected: input + "\n", linelength: 50)

    let wrapped = """
      class Foo {
      }

      """
    assertPrettyPrintEqual(input: input, expected: wrapped, linelength: 11)
  }

  func testEmptyClassWithComment() {
    let input = """
      class Foo {
        // foo
      }
      """
    assertPrettyPrintEqual(input: input, expected: input + "\n", linelength: 50)
  }

  func testOneMemberClass() {
    let input = "class Foo { var bar: Int }"
    assertPrettyPrintEqual(input: input, expected: input + "\n", linelength: 50)
  }

  func testBasicActorDeclarations() {
    let input =
      """
      actor MyActor {
        let A: Int
        let B: Bool
      }
      public actor MyActor {
        let A: Int
        let B: Bool
      }
      public actor MyLongerActor {
        let A: Int
        let B: Bool
      }
      """

    let expected =
      """
      actor MyActor {
        let A: Int
        let B: Bool
      }
      public actor MyActor {
        let A: Int
        let B: Bool
      }
      public actor
        MyLongerActor
      {
        let A: Int
        let B: Bool
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 25)
  }
}
