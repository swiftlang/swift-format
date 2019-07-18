import Foundation
import SwiftSyntax
import XCTest

@testable import SwiftFormatRules

public class UseSynthesizedInitializerTests: DiagnosingTestCase {
  public func testRedundantCustomInitializer() {
    let input =
      """
      public struct Person {

        public var name: String = "John Doe"
        let phoneNumber: String?
        private let address: String = "123 Happy St"

        init(name: String = "John Doe", phoneNumber: String?, address: String) {
          self.name = name
          self.address = address
          self.phoneNumber = phoneNumber
        }

        init(name: String, phoneNumber: String?, address: String) {
          self.name = name
          self.phoneNumber = "1234578910"
          self.address = address
        }
        init(name: String, phoneNumber: String? = "123456789", address: String) {
          self.name = name
          self.phoneNumber = phoneNumber
          self.address = address
        }
        public init(name: String, phoneNumber: String?, address: String) {
          self.name = name
          self.phoneNumber = phoneNumber
          self.address = address
        }
        init?(name: String, phoneNumber: String?, address: String) {
          self.name = name
          self.phoneNumber = phoneNumber
          self.address = address
        }
        init(name: String, phoneNumber: String?, address: String) throws {
          self.name = name
          self.phoneNumber = phoneNumber
          self.address = address
        }
      }
      """
    performLint(UseSynthesizedInitializer.self, input: input)
    XCTAssertDiagnosed(.removeRedundantInitializer)
    XCTAssertNotDiagnosed(.removeRedundantInitializer)
  }
}
