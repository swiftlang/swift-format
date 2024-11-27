import SwiftFormat
import XCTest

final class IgnoreFileTests: XCTestCase {

  func testMissingIgnoreFile() throws {
    let url = Bundle.module.url(forResource: "missing", withExtension: "", subdirectory: "Ignore Files")
    XCTAssertNotNil(url)
    XCTAssertNil(try IgnoreFile(forDirectory: url!))
  }

  func testValidIgnoreFile() throws {
    let url = Bundle.module.url(forResource: "valid", withExtension: "", subdirectory: "Ignore Files")
    XCTAssertNotNil(url)
    XCTAssertNotNil(try IgnoreFile(forDirectory: url!))
  }

  func testInvalidIgnoreFile() throws {
    let url = Bundle.module.url(forResource: "invalid", withExtension: "", subdirectory: "Ignore Files")
    XCTAssertNotNil(url)
    XCTAssertThrowsError(try IgnoreFile(forDirectory: url!))
  }

  func testEmptyIgnoreFile() throws {
    let url = Bundle.module.url(forResource: "empty", withExtension: "", subdirectory: "Ignore Files")
    XCTAssertNotNil(url)
    XCTAssertThrowsError(try IgnoreFile(forDirectory: url!))
  }

}
