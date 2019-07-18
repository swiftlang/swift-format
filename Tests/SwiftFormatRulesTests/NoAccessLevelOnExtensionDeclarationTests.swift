import Foundation
import SwiftSyntax
import XCTest

@testable import SwiftFormatRules

public class NoAccessLevelOnExtensionDeclarationTests: DiagnosingTestCase {
  public func testExtensionDeclarationAccessLevel() {
    XCTAssertFormatting(
      NoAccessLevelOnExtensionDeclaration.self,
      input: """
             public extension Foo {
               var x: Bool
               // Comment 1
               internal var y: Bool
               // Comment 2
               static var z: Bool
               static func someFunc() {}
               init() {}
               protocol SomeProtocol {}
               class SomeClass {}
               struct SomeStruct {}
               enum SomeEnum {}
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
                  public static func someFunc() {}
                  public init() {}
                  public protocol SomeProtocol {}
                  public class SomeClass {}
                  public struct SomeStruct {}
                  public enum SomeEnum {}
                }
                extension Bar {
                  var a: Int
                  var b: Int
                }
                """
    )
  }

  public func testPreservesCommentOnRemovedModifier() {
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
}
