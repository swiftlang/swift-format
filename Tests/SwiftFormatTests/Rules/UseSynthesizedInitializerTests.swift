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

final class UseSynthesizedInitializerTests: LintOrFormatRuleTestCase {
  func testMemberwiseInitializerIsDiagnosed() {
    assertLint(
      UseSynthesizedInitializer.self,
      """
      public struct Person {

        public var name: String
        let phoneNumber: String
        internal let address: String

        1️⃣init(name: String, phoneNumber: String, address: String) {
          self.name = name
          self.address = address
          self.phoneNumber = phoneNumber
        }
      }
      """,
      findings: [
        FindingSpec(
          "1️⃣",
          message: "remove this explicit initializer, which is identical to the compiler-synthesized initializer"
        )
      ]
    )
  }

  func testNestedMemberwiseInitializerIsDiagnosed() {
    assertLint(
      UseSynthesizedInitializer.self,
      """
      public struct MyContainer {
        public struct Person {
          public var name: String

          1️⃣init(name: String) {
            self.name = name
          }
        }
      }
      """,
      findings: [
        FindingSpec(
          "1️⃣",
          message: "remove this explicit initializer, which is identical to the compiler-synthesized initializer"
        )
      ]
    )
  }

  func testInternalMemberwiseInitializerIsDiagnosed() {
    assertLint(
      UseSynthesizedInitializer.self,
      """
      public struct Person {

        public var name: String
        let phoneNumber: String
        internal let address: String

        1️⃣internal init(name: String, phoneNumber: String, address: String) {
          self.name = name
          self.address = address
          self.phoneNumber = phoneNumber
        }
      }
      """,
      findings: [
        FindingSpec(
          "1️⃣",
          message: "remove this explicit initializer, which is identical to the compiler-synthesized initializer"
        )
      ]
    )
  }

  func testMemberwiseInitializerWithDefaultArgumentIsDiagnosed() {
    assertLint(
      UseSynthesizedInitializer.self,
      """
      public struct Person {

        public var name: String = "John Doe"
        let phoneNumber: String
        internal let address: String

        1️⃣init(name: String = "John Doe", phoneNumber: String, address: String) {
          self.name = name
          self.address = address
          self.phoneNumber = phoneNumber
        }
      }
      """,
      findings: [
        FindingSpec(
          "1️⃣",
          message: "remove this explicit initializer, which is identical to the compiler-synthesized initializer"
        )
      ]
    )
  }

  func testCustomInitializerVoidsSynthesizedInitializerWarning() {
    // The compiler won't create a memberwise initializer when there are any other initializers.
    // It's valid to have a memberwise initializer when there are any custom initializers.
    assertLint(
      UseSynthesizedInitializer.self,
      """
      public struct Person {

        public var name: String
        let phoneNumber: String
        private let address: String

        init(name: String, phoneNumber: String, address: String) {
          self.name = name
          self.address = address
          self.phoneNumber = phoneNumber
        }

        init(name: String, address: String) {
          self.name = name
          self.phoneNumber = "1234578910"
          self.address = address
        }
      }
      """,
      findings: []
    )
  }

  func testMemberwiseInitializerWithDefaultArgument() {
    assertLint(
      UseSynthesizedInitializer.self,
      """
      public struct Person {

        public var name: String
        let phoneNumber: String
        let address: String

        init(name: String = "Jane Doe", phoneNumber: String, address: String) {
          self.name = name
          self.address = address
          self.phoneNumber = phoneNumber
        }
      }
      """,
      findings: []
    )
  }

  func testMemberwiseInitializerWithNonMatchingDefaultValues() {
    assertLint(
      UseSynthesizedInitializer.self,
      """
      public struct Person {

        public var name: String = "John Doe"
        let phoneNumber: String
        let address: String

        init(name: String = "Jane Doe", phoneNumber: String, address: String) {
          self.name = name
          self.address = address
          self.phoneNumber = phoneNumber
        }
      }
      """,
      findings: []
    )
  }

  func testMemberwiseInitializerMissingDefaultValues() {
    // When the initializer doesn't contain a matching default argument, then it isn't equivalent to
    // the synthesized memberwise initializer.
    assertLint(
      UseSynthesizedInitializer.self,
      """
      public struct Person {

        public var name: String
        var phoneNumber: String = "+15555550101"
        let address: String

        init(name: String, phoneNumber: String, address: String) {
          self.name = name
          self.address = address
          self.phoneNumber = phoneNumber
        }
      }
      """,
      findings: []
    )
  }

  func testCustomInitializerWithMismatchedTypes() {
    assertLint(
      UseSynthesizedInitializer.self,
      """
      public struct Person {

        public var name: String
        var phoneNumber: String?
        let address: String

        init(name: String, phoneNumber: String, address: String) {
          self.name = name
          self.address = address
          self.phoneNumber = phoneNumber
        }
      }
      """,
      findings: []
    )
  }

  func testCustomInitializerWithExtraParameters() {
    assertLint(
      UseSynthesizedInitializer.self,
      """
      public struct Person {

        public var name: String
        var phoneNumber: String?
        let address: String

        init(name: String, phoneNumber: String?, address: String, anotherArg: Int) {
          self.name = name
          self.address = address
          self.phoneNumber = phoneNumber
        }
      }
      """,
      findings: []
    )
  }

