//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2025 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

@_spi(Rules) import SwiftFormat
import _SwiftFormatTestSupport

final class NoAccessLevelOnExtensionDeclarationTests: LintOrFormatRuleTestCase {
  func testExtensionDeclarationAccessLevel() {
    assertFormatting(
      NoAccessLevelOnExtensionDeclaration.self,
      input: """
        1️⃣public extension Foo {
          2️⃣var x: Bool
          // Comment 1
          internal var y: Bool
          // Comment 2
          3️⃣static var z: Bool
          // Comment 3
          4️⃣static func someFunc() {}
          5️⃣init() {}
          6️⃣subscript(index: Int) -> Element {}
          7️⃣class SomeClass {}
          8️⃣struct SomeStruct {}
          9️⃣enum SomeEnum {}
          🔟typealias Foo = Bar
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
          public class SomeClass {}
          public struct SomeStruct {}
          public enum SomeEnum {}
          public typealias Foo = Bar
        }
        """,
      findings: [
        FindingSpec(
          "1️⃣",
          message: "move this 'public' access modifier to precede each member inside this extension",
          notes: [
            NoteSpec("2️⃣", message: "add 'public' access modifier to this declaration"),
            NoteSpec("3️⃣", message: "add 'public' access modifier to this declaration"),
            NoteSpec("4️⃣", message: "add 'public' access modifier to this declaration"),
            NoteSpec("5️⃣", message: "add 'public' access modifier to this declaration"),
            NoteSpec("6️⃣", message: "add 'public' access modifier to this declaration"),
            NoteSpec("7️⃣", message: "add 'public' access modifier to this declaration"),
            NoteSpec("8️⃣", message: "add 'public' access modifier to this declaration"),
            NoteSpec("9️⃣", message: "add 'public' access modifier to this declaration"),
            NoteSpec("🔟", message: "add 'public' access modifier to this declaration"),
          ]
        )
      ]
    )
  }

  func testRemoveRedundantInternal() {
    assertFormatting(
      NoAccessLevelOnExtensionDeclaration.self,
      input: """
        1️⃣internal extension Bar {
          var a: Int
          var b: Int
        }
        """,
      expected: """
        extension Bar {
          var a: Int
          var b: Int
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove this redundant 'internal' access modifier from this extension")
      ]
    )
  }

  func testPreservesCommentOnRemovedModifier() {
    assertFormatting(
      NoAccessLevelOnExtensionDeclaration.self,
      input: """
        /// This doc comment should stick around.
        1️⃣public extension Foo {
          3️⃣func f() {}
          // This should not change.
          4️⃣func g() {}
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
        FindingSpec(
          "1️⃣",
          message: "move this 'public' access modifier to precede each member inside this extension",
          notes: [
            NoteSpec("3️⃣", message: "add 'public' access modifier to this declaration"),
            NoteSpec("4️⃣", message: "add 'public' access modifier to this declaration"),
          ]
        ),
        FindingSpec("2️⃣", message: "remove this redundant 'internal' access modifier from this extension"),
      ]
    )
  }

  func testPackageAccessLevel() {
    assertFormatting(
      NoAccessLevelOnExtensionDeclaration.self,
      input: """
        1️⃣package extension Foo {
          2️⃣func f() {}
        }
        """,
      expected: """
        extension Foo {
          package func f() {}
        }
        """,
      findings: [
        FindingSpec(
          "1️⃣",
          message: "move this 'package' access modifier to precede each member inside this extension",
          notes: [
            NoteSpec("2️⃣", message: "add 'package' access modifier to this declaration")
          ]
        )
      ]
    )
  }

