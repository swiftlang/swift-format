@_spi(Internal) import SwiftFormat
import XCTest

final class FileIteratorTests: XCTestCase {
  private var tmpdir: URL!

  override func setUpWithError() throws {
    tmpdir = try FileManager.default.url(
      for: .itemReplacementDirectory,
      in: .userDomainMask,
      appropriateFor: FileManager.default.temporaryDirectory,
      create: true
    )

    // Create a simple file tree used by the tests below.
    try touch("project/real1.swift")
    try touch("project/real2.swift")
    try touch("project/.hidden.swift")
    try touch("project/.build/generated.swift")
    try symlink("project/link.swift", to: "project/.hidden.swift")
  }

  override func tearDownWithError() throws {
    try FileManager.default.removeItem(at: tmpdir)
  }

  func testNoFollowSymlinks() {
    let seen = allFilesSeen(iteratingOver: [tmpdir], followSymlinks: false)
    XCTAssertEqual(seen.count, 2)
    XCTAssertTrue(seen.contains { $0.hasSuffix("project/real1.swift") })
    XCTAssertTrue(seen.contains { $0.hasSuffix("project/real2.swift") })
  }

  func testFollowSymlinks() {
    let seen = allFilesSeen(iteratingOver: [tmpdir], followSymlinks: true)
    XCTAssertEqual(seen.count, 3)
    XCTAssertTrue(seen.contains { $0.hasSuffix("project/real1.swift") })
    XCTAssertTrue(seen.contains { $0.hasSuffix("project/real2.swift") })
    // Hidden but found through the visible symlink project/link.swift
    XCTAssertTrue(seen.contains { $0.hasSuffix("project/.hidden.swift") })
  }

  func testTraversesHiddenFilesIfExplicitlySpecified() {
    let seen = allFilesSeen(
      iteratingOver: [tmpURL("project/.build"), tmpURL("project/.hidden.swift")],
      followSymlinks: false
    )
    XCTAssertEqual(seen.count, 2)
    XCTAssertTrue(seen.contains { $0.hasSuffix("project/.build/generated.swift") })
    XCTAssertTrue(seen.contains { $0.hasSuffix("project/.hidden.swift") })
  }

  func testDoesNotFollowSymlinksIfFollowSymlinksIsFalseEvenIfExplicitlySpecified() {
    // Symlinks are not traversed even if `followSymlinks` is false even if they are explicitly
    // passed to the iterator. This is meant to avoid situations where a symlink could be hidden by
    // shell expansion; for example, if the user writes `swift-format --no-follow-symlinks *`, if
    // the current directory contains a symlink, they would probably *not* expect it to be followed.
    let seen = allFilesSeen(iteratingOver: [tmpURL("project/link.swift")], followSymlinks: false)
    XCTAssertTrue(seen.isEmpty)
  }
}

extension FileIteratorTests {
  /// Returns a URL to a file or directory in the test's temporary space.
  private func tmpURL(_ path: String) -> URL {
    return tmpdir.appendingPathComponent(path, isDirectory: false)
  }

  /// Create an empty file at the given path in the test's temporary space.
  private func touch(_ path: String) throws {
    let fileURL = tmpURL(path)
    try FileManager.default.createDirectory(
      at: fileURL.deletingLastPathComponent(),
      withIntermediateDirectories: true
    )
    struct FailedToCreateFileError: Error {
      let url: URL
    }
    if !FileManager.default.createFile(atPath: fileURL.path, contents: Data()) {
      throw FailedToCreateFileError(url: fileURL)
    }
  }

  /// Create a symlink between files or directories in the test's temporary space.
  private func symlink(_ source: String, to target: String) throws {
    try FileManager.default.createSymbolicLink(
      at: tmpURL(source),
      withDestinationURL: tmpURL(target)
    )
  }

  /// Computes the list of all files seen by using `FileIterator` to iterate over the given URLs.
  private func allFilesSeen(iteratingOver urls: [URL], followSymlinks: Bool) -> [String] {
    let iterator = FileIterator(urls: urls, followSymlinks: followSymlinks)
    var seen: [String] = []
    for next in iterator {
      seen.append(next.path)
    }
    return seen
  }
}