  func testCustomInitializerWithExtraStatements() {
    assertLint(
      UseSynthesizedInitializer.self,
      #"""
      public struct Person {

        public var name: String
        var phoneNumber: String?
        let address: String

        init(name: String, phoneNumber: String?, address: String) {
          self.name = name
          self.address = address
          self.phoneNumber = phoneNumber

          print("phoneNumber: \(self.phoneNumber)")
        }
      }
      """#,
      findings: []
    )
  }

  func testFailableMemberwiseInitializerIsNotDiagnosed() {
    assertLint(
      UseSynthesizedInitializer.self,
      """
      public struct Person {

        public var name: String
        let phoneNumber: String
        let address: String

        init?(name: String, phoneNumber: String, address: String) {
          self.name = name
          self.address = address
          self.phoneNumber = phoneNumber
        }
      }
      """,
      findings: []
    )
  }

  func testThrowingMemberwiseInitializerIsNotDiagnosed() {
    assertLint(
      UseSynthesizedInitializer.self,
      """
      public struct Person {

        public var name: String
        let phoneNumber: String
        let address: String

        init(name: String, phoneNumber: String, address: String) throws {
          self.name = name
          self.address = address
          self.phoneNumber = phoneNumber
        }
      }
      """,
      findings: []
    )
  }

  func testPublicMemberwiseInitializerIsNotDiagnosed() {
    assertLint(
      UseSynthesizedInitializer.self,
      """
      public struct Person {

        public var name: String
        let phoneNumber: String
        let address: String

        public init(name: String, phoneNumber: String, address: String) {
          self.name = name
          self.address = address
          self.phoneNumber = phoneNumber
        }
      }
      """,
      findings: []
    )
  }

  func testDefaultMemberwiseInitializerIsNotDiagnosed() {
    // The synthesized initializer is private when any member is private, so an initializer with
    // default access control (i.e. internal) is not equivalent to the synthesized initializer.
    assertLint(
      UseSynthesizedInitializer.self,
      """
      public struct Person {

        let phoneNumber: String
        private let address: String

        init(phoneNumber: String, address: String) {
          self.address = address
          self.phoneNumber = phoneNumber
        }
      }
      """,
      findings: []
    )
  }

  func testPrivateMemberwiseInitializerWithPrivateMemberIsDiagnosed() {
    // The synthesized initializer is private when any member is private, so a private initializer
    // is equivalent to the synthesized initializer.
    assertLint(
      UseSynthesizedInitializer.self,
      """
      public struct Person {

        let phoneNumber: String
        private let address: String

        1️⃣private init(phoneNumber: String, address: String) {
          self.address = address
          self.phoneNumber = phoneNumber
        }
      }
      """,
      findings: [
        FindingSpec(
          "1️⃣",
          message: "remove this explicit initializer, which is identical to the compiler-synthesized initializer"
        )
      ]
    )
  }

  func testFileprivateMemberwiseInitializerWithFileprivateMemberIsDiagnosed() {
    // The synthesized initializer is fileprivate when any member is fileprivate, so a fileprivate
    // initializer is equivalent to the synthesized initializer.
    assertLint(
      UseSynthesizedInitializer.self,
      """
      public struct Person {

        let phoneNumber: String
        fileprivate let address: String

        1️⃣fileprivate init(phoneNumber: String, address: String) {
          self.address = address
          self.phoneNumber = phoneNumber
        }
      }
      """,
      findings: [
        FindingSpec(
          "1️⃣",
          message: "remove this explicit initializer, which is identical to the compiler-synthesized initializer"
        )
      ]
    )
  }

  func testCustomSetterAccessLevel() {
    // When a property has a different access level for its setter, the setter's access level
    // doesn't change the access level of the synthesized initializer.
    assertLint(
      UseSynthesizedInitializer.self,
      """
      public struct Person {
        let phoneNumber: String
        private(set) let address: String

        1️⃣init(phoneNumber: String, address: String) {
          self.address = address
          self.phoneNumber = phoneNumber
        }
      }

      public struct Person2 {
        fileprivate let phoneNumber: String
        private(set) let address: String

        2️⃣fileprivate init(phoneNumber: String, address: String) {
          self.address = address
          self.phoneNumber = phoneNumber
        }
      }

      public struct Person3 {
        fileprivate(set) let phoneNumber: String
        private(set) let address: String

        3️⃣init(phoneNumber: String, address: String) {
          self.address = address
          self.phoneNumber = phoneNumber
        }
      }

      public struct Person4 {
        private fileprivate(set) let phoneNumber: String
        private(set) let address: String

        init(phoneNumber: String, address: String) {
          self.address = address
          self.phoneNumber = phoneNumber
        }
      }
      """,
      findings: [
        FindingSpec(
          "1️⃣",
          message: "remove this explicit initializer, which is identical to the compiler-synthesized initializer"
        ),
        FindingSpec(
          "2️⃣",
          message: "remove this explicit initializer, which is identical to the compiler-synthesized initializer"
        ),
        FindingSpec(
          "3️⃣",
          message: "remove this explicit initializer, which is identical to the compiler-synthesized initializer"
        ),
      ]
    )
  }

  func testMemberwiseInitializerWithAttributeIsNotDiagnosed() {
    assertLint(
      UseSynthesizedInitializer.self,
      """
      public struct Person {
        let phoneNumber: String
        let address: String

        @inlinable init(phoneNumber: String, address: String) {
          self.address = address
          self.phoneNumber = phoneNumber
        }
      }
      """,
      findings: []
    )
  }
}
