import Foundation
import SwiftSyntax
import XCTest

@testable import SwiftFormatRules

public class UseSynthesizedInitializerTests: DiagnosingTestCase {
  public func testMemberwiseInitializerIsDiagnosed() {
    let input =
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
      }
      """

    performLint(UseSynthesizedInitializer.self, input: input)
    XCTAssertDiagnosed(.removeRedundantInitializer)
    XCTAssertNotDiagnosed(.removeRedundantInitializer)
  }

  public func testMemberwiseInitializerWithDefaultArgumentIsDiagnosed() {
     let input =
       """
       public struct Person {

         public var name: String = "John Doe"
         let phoneNumber: String
         private let address: String

         init(name: String = "John Doe", phoneNumber: String, address: String) {
           self.name = name
           self.address = address
           self.phoneNumber = phoneNumber
         }
       }
       """

     performLint(UseSynthesizedInitializer.self, input: input)
     XCTAssertDiagnosed(.removeRedundantInitializer)
     XCTAssertNotDiagnosed(.removeRedundantInitializer)
   }

  public func testCustomInitializerVoidsSynthesizedInitializerWarning() {
    // The compiler won't create a memberwise initializer when there are any other initializers.
    // It's valid to have a memberwise initializer when there are any custom initializers.
    let input =
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

        init(name: String, phoneNumber: String, address: String) {
          self.name = name
          self.phoneNumber = "1234578910"
          self.address = address
        }
      }
      """

    performLint(UseSynthesizedInitializer.self, input: input)
    XCTAssertNotDiagnosed(.removeRedundantInitializer)
  }

  public func testMemberwiseInitializerWithDefaultArgument() {
     let input =
       """
       public struct Person {

         public var name: String
         let phoneNumber: String
         private let address: String

         init(name: String = "Jane Doe", phoneNumber: String, address: String) {
           self.name = name
           self.address = address
           self.phoneNumber = phoneNumber
         }
       }
       """

    performLint(UseSynthesizedInitializer.self, input: input)
    XCTAssertNotDiagnosed(.removeRedundantInitializer)
  }

  public func testMemberwiseInitializerWithNonMatchingDefaultValues() {
     let input =
       """
       public struct Person {

         public var name: String = "John Doe"
         let phoneNumber: String
         private let address: String

         init(name: String = "Jane Doe", phoneNumber: String, address: String) {
           self.name = name
           self.address = address
           self.phoneNumber = phoneNumber
         }
       }
       """

    performLint(UseSynthesizedInitializer.self, input: input)
    XCTAssertNotDiagnosed(.removeRedundantInitializer)
  }

  public func testMemberwiseInitializerMissingDefaultValues() {
    // When the initializer doesn't contain a matching default argument, then it isn't equivalent to
    // the synthesized memberwise initializer.
    let input =
      """
      public struct Person {

        public var name: String
        var phoneNumber: String = "+15555550101"
        private let address: String

        init(name: String, phoneNumber: String, address: String) {
          self.name = name
          self.address = address
          self.phoneNumber = phoneNumber
        }
      }
      """

    performLint(UseSynthesizedInitializer.self, input: input)
    XCTAssertNotDiagnosed(.removeRedundantInitializer)
  }

  public func testCustomInitializerWithMismatchedTypes() {
    let input =
      """
      public struct Person {

        public var name: String
        var phoneNumber: String?
        private let address: String

        init(name: String, phoneNumber: String, address: String) {
          self.name = name
          self.address = address
          self.phoneNumber = phoneNumber
        }
      }
      """

    performLint(UseSynthesizedInitializer.self, input: input)
    XCTAssertNotDiagnosed(.removeRedundantInitializer)
  }

  public func testCustomInitializerWithExtraParameters() {
    let input =
      """
      public struct Person {

        public var name: String
        var phoneNumber: String?
        private let address: String

        init(name: String, phoneNumber: String?, address: String, anotherArg: Int) {
          self.name = name
          self.address = address
          self.phoneNumber = phoneNumber
        }
      }
      """

    performLint(UseSynthesizedInitializer.self, input: input)
    XCTAssertNotDiagnosed(.removeRedundantInitializer)
  }

  public func testCustomInitializerWithExtraStatements() {
    let input =
      #"""
      public struct Person {

        public var name: String
        var phoneNumber: String?
        private let address: String

        init(name: String, phoneNumber: String?, address: String) {
          self.name = name
          self.address = address
          self.phoneNumber = phoneNumber

          print("phoneNumber: \(self.phoneNumber)")
        }
      }
      """#

    performLint(UseSynthesizedInitializer.self, input: input)
    XCTAssertNotDiagnosed(.removeRedundantInitializer)
  }

  public func testFailableMemberwiseInitializerIsNotDiagnosed() {
    let input =
      """
      public struct Person {

        public var name: String
        let phoneNumber: String
        private let address: String

        init?(name: String, phoneNumber: String, address: String) {
          self.name = name
          self.address = address
          self.phoneNumber = phoneNumber
        }
      }
      """

    performLint(UseSynthesizedInitializer.self, input: input)
    XCTAssertNotDiagnosed(.removeRedundantInitializer)
  }

  public func testThrowingMemberwiseInitializerIsNotDiagnosed() {
    let input =
      """
      public struct Person {

        public var name: String
        let phoneNumber: String
        private let address: String

        init(name: String, phoneNumber: String, address: String) throws {
          self.name = name
          self.address = address
          self.phoneNumber = phoneNumber
        }
      }
      """

    performLint(UseSynthesizedInitializer.self, input: input)
    XCTAssertNotDiagnosed(.removeRedundantInitializer)
  }

  public func testPublicMemberwiseInitializerIsNotDiagnosed() {
    let input =
      """
      public struct Person {

        public var name: String
        let phoneNumber: String
        private let address: String

        public init(name: String, phoneNumber: String, address: String) {
          self.name = name
          self.address = address
          self.phoneNumber = phoneNumber
        }
      }
      """

    performLint(UseSynthesizedInitializer.self, input: input)
    XCTAssertNotDiagnosed(.removeRedundantInitializer)
  }
}
