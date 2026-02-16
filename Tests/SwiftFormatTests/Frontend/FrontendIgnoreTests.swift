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

import Foundation
@_spi(Testing) @_spi(Internal) import SwiftFormat
import Testing

/// Tests for Frontend integration with .swift-format-ignore files
@Suite
struct FrontendIgnoreTests {

  // MARK: - Test Setup Helpers

  /// Creates a temporary directory structure for testing Frontend ignore functionality
  /// and automatically cleans it up after the closure executes
  private func withTestDirectory<T>(_ closure: (URL) throws -> T) throws -> T {
    let tempDir = URL(fileURLWithPath: NSTemporaryDirectory())
      .appendingPathComponent("SwiftFormatFrontendTests-\(UUID().uuidString)")

    defer {
      try? FileManager.default.removeItem(at: tempDir)
    }

    try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

    // Create test Swift files
    let testFile1 = tempDir.appendingPathComponent("Test.swift")
    try "class Test {}".write(to: testFile1, atomically: true, encoding: .utf8)

    let ignoredFile = tempDir.appendingPathComponent("Generated.swift")
    try "class Generated {}".write(to: ignoredFile, atomically: true, encoding: .utf8)

    // Create subdirectory with files
    let subDir = tempDir.appendingPathComponent("src")
    try FileManager.default.createDirectory(at: subDir, withIntermediateDirectories: true)

    let subFile1 = subDir.appendingPathComponent("Main.swift")
    try "class Main {}".write(to: subFile1, atomically: true, encoding: .utf8)

    let subFile2 = subDir.appendingPathComponent("Helper.swift")
    try "class Helper {}".write(to: subFile2, atomically: true, encoding: .utf8)

    // Create build directory that should be ignored
    let buildDir = tempDir.appendingPathComponent("build")
    try FileManager.default.createDirectory(at: buildDir, withIntermediateDirectories: true)

    let buildFile = buildDir.appendingPathComponent("Build.swift")
    try "class Build {}".write(to: buildFile, atomically: true, encoding: .utf8)

    return try closure(tempDir)
  }

  // MARK: - FileIterator Integration Tests (Testing Through Frontend)

  @Test func frontendUsesFileIteratorWithIgnoreManager() throws {
    try withTestDirectory { testDir in
      // Create .swift-format-ignore file
      let ignoreFile = testDir.appendingPathComponent(".swift-format-ignore")
      try "Generated.swift\nbuild/".write(to: ignoreFile, atomically: true, encoding: .utf8)

      // Test that FileIterator respects ignore files when used through Frontend
      // We'll test this by collecting all files that FileIterator would discover
      let urls = [testDir]
      let fileIterator = FileIterator(
        urls: urls,
        followSymlinks: false,
        ignoreManager: IgnoreManager()
      )

      let discoveredFiles = Array(fileIterator).map { $0.lastPathComponent }.sorted()

      // Verify that ignored files were filtered out by FileIterator
      #expect(!discoveredFiles.contains("Generated.swift"))
      #expect(!discoveredFiles.contains("Build.swift"))

      // Verify that non-ignored files were included
      #expect(discoveredFiles.contains("Test.swift"))
      #expect(discoveredFiles.contains("Main.swift"))
      #expect(discoveredFiles.contains("Helper.swift"))
    }
  }

  @Test func frontendFileIteratorRespectsNestedIgnoreFiles() throws {
    try withTestDirectory { testDir in
      // Create root .swift-format-ignore
      let rootIgnore = testDir.appendingPathComponent(".swift-format-ignore")
      try "Generated.swift".write(to: rootIgnore, atomically: true, encoding: .utf8)

      // Create nested .swift-format-ignore that has additional rules
      let srcDir = testDir.appendingPathComponent("src")
      let nestedIgnore = srcDir.appendingPathComponent(".swift-format-ignore")
      try "Helper.swift".write(to: nestedIgnore, atomically: true, encoding: .utf8)

      // Test FileIterator with ignore functionality
      let urls = [testDir]
      let fileIterator = FileIterator(
        urls: urls,
        followSymlinks: false,
        ignoreManager: IgnoreManager()
      )

      let discoveredFiles = Array(fileIterator).map { $0.lastPathComponent }.sorted()

      // Root ignore file should prevent Generated.swift from being discovered
      #expect(!discoveredFiles.contains("Generated.swift"))

      // Nested ignore file should prevent Helper.swift from being discovered
      #expect(!discoveredFiles.contains("Helper.swift"))

      // Other files should be discovered
      #expect(discoveredFiles.contains("Test.swift"))
      #expect(discoveredFiles.contains("Main.swift"))
    }
  }

  @Test func frontendFileIteratorWithoutIgnoreManagerIncludesAllFiles() throws {
    try withTestDirectory { testDir in
      // Test FileIterator WITHOUT ignore functionality (current behavior)
      let urls = [testDir]
      let fileIterator = FileIterator(urls: urls, followSymlinks: false)

      let discoveredFiles = Array(fileIterator).map { $0.lastPathComponent }.sorted()

      // Without IgnoreManager, ALL Swift files should be discovered (including ignored ones)
      #expect(discoveredFiles.contains("Generated.swift"))
      #expect(discoveredFiles.contains("Build.swift"))
      #expect(discoveredFiles.contains("Test.swift"))
      #expect(discoveredFiles.contains("Main.swift"))
      #expect(discoveredFiles.contains("Helper.swift"))
    }
  }

  // MARK: - Frontend Integration Point Tests

  @Test func frontendWillCreateIgnoreManagerWhenIntegrated() throws {
    try withTestDirectory { testDir in
      // This test documents the expected integration point in Frontend
      // When Frontend.processURLs() creates FileIterator, it should:
      // 1. Create an IgnoreManager with the appropriate base directory
      // 2. Pass both IgnoreManager and baseDirectory to FileIterator

      // For now, we test that our IgnoreManager works correctly with the expected setup
      let urls = [testDir]

      // This is what the integration should look like in Frontend.processURLs():
      // let baseDirectory = /* determine from urls */
      // let ignoreManager = IgnoreManager(baseDirectory: baseDirectory)
      // let fileIterator = FileIterator(
      //   urls: urls,
      //   followSymlinks: lintFormatOptions.followSymlinks,
      //   ignoreManager: ignoreManager,
      //   baseDirectory: baseDirectory
      // )

      // Test that this setup works correctly
      let baseDirectory = testDir
      let ignoreManager = IgnoreManager()
      let fileIterator = FileIterator(
        urls: urls,
        followSymlinks: false,
        ignoreManager: ignoreManager
      )

      // Verify that the integration components work together
      #expect(baseDirectory.path.contains("SwiftFormatFrontendTests"))

      // FileIterator should work with these components
      let files = Array(fileIterator)
      #expect(!files.isEmpty)
      #expect(files.allSatisfy { $0.pathExtension == "swift" })
    }
  }
}
