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

final class DontRepeatTypeInStaticPropertiesTests: LintOrFormatRuleTestCase {
  func testRepetitiveProperties() {
    assertLint(
      DontRepeatTypeInStaticProperties.self,
      """
      public class UIColor {
        static let 1️⃣redColor: UIColor
        public class var 2️⃣blueColor: UIColor
        var yellowColor: UIColor
        static let green: UIColor
        public class var purple: UIColor
      }
      enum Sandwich {
        static let 3️⃣bolognaSandwich: Sandwich
        static var 4️⃣hamSandwich: Sandwich
        static var turkey: Sandwich
      }
      protocol RANDPerson {
        var oldPerson: Person
        static let 5️⃣youngPerson: Person
      }
      struct TVGame {
        static var 6️⃣basketballGame: TVGame
        static var 7️⃣baseballGame: TVGame
        static let soccer: TVGame
        let hockey: TVGame
      }
      extension URLSession {
        class var 8️⃣sharedSession: URLSession
      }
      public actor Cookie {
        static let 9️⃣chocolateChipCookie: Cookie
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: "remove the suffix 'Color' from the name of the variable 'redColor'"),
        FindingSpec("2️⃣", message: "remove the suffix 'Color' from the name of the variable 'blueColor'"),
        FindingSpec("3️⃣", message: "remove the suffix 'Sandwich' from the name of the variable 'bolognaSandwich'"),
        FindingSpec("4️⃣", message: "remove the suffix 'Sandwich' from the name of the variable 'hamSandwich'"),
        FindingSpec("5️⃣", message: "remove the suffix 'Person' from the name of the variable 'youngPerson'"),
        FindingSpec("6️⃣", message: "remove the suffix 'Game' from the name of the variable 'basketballGame'"),
        FindingSpec("7️⃣", message: "remove the suffix 'Game' from the name of the variable 'baseballGame'"),
        FindingSpec("8️⃣", message: "remove the suffix 'Session' from the name of the variable 'sharedSession'"),
        FindingSpec("9️⃣", message: "remove the suffix 'Cookie' from the name of the variable 'chocolateChipCookie'"),
      ]
    )
  }

  func testDoNotDiagnoseUnrelatedType() {
    assertLint(
      DontRepeatTypeInStaticProperties.self,
      """
      extension A {
        static let b = C()
      }
      extension UIImage {
        static let fooImage: Int
      }
      """
    )
  }

  func testDottedExtendedType() {
    assertLint(
      DontRepeatTypeInStaticProperties.self,
      """
      extension Dotted.Thing {
        static let 1️⃣defaultThing: Dotted.Thing
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: "remove the suffix 'Thing' from the name of the variable 'defaultThing'")
      ]
    )
  }

  func testDottedExtendedTypeWithNamespacePrefix() {
    assertLint(
      DontRepeatTypeInStaticProperties.self,
      """
      extension Dotted.RANDThing {
        static let 1️⃣defaultThing: Dotted.RANDThing
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: "remove the suffix 'Thing' from the name of the variable 'defaultThing'")
      ]
    )
  }

  func testSelfType() {
    assertLint(
      DontRepeatTypeInStaticProperties.self,
      """
      extension Dotted.Thing {
        static let 1️⃣defaultThing: Self
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: "remove the suffix 'Thing' from the name of the variable 'defaultThing'")
      ]
    )
  }

  func testDottedExtendedTypeInitializer() {
    assertLint(
      DontRepeatTypeInStaticProperties.self,
      """
      extension Dotted.Thing {
        static let 1️⃣defaultThing = Dotted.Thing()
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: "remove the suffix 'Thing' from the name of the variable 'defaultThing'")
      ]
    )
  }

  func testExplicitInitializer() {
    assertLint(
      DontRepeatTypeInStaticProperties.self,
      """
      struct Foo {
        static let 1️⃣defaultFoo = Foo.init()
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: "remove the suffix 'Foo' from the name of the variable 'defaultFoo'")
      ]
    )
  }

  func testSelfTypeInitializer() {
    assertLint(
      DontRepeatTypeInStaticProperties.self,
      """
      struct Foo {
        static let 1️⃣defaultFoo = Self()
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: "remove the suffix 'Foo' from the name of the variable 'defaultFoo'")
      ]
    )
  }

  func testIgnoreSingleDecl() {
    assertLint(
      DontRepeatTypeInStaticProperties.self,
      """
      struct Foo {
        // swift-format-ignore: DontRepeatTypeInStaticProperties
        static let defaultFoo: Foo
        static let 1️⃣alternateFoo: Foo
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: "remove the suffix 'Foo' from the name of the variable 'alternateFoo'")
      ]
    )
  }
}