  func testPrivateIsEffectivelyFileprivate() {
    assertFormatting(
      NoAccessLevelOnExtensionDeclaration.self,
      input: """
        1️⃣private extension Foo {
          2️⃣func f() {}
        }
        """,
      expected: """
        extension Foo {
          fileprivate func f() {}
        }
        """,
      findings: [
        FindingSpec(
          "1️⃣",
          message:
            "remove this 'private' access modifier and declare each member inside this extension as 'fileprivate'",
          notes: [
            NoteSpec("2️⃣", message: "add 'fileprivate' access modifier to this declaration")
          ]
        )
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
        FindingSpec("1️⃣", message: "move this 'public' access modifier to precede each member inside this extension")
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
          2️⃣@objc var x: Bool { get { return true }}
          // This property has a developer comment.
          3️⃣@objc static var z: Bool { get { return false }}
          /// This static function has a doc comment.
          4️⃣@objc static func someStaticFunc() {}
          5️⃣@objc init(with foo: Foo) {}
          6️⃣@objc func someOtherFunc() {}
          7️⃣@objc class SomeClass : NSObject {}
          8️⃣@objc typealias SomeType = SomeOtherType
          9️⃣@objc enum SomeEnum : Int {
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
          @objc public class SomeClass : NSObject {}
          @objc public typealias SomeType = SomeOtherType
          @objc public enum SomeEnum : Int {
            case SomeInt = 32
          }
        }
        """,
      findings: [
        FindingSpec(
          "1️⃣",
          message: "move this 'public' access modifier to precede each member inside this extension",
          notes: [
            NoteSpec("2️⃣", message: "add 'public' access modifier to this declaration"),
            NoteSpec("3️⃣", message: "add 'public' access modifier to this declaration"),
            NoteSpec("4️⃣", message: "add 'public' access modifier to this declaration"),
            NoteSpec("5️⃣", message: "add 'public' access modifier to this declaration"),
            NoteSpec("6️⃣", message: "add 'public' access modifier to this declaration"),
            NoteSpec("7️⃣", message: "add 'public' access modifier to this declaration"),
            NoteSpec("8️⃣", message: "add 'public' access modifier to this declaration"),
            NoteSpec("9️⃣", message: "add 'public' access modifier to this declaration"),
          ]
        )
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
          2️⃣@available(iOS 13, *)
          var x: Bool { get { return true }}
          // This property has a developer comment.
          3️⃣@available(iOS 13, *)
          static var z: Bool { get { return false }}
          // This static function has a developer comment.
          4️⃣@objc(someStaticFunction)
          static func someStaticFunc() {}
          5️⃣@objc(initWithFoo:)
          init(with foo: Foo) {}
          6️⃣@objc
          func someOtherFunc() {}
          7️⃣@objc
          class SomeClass : NSObject {}
          8️⃣@available(iOS 13, *)
          typealias SomeType = SomeOtherType
          9️⃣@objc
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
          public class SomeClass : NSObject {}
          @available(iOS 13, *)
          public typealias SomeType = SomeOtherType
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
        FindingSpec(
          "1️⃣",
          message: "move this 'public' access modifier to precede each member inside this extension",
          notes: [
            NoteSpec("2️⃣", message: "add 'public' access modifier to this declaration"),
            NoteSpec("3️⃣", message: "add 'public' access modifier to this declaration"),
            NoteSpec("4️⃣", message: "add 'public' access modifier to this declaration"),
            NoteSpec("5️⃣", message: "add 'public' access modifier to this declaration"),
            NoteSpec("6️⃣", message: "add 'public' access modifier to this declaration"),
            NoteSpec("7️⃣", message: "add 'public' access modifier to this declaration"),
            NoteSpec("8️⃣", message: "add 'public' access modifier to this declaration"),
            NoteSpec("9️⃣", message: "add 'public' access modifier to this declaration"),
          ]
        )
      ]
    )
  }

  func testIfConfigMembers() {
    assertFormatting(
      NoAccessLevelOnExtensionDeclaration.self,
      input: """
        1️⃣public extension Foo {
          #if os(macOS)
            2️⃣var x: Bool
          #else
            3️⃣var y: String
          #endif
        }
        """,
      expected: """
        extension Foo {
          #if os(macOS)
            public var x: Bool
          #else
            public var y: String
          #endif
        }
        """,
      findings: [
        FindingSpec(
          "1️⃣",
          message: "move this 'public' access modifier to precede each member inside this extension",
          notes: [
            NoteSpec("2️⃣", message: "add 'public' access modifier to this declaration"),
            NoteSpec("3️⃣", message: "add 'public' access modifier to this declaration"),
          ]
        )
      ]
    )
  }

  func testNestedExtensionsAreIgnored() {
    assertFormatting(
      NoAccessLevelOnExtensionDeclaration.self,
      input: """
        1️⃣public extension Foo {
          2️⃣var x: Bool
          extension Bar {
            var y: String
          }
          private extension Baz {
            var y: String
          }
          3️⃣var z: Float
        }
        """,
      expected: """
        extension Foo {
          public var x: Bool
          extension Bar {
            var y: String
          }
          private extension Baz {
            var y: String
          }
          public var z: Float
        }
        """,
      findings: [
        FindingSpec(
          "1️⃣",
          message: "move this 'public' access modifier to precede each member inside this extension",
          notes: [
            NoteSpec("2️⃣", message: "add 'public' access modifier to this declaration"),
            NoteSpec("3️⃣", message: "add 'public' access modifier to this declaration"),
          ]
        )
      ]
    )
  }
}
