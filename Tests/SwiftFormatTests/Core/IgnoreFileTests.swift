import SwiftFormat
import XCTest

final class IgnoreFileTests: XCTestCase {

  func testMissingIgnoreFile() throws {
    let url = Bundle.module.url(forResource: "missing", withExtension: "", subdirectory: "Ignore Files")
    XCTAssertNotNil(url)
    XCTAssertNil(try IgnoreFile(forDirectory: url!))
    XCTAssertNil(try IgnoreFile(for: url!.appending(path:"file.swift")))
  }

  func testValidIgnoreFile() throws {
    let url = Bundle.module.url(forResource: "valid", withExtension: "", subdirectory: "Ignore Files")
    XCTAssertNotNil(url)
    XCTAssertNotNil(try IgnoreFile(forDirectory: url!))
    XCTAssertNotNil(try IgnoreFile(for: url!.appending(path:"file.swift")))
  }

  func testInvalidIgnoreFile() throws {
    let url = Bundle.module.url(forResource: "invalid", withExtension: "", subdirectory: "Ignore Files")
    XCTAssertNotNil(url)
    XCTAssertThrowsError(try IgnoreFile(forDirectory: url!))
    XCTAssertThrowsError(try IgnoreFile(for: url!.appending(path:"file.swift")))
  }

  func testEmptyIgnoreFile() throws {
    let url = Bundle.module.url(forResource: "empty", withExtension: "", subdirectory: "Ignore Files")
    XCTAssertNotNil(url)
    XCTAssertThrowsError(try IgnoreFile(forDirectory: url!))
    XCTAssertThrowsError(try IgnoreFile(for: url!.appending(path:"file.swift")))
  }

  func testNestedIgnoreFile() throws {
    let url = Bundle.module.url(forResource: "nested", withExtension: "", subdirectory: "Ignore Files")
    XCTAssertNotNil(url)
    let subdirectory = url!.appendingPathComponent("subdirectory").appending(path: "file.swift")
    XCTAssertNotNil(try IgnoreFile(for: subdirectory))
  }

}
