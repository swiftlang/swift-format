import SwiftFormatRules

final class NoAccessLevelOnExtensionDeclarationTests: LintOrFormatRuleTestCase {
  func testExtensionDeclarationAccessLevel() {
    XCTAssertFormatting(
      NoAccessLevelOnExtensionDeclaration.self,
      input: """
             public extension Foo {
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
             internal extension Bar {
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
                """
    )
  }

  func testPreservesCommentOnRemovedModifier() {
    XCTAssertFormatting(
      NoAccessLevelOnExtensionDeclaration.self,
      input: """
        /// This doc comment should stick around.
        public extension Foo {
          func f() {}
          // This should not change.
          func g() {}
        }

        /// So should this one.
        internal extension Foo {
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
        """
    )
  }

  func testPrivateIsEffectivelyFileprivate() {
    XCTAssertFormatting(
      NoAccessLevelOnExtensionDeclaration.self,
      input: """
        private extension Foo {
          func f() {}
        }
        """,
      expected: """
        extension Foo {
          fileprivate func f() {}
        }
        """
    )
  }

  func testExtensionWithAnnotation() {
    XCTAssertFormatting(
      NoAccessLevelOnExtensionDeclaration.self,
      input:
        """
        /// This extension has a comment.
        @objc public extension Foo {
        }
        """,
      expected:
        """
        /// This extension has a comment.
        @objc extension Foo {
        }
        """
    )
  }

  func testPreservesInlineAnnotationsBeforeAddedAccessLevelModifiers() {
    XCTAssertFormatting(
      NoAccessLevelOnExtensionDeclaration.self,
      input: """
            /// This extension has a comment.
            public extension Foo {
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
            """
    )
  }

  func testPreservesMultiLineAnnotationsBeforeAddedAccessLevelModifiers() {
    XCTAssertFormatting(
      NoAccessLevelOnExtensionDeclaration.self,
      input: """
        /// This extension has a comment.
        public extension Foo {
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
        """
    )
  }
}
