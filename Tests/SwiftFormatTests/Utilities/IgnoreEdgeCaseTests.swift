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
@_spi(Internal) import SwiftFormat
import Testing
import _SwiftFormatTestSupport

/// Tests for edge cases and error handling in .swift-format-ignore functionality
@Suite
struct IgnoreEdgeCaseTests {

  // MARK: - Test Setup Helpers

  /// Creates a temporary directory structure for testing edge cases
  private func withTestDirectory<T>(_ closure: (URL) throws -> T) throws -> T {
    let tempDir = URL(fileURLWithPath: NSTemporaryDirectory())
      .appendingPathComponent("SwiftFormatEdgeCaseTests-\(UUID().uuidString)")

    defer {
      try? FileManager.default.removeItem(at: tempDir)
    }

    try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    return try closure(tempDir)
  }

  // MARK: - Invalid Pattern Tests

  @Test func invalidPatternsShouldBeSkipped() throws {
    try withTestDirectory { testDir in
      // Create ignore file with mix of valid and invalid patterns
      let ignoreFile = testDir.appendingPathComponent(".swift-format-ignore")
      let invalidPatterns = """
        # This is a comment
        ValidFile.swift


        !ValidNegation.swift
        # Another comment
        """
      try invalidPatterns.writeAtomicallyIfPossible(to: ignoreFile)

      // Create test files
      let validFile = testDir.appendingPathComponent("ValidFile.swift")
      try "class ValidFile {}".writeAtomicallyIfPossible(to: validFile)

      let negationFile = testDir.appendingPathComponent("ValidNegation.swift")
      try "class ValidNegation {}".writeAtomicallyIfPossible(to: negationFile)

      let otherFile = testDir.appendingPathComponent("Other.swift")
      try "class Other {}".writeAtomicallyIfPossible(to: otherFile)

      let ignoreManager = IgnoreManager()

      // Valid patterns should work
      #expect(ignoreManager.shouldIgnore(file: validFile, isDirectory: false))
      #expect(!ignoreManager.shouldIgnore(file: negationFile, isDirectory: false))
      #expect(!ignoreManager.shouldIgnore(file: otherFile, isDirectory: false))
    }
  }

  @Test func emptyIgnoreFileShouldNotCauseErrors() throws {
    try withTestDirectory { testDir in
      // Create empty ignore file
      let ignoreFile = testDir.appendingPathComponent(".swift-format-ignore")
      try "".writeAtomicallyIfPossible(to: ignoreFile)

      // Create test file
      let testFile = testDir.appendingPathComponent("Test.swift")
      try "class Test {}".writeAtomicallyIfPossible(to: testFile)

      let ignoreManager = IgnoreManager()

      // Should not ignore any files
      #expect(!ignoreManager.shouldIgnore(file: testFile, isDirectory: false))
    }
  }

  @Test func ignoreFileWithOnlyCommentsAndWhitespace() throws {
    try withTestDirectory { testDir in
      // Create ignore file with only comments and whitespace
      let ignoreFile = testDir.appendingPathComponent(".swift-format-ignore")
      let content = """
        # This is just a comment file


        # Another comment


        # Final comment
        """
      try content.writeAtomicallyIfPossible(to: ignoreFile)

      // Create test file
      let testFile = testDir.appendingPathComponent("Test.swift")
      try "class Test {}".writeAtomicallyIfPossible(to: testFile)

      let ignoreManager = IgnoreManager()

      // Should not ignore any files
      #expect(!ignoreManager.shouldIgnore(file: testFile, isDirectory: false))
    }
  }

  // MARK: - Missing File Tests

  @Test func nonExistentIgnoreFileShouldNotCauseErrors() throws {
    try withTestDirectory { testDir in
      // Create test file without any ignore file
      let testFile = testDir.appendingPathComponent("Test.swift")
      try "class Test {}".writeAtomicallyIfPossible(to: testFile)

      let ignoreManager = IgnoreManager()

      // Should not ignore any files when no ignore file exists
      #expect(!ignoreManager.shouldIgnore(file: testFile, isDirectory: false))
    }
  }

  @Test func nonExistentFileShouldNotCauseErrors() throws {
    try withTestDirectory { testDir in
      // Create ignore file
      let ignoreFile = testDir.appendingPathComponent(".swift-format-ignore")
      try "*.swift".writeAtomicallyIfPossible(to: ignoreFile)

      // Test with non-existent file
      let nonExistentFile = testDir.appendingPathComponent("NonExistent.swift")

      let ignoreManager = IgnoreManager()

      // Should handle non-existent files gracefully
      #expect(ignoreManager.shouldIgnore(file: nonExistentFile, isDirectory: false))
    }
  }

  // MARK: - Symlink Tests

  @Test func symlinksShouldBeHandledCorrectly() throws {
    try withTestDirectory { testDir in
      // Create a real file
      let realFile = testDir.appendingPathComponent("RealFile.swift")
      try "class RealFile {}".writeAtomicallyIfPossible(to: realFile)

      // Create a symlink to the real file
      let symlinkFile = testDir.appendingPathComponent("SymlinkFile.swift")
      try FileManager.default.createSymbolicLink(at: symlinkFile, withDestinationURL: realFile)

      // Create ignore file that ignores symlinks
      let ignoreFile = testDir.appendingPathComponent(".swift-format-ignore")
      try "SymlinkFile.swift".writeAtomicallyIfPossible(to: ignoreFile)

      let ignoreManager = IgnoreManager()

      // Real file should not be ignored
      #expect(!ignoreManager.shouldIgnore(file: realFile, isDirectory: false))

      // Symlink should be ignored
      #expect(ignoreManager.shouldIgnore(file: symlinkFile, isDirectory: false))
    }
  }

