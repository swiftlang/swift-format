import _SwiftFormatTestSupport

@_spi(Rules) import SwiftFormat

// FIXME: We should have notes on each of the declarations inside the extension that we modify.
// Also fix the lack of trimming around the extension name, and we should say "extension X" instead
// of just "X".
final class NoAccessLevelOnExtensionDeclarationTests: LintOrFormatRuleTestCase {
  func testExtensionDeclarationAccessLevel() {
    assertFormatting(
      NoAccessLevelOnExtensionDeclaration.self,
      input: """
        1️⃣public extension Foo {
          var x: Bool
          // Comment 1
          internal var y: Bool
          // Comment 2
          static var z: Bool
          // Comment 3
          static func someFunc() {}
          init() {}
          subscript(index: Int) -> Element {}
          protocol SomeProtocol {}
          class SomeClass {}
          struct SomeStruct {}
          enum SomeEnum {}
          typealias Foo = Bar
        }
        2️⃣internal extension Bar {
          var a: Int
          var b: Int
        }
        """,
      expected: """
        extension Foo {
          public var x: Bool
          // Comment 1
          internal var y: Bool
          // Comment 2
          public static var z: Bool
          // Comment 3
          public static func someFunc() {}
          public init() {}
          public subscript(index: Int) -> Element {}
          public protocol SomeProtocol {}
          public class SomeClass {}
          public struct SomeStruct {}
          public enum SomeEnum {}
          public typealias Foo = Bar
        }
        extension Bar {
          var a: Int
          var b: Int
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "move the 'public' access keyword to precede each member inside the extension"),
        FindingSpec("2️⃣", message: "remove redundant 'internal' access keyword from 'Bar '"),
      ]
    )
  }

  func testPreservesCommentOnRemovedModifier() {
    assertFormatting(
      NoAccessLevelOnExtensionDeclaration.self,
      input: """
        /// This doc comment should stick around.
        1️⃣public extension Foo {
          func f() {}
          // This should not change.
          func g() {}
        }

        /// So should this one.
        2️⃣internal extension Foo {
          func f() {}
          // This should not change.
          func g() {}
        }
        """,
      expected: """
        /// This doc comment should stick around.
        extension Foo {
          public func f() {}
          // This should not change.
          public func g() {}
        }

        /// So should this one.
        extension Foo {
          func f() {}
          // This should not change.
          func g() {}
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "move the 'public' access keyword to precede each member inside the extension"),
        FindingSpec("2️⃣", message: "remove redundant 'internal' access keyword from 'Foo '"),
      ]
    )
  }

  func testPrivateIsEffectivelyFileprivate() {
    assertFormatting(
      NoAccessLevelOnExtensionDeclaration.self,
      input: """
        1️⃣private extension Foo {
          func f() {}
        }
        """,
      expected: """
        extension Foo {
          fileprivate func f() {}
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "move the 'private' access keyword to precede each member inside the extension"),
      ]
    )
  }

  func testExtensionWithAnnotation() {
    assertFormatting(
      NoAccessLevelOnExtensionDeclaration.self,
      input: """
        /// This extension has a comment.
        @objc 1️⃣public extension Foo {
        }
        """,
      expected: """
        /// This extension has a comment.
        @objc extension Foo {
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "move the 'public' access keyword to precede each member inside the extension"),
      ]
    )
  }

  func testPreservesInlineAnnotationsBeforeAddedAccessLevelModifiers() {
    assertFormatting(
      NoAccessLevelOnExtensionDeclaration.self,
      input: """
        /// This extension has a comment.
        1️⃣public extension Foo {
          /// This property has a doc comment.
          @objc var x: Bool { get { return true }}
          // This property has a developer comment.
          @objc static var z: Bool { get { return false }}
          /// This static function has a doc comment.
          @objc static func someStaticFunc() {}
          @objc init(with foo: Foo) {}
          @objc func someOtherFunc() {}
          @objc protocol SomeProtocol {}
          @objc class SomeClass : NSObject {}
          @objc associatedtype SomeType
          @objc enum SomeEnum : Int {
            case SomeInt = 32
          }
        }
        """,
      expected: """
        /// This extension has a comment.
        extension Foo {
          /// This property has a doc comment.
          @objc public var x: Bool { get { return true }}
          // This property has a developer comment.
          @objc public static var z: Bool { get { return false }}
          /// This static function has a doc comment.
          @objc public static func someStaticFunc() {}
          @objc public init(with foo: Foo) {}
          @objc public func someOtherFunc() {}
          @objc public protocol SomeProtocol {}
          @objc public class SomeClass : NSObject {}
          @objc public associatedtype SomeType
          @objc public enum SomeEnum : Int {
            case SomeInt = 32
          }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "move the 'public' access keyword to precede each member inside the extension"),
      ]
    )
  }

  func testPreservesMultiLineAnnotationsBeforeAddedAccessLevelModifiers() {
    assertFormatting(
      NoAccessLevelOnExtensionDeclaration.self,
      input: """
        /// This extension has a comment.
        1️⃣public extension Foo {
          /// This property has a doc comment.
          @available(iOS 13, *)
          var x: Bool { get { return true }}
          // This property has a developer comment.
          @available(iOS 13, *)
          static var z: Bool { get { return false }}
          // This static function has a developer comment.
          @objc(someStaticFunction)
          static func someStaticFunc() {}
          @objc(initWithFoo:)
          init(with foo: Foo) {}
          @objc
          func someOtherFunc() {}
          @objc
          protocol SomeProtocol {}
          @objc
          class SomeClass : NSObject {}
          @available(iOS 13, *)
          associatedtype SomeType
          @objc
          enum SomeEnum : Int {
            case SomeInt = 32
          }

          // This is a doc comment for a multi-argument method.
          @objc(
            doSomethingThatIsVeryComplicatedWithThisFoo:
            forGoodMeasureUsingThisBar:
            andApplyingThisBaz:
          )
          public func doSomething(_ foo : Foo, bar : Bar, baz : Baz) {}
        }
        """,
      expected: """
        /// This extension has a comment.
        extension Foo {
          /// This property has a doc comment.
          @available(iOS 13, *)
          public var x: Bool { get { return true }}
          // This property has a developer comment.
          @available(iOS 13, *)
          public static var z: Bool { get { return false }}
          // This static function has a developer comment.
          @objc(someStaticFunction)
          public static func someStaticFunc() {}
          @objc(initWithFoo:)
          public init(with foo: Foo) {}
          @objc
          public func someOtherFunc() {}
          @objc
          public protocol SomeProtocol {}
          @objc
          public class SomeClass : NSObject {}
          @available(iOS 13, *)
          public associatedtype SomeType
          @objc
          public enum SomeEnum : Int {
            case SomeInt = 32
          }

          // This is a doc comment for a multi-argument method.
          @objc(
            doSomethingThatIsVeryComplicatedWithThisFoo:
            forGoodMeasureUsingThisBar:
            andApplyingThisBaz:
          )
          public func doSomething(_ foo : Foo, bar : Bar, baz : Baz) {}
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "move the 'public' access keyword to precede each member inside the extension"),
      ]
    )
  }
}
