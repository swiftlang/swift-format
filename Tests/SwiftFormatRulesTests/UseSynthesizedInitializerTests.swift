import SwiftFormatRules

final class UseSynthesizedInitializerTests: LintOrFormatRuleTestCase {
  override func setUp() {
    self.shouldCheckForUnassertedDiagnostics = true
  }

  func testMemberwiseInitializerIsDiagnosed() {
    let input =
      """
      public struct Person {

        public var name: String
        let phoneNumber: String
        internal let address: String

        init(name: String, phoneNumber: String, address: String) {
          self.name = name
          self.address = address
          self.phoneNumber = phoneNumber
        }
      }
      """

    performLint(UseSynthesizedInitializer.self, input: input)
    XCTAssertDiagnosed(.removeRedundantInitializer, line: 7)
  }

  func testInternalMemberwiseInitializerIsDiagnosed() {
    let input =
      """
      public struct Person {

        public var name: String
        let phoneNumber: String
        internal let address: String

        internal init(name: String, phoneNumber: String, address: String) {
          self.name = name
          self.address = address
          self.phoneNumber = phoneNumber
        }
      }
      """

    performLint(UseSynthesizedInitializer.self, input: input)
    XCTAssertDiagnosed(.removeRedundantInitializer, line: 7)
  }

  func testMemberwiseInitializerWithDefaultArgumentIsDiagnosed() {
     let input =
       """
       public struct Person {

         public var name: String = "John Doe"
         let phoneNumber: String
         internal let address: String

         init(name: String = "John Doe", phoneNumber: String, address: String) {
           self.name = name
           self.address = address
           self.phoneNumber = phoneNumber
         }
       }
       """

    performLint(UseSynthesizedInitializer.self, input: input)
    XCTAssertDiagnosed(.removeRedundantInitializer, line: 7)
   }

  func testCustomInitializerVoidsSynthesizedInitializerWarning() {
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

  func testMemberwiseInitializerWithDefaultArgument() {
     let input =
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
       """

    performLint(UseSynthesizedInitializer.self, input: input)
    XCTAssertNotDiagnosed(.removeRedundantInitializer)
  }

  func testMemberwiseInitializerWithNonMatchingDefaultValues() {
     let input =
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
       """

    performLint(UseSynthesizedInitializer.self, input: input)
    XCTAssertNotDiagnosed(.removeRedundantInitializer)
  }

  func testMemberwiseInitializerMissingDefaultValues() {
    // When the initializer doesn't contain a matching default argument, then it isn't equivalent to
    // the synthesized memberwise initializer.
    let input =
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
      """

    performLint(UseSynthesizedInitializer.self, input: input)
    XCTAssertNotDiagnosed(.removeRedundantInitializer)
  }

  func testCustomInitializerWithMismatchedTypes() {
    let input =
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
      """

    performLint(UseSynthesizedInitializer.self, input: input)
    XCTAssertNotDiagnosed(.removeRedundantInitializer)
  }

  func testCustomInitializerWithExtraParameters() {
    let input =
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
      """

    performLint(UseSynthesizedInitializer.self, input: input)
    XCTAssertNotDiagnosed(.removeRedundantInitializer)
  }

  func testCustomInitializerWithExtraStatements() {
    let input =
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
      """#

    performLint(UseSynthesizedInitializer.self, input: input)
    XCTAssertNotDiagnosed(.removeRedundantInitializer)
  }

  func testFailableMemberwiseInitializerIsNotDiagnosed() {
    let input =
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
      """

    performLint(UseSynthesizedInitializer.self, input: input)
    XCTAssertNotDiagnosed(.removeRedundantInitializer)
  }

  func testThrowingMemberwiseInitializerIsNotDiagnosed() {
    let input =
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
      """

    performLint(UseSynthesizedInitializer.self, input: input)
    XCTAssertNotDiagnosed(.removeRedundantInitializer)
  }

  func testPublicMemberwiseInitializerIsNotDiagnosed() {
    let input =
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
      """

    performLint(UseSynthesizedInitializer.self, input: input)
    XCTAssertNotDiagnosed(.removeRedundantInitializer)
  }

  func testDefaultMemberwiseInitializerIsNotDiagnosed() {
    // The synthesized initializer is private when any member is private, so an initializer with
    // default access control (i.e. internal) is not equivalent to the synthesized initializer.
    let input =
      """
      public struct Person {

        let phoneNumber: String
        private let address: String

        init(phoneNumber: String, address: String) {
          self.address = address
          self.phoneNumber = phoneNumber
        }
      }
      """

    performLint(UseSynthesizedInitializer.self, input: input)
    XCTAssertNotDiagnosed(.removeRedundantInitializer)
  }

  func testPrivateMemberwiseInitializerWithPrivateMemberIsDiagnosed() {
    // The synthesized initializer is private when any member is private, so a private initializer
    // is equivalent to the synthesized initializer.
    let input =
      """
      public struct Person {

        let phoneNumber: String
        private let address: String

        private init(phoneNumber: String, address: String) {
          self.address = address
          self.phoneNumber = phoneNumber
        }
      }
      """

    performLint(UseSynthesizedInitializer.self, input: input)
    XCTAssertDiagnosed(.removeRedundantInitializer, line: 6)
  }

  func testFileprivateMemberwiseInitializerWithFileprivateMemberIsDiagnosed() {
    // The synthesized initializer is fileprivate when any member is fileprivate, so a fileprivate
    // initializer is equivalent to the synthesized initializer.
    let input =
      """
      public struct Person {

        let phoneNumber: String
        fileprivate let address: String

        fileprivate init(phoneNumber: String, address: String) {
          self.address = address
          self.phoneNumber = phoneNumber
        }
      }
      """

    performLint(UseSynthesizedInitializer.self, input: input)
    XCTAssertDiagnosed(.removeRedundantInitializer, line: 6)
  }

  func testCustomSetterAccessLevel() {
    // When a property has a different access level for its setter, the setter's access level
    // doesn't change the access level of the synthesized initializer.
    let input =
      """
      public struct Person {
        let phoneNumber: String
        private(set) let address: String

        init(phoneNumber: String, address: String) {
          self.address = address
          self.phoneNumber = phoneNumber
        }
      }

      public struct Person2 {
        fileprivate let phoneNumber: String
        private(set) let address: String

        fileprivate init(phoneNumber: String, address: String) {
          self.address = address
          self.phoneNumber = phoneNumber
        }
      }

      public struct Person3 {
        fileprivate(set) let phoneNumber: String
        private(set) let address: String

        init(phoneNumber: String, address: String) {
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
      """

    performLint(UseSynthesizedInitializer.self, input: input)
    XCTAssertDiagnosed(.removeRedundantInitializer, line: 5)
    XCTAssertDiagnosed(.removeRedundantInitializer, line: 15)
    XCTAssertDiagnosed(.removeRedundantInitializer, line: 25)
  }
}