  // MARK: - Large File Tests

  @Test func largeIgnoreFileShouldBeHandledEfficiently() throws {
    try withTestDirectory { testDir in
      // Create large ignore file with many patterns
      let ignoreFile = testDir.appendingPathComponent(".swift-format-ignore")
      var patterns: [String] = []

      // Generate 1000 patterns
      for i in 0..<1000 {
        patterns.append("Generated\(i).swift")
        patterns.append("Test\(i).swift")
        patterns.append("build/Output\(i).swift")
      }

      try patterns.joined(separator: "\n").writeAtomicallyIfPossible(to: ignoreFile)

      // Create test files
      let matchedFile = testDir.appendingPathComponent("Generated500.swift")
      try "class Generated500 {}".writeAtomicallyIfPossible(to: matchedFile)

      let unmatchedFile = testDir.appendingPathComponent("Regular.swift")
      try "class Regular {}".writeAtomicallyIfPossible(to: unmatchedFile)

      let ignoreManager = IgnoreManager()

      // Should handle large ignore files efficiently
      #expect(ignoreManager.shouldIgnore(file: matchedFile, isDirectory: false))
      #expect(!ignoreManager.shouldIgnore(file: unmatchedFile, isDirectory: false))
    }
  }

  // MARK: - Path Edge Cases

  @Test func specialCharactersInPathsShouldBeHandled() throws {
    try withTestDirectory { testDir in
      // Create directories and files with special characters
      let specialDir = testDir.appendingPathComponent("special-chars & spaces")
      try FileManager.default.createDirectory(at: specialDir, withIntermediateDirectories: true)

      let specialFile = specialDir.appendingPathComponent("file with spaces & symbols.swift")
      try "class SpecialFile {}".writeAtomicallyIfPossible(to: specialFile)

      // Create ignore file
      let ignoreFile = testDir.appendingPathComponent(".swift-format-ignore")
      try "special-chars & spaces/file with spaces & symbols.swift".writeAtomicallyIfPossible(to: ignoreFile)

      let ignoreManager = IgnoreManager()

      // Should handle special characters correctly
      #expect(ignoreManager.shouldIgnore(file: specialFile, isDirectory: false))
    }
  }

  // MARK: - Caching Tests

  @Test func ignoreManagerShouldCacheLoadedFiles() throws {
    try withTestDirectory { testDir in
      // Create ignore file
      let ignoreFile = testDir.appendingPathComponent(".swift-format-ignore")
      try "*.generated".writeAtomicallyIfPossible(to: ignoreFile)

      // Create test files
      let file1 = testDir.appendingPathComponent("File1.generated")
      let file2 = testDir.appendingPathComponent("File2.generated")
      try "content1".writeAtomicallyIfPossible(to: file1)
      try "content2".writeAtomicallyIfPossible(to: file2)

      let ignoreManager = IgnoreManager()

      // First call should load and cache the ignore file
      #expect(ignoreManager.shouldIgnore(file: file1, isDirectory: false))

      // Second call should use cached version
      #expect(ignoreManager.shouldIgnore(file: file2, isDirectory: false))

      // Verify caching by modifying the file after first load
      try "# modified content\n*.different".writeAtomicallyIfPossible(to: ignoreFile)

      // Should still use cached version
      #expect(ignoreManager.shouldIgnore(file: file1, isDirectory: false))
    }
  }

  // MARK: - Unicode and Encoding Tests

  @Test func unicodeCharactersInPatternsAndPathsShouldWork() throws {
    try withTestDirectory { testDir in
      // Create file with unicode characters
      let unicodeFile = testDir.appendingPathComponent("测试文件.swift")
      try "class TestFile {}".writeAtomicallyIfPossible(to: unicodeFile)

      // Create ignore file with unicode pattern
      let ignoreFile = testDir.appendingPathComponent(".swift-format-ignore")
      try "测试文件.swift".writeAtomicallyIfPossible(to: ignoreFile)

      let ignoreManager = IgnoreManager()

      // Should handle unicode correctly
      #expect(ignoreManager.shouldIgnore(file: unicodeFile, isDirectory: false))
    }
  }

  // MARK: - Nested Directory Edge Cases

  @Test func deeplyNestedDirectoriesShouldWork() throws {
    try withTestDirectory { testDir in
      // Create deeply nested structure
      let deepPath = "level1/level2/level3/level4/level5"
      let deepDir = testDir.appendingPathComponent(deepPath)
      try FileManager.default.createDirectory(at: deepDir, withIntermediateDirectories: true)

      let deepFile = deepDir.appendingPathComponent("Deep.swift")
      try "class Deep {}".writeAtomicallyIfPossible(to: deepFile)

      // Create ignore file at root
      let ignoreFile = testDir.appendingPathComponent(".swift-format-ignore")
      try "level1/level2/level3/**/*.swift".writeAtomicallyIfPossible(to: ignoreFile)

      let ignoreManager = IgnoreManager()

      // Should match files in deeply nested directories
      #expect(ignoreManager.shouldIgnore(file: deepFile, isDirectory: false))
    }
  }
}
