@_spi(Internal) import SwiftFormat
import XCTest

final class IgnoreFileTests: XCTestCase {
  var testTreeURL: URL?

  /// Description of a file or directory tree to create for testing.
  enum TestTree {
    case file(String, String)
    case directory(String, [TestTree])
  }

  override func tearDown() {
    // Clean up any test tree after each test.
    if let testTreeURL {
      // try? FileManager.default.removeItem(at: testTreeURL)
    }
  }

  /// Make a temporary directory tree for testing.
  /// Returns the URL of the root directory.
  /// The tree will be cleaned up after the test.
  /// If a tree is already set up, it will be cleaned up first.
  func makeTempTree(_ tree: TestTree) throws -> URL {
    if let testTreeURL {
      try? FileManager.default.removeItem(at: testTreeURL)
    }
    let tempDir = FileManager.default.temporaryDirectory
    let tempURL = tempDir.appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(at: tempURL, withIntermediateDirectories: true)
    try writeTree(tree, to: tempURL)
    testTreeURL = tempURL
    return tempURL
  }

  /// Write a file or directory tree to the given root URL.
  func writeTree(_ tree: TestTree, to root: URL) throws {
    switch tree {
    case let .file(name, contents):
      print("Writing file \(name) to \(root)")
      try contents.write(to: root.appendingPathComponent(name), atomically: true, encoding: .utf8)
    case let .directory(name, children):
      let directory = root.appendingPathComponent(name)
      try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
      for child in children {
        try writeTree(child, to: directory)
      }
    }
  }

  func testMissingIgnoreFile() throws {
    let url = URL(filePath: "/")
    XCTAssertNil(try IgnoreFile(forDirectory: url))
    XCTAssertNil(try IgnoreFile(for: url.appending(path: "file.swift")))
  }

  func testValidIgnoreFile() throws {
    let url = try makeTempTree(.file(IgnoreFile.standardFileName, "*"))
    XCTAssertNotNil(try IgnoreFile(forDirectory: url))
    XCTAssertNotNil(try IgnoreFile(for: url.appending(path: "file.swift")))
  }

  func testInvalidIgnoreFile() throws {
    let url = try makeTempTree(.file(IgnoreFile.standardFileName, "this is an invalid pattern"))
    XCTAssertThrowsError(try IgnoreFile(forDirectory: url))
    XCTAssertThrowsError(try IgnoreFile(for: url.appending(path: "file.swift")))
  }

  func testEmptyIgnoreFile() throws {
    XCTAssertThrowsError(try IgnoreFile(""))
  }

  func testNestedIgnoreFile() throws {
    let url = try makeTempTree(.file(IgnoreFile.standardFileName, "*"))
    let fileInSubdirectory = url.appendingPathComponent("subdirectory").appending(path: "file.swift")
    XCTAssertNotNil(try IgnoreFile(for: fileInSubdirectory))
  }

  func testIterateWithIgnoreFile() throws {
    let url = try makeTempTree(.file(IgnoreFile.standardFileName, "*"))
    let iterator = FileIterator(urls: [url], followSymlinks: false)
    let files = Array(iterator)
    XCTAssertEqual(files.count, 0)
  }

  func testIterateWithInvalidIgnoreFile() throws {
    let url = try makeTempTree(.file(IgnoreFile.standardFileName, "this file is invalid"))
    let iterator = FileIterator(urls: [url], followSymlinks: false)
    let files = Array(iterator)
    XCTAssertEqual(files.count, 1)
    XCTAssertTrue(files.first?.lastPathComponent == IgnoreFile.standardFileName)
  }

  func testIterateWithNestedIgnoreFile() throws {
    let url = try makeTempTree(
      .directory(
        "Source",
        [
          .directory(
            "Ignored",
            [
              .file(IgnoreFile.standardFileName, "*"),
              .file("file.swift", "contents"),
            ]
          ),
          .directory(
            "Not Ignored",
            [
              .file("file.swift", "contents")
            ]
          ),
        ]
      )
    )

    XCTAssertNil(try IgnoreFile(forDirectory: url))
    XCTAssertNil(try IgnoreFile(for: url.appending(path: "Source/file.swift")))
    XCTAssertNotNil(try IgnoreFile(for: url.appending(path: "Source/Ignored/file.swift")))
    let iterator = FileIterator(urls: [url], followSymlinks: false)
    let files = Array(iterator)
    print(files)
    XCTAssertEqual(files.count, 1)
    XCTAssertEqual(files.first?.lastPathComponent, "file.swift")
  }

}
