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

@Suite
struct IgnoreManagerTests {

  // MARK: - File Discovery Tests

  @Suite
  struct FindIgnoreFilesTests {
    @Test func findIgnoreFilesInSingleDirectory() throws {
      try withTempDirectory { tempDir in
        // Create a .swift-format-ignore file
        let ignoreFile = tempDir.appendingPathComponent(".swift-format-ignore")
        try "*.generated.swift".write(to: ignoreFile, atomically: true, encoding: .utf8)

        let manager = IgnoreManager()
        let foundFiles = manager.findIgnoreFiles(for: tempDir.appendingPathComponent("test.swift"))

        #expect(foundFiles.count == 1)
        #expect(foundFiles.first == ignoreFile)
      }
    }

    @Test func findIgnoreFilesForNonExistingFileReturnEmptyArray() throws {
      try withTempDirectory { tempDir in
        let manager = IgnoreManager()
        let foundFiles = manager.findIgnoreFiles(for: tempDir.appendingPathComponent("test.swift"))

        #expect(foundFiles.count == 0)
        #expect(foundFiles.isEmpty == true)
      }
    }

    @Test func findIgnoreFilesWalkingUpDirectoryTree() throws {
      try withTempDirectory { tempDir in
        // Create nested directory structure: tempDir/src/main/
        let srcDir = tempDir.appendingPathComponent("src")
        let mainDir = srcDir.appendingPathComponent("main")
        try FileManager.default.createDirectory(at: mainDir, withIntermediateDirectories: true)

        // Create ignore files at different levels
        let rootIgnore = tempDir.appendingPathComponent(".swift-format-ignore")
        let srcIgnore = srcDir.appendingPathComponent(".swift-format-ignore")

        try "*.generated.swift".write(to: rootIgnore, atomically: true, encoding: .utf8)
        try "*.test.swift".write(to: srcIgnore, atomically: true, encoding: .utf8)

        let manager = IgnoreManager()
        let testFile = mainDir.appendingPathComponent("MyFile.swift")
        let foundFiles = manager.findIgnoreFiles(for: testFile)

        // Should find both files, with closest first (src, then root)
        #expect(foundFiles.count == 2)
        #expect(foundFiles[0] == srcIgnore)  // Closest
        #expect(foundFiles[1] == rootIgnore)  // Further
      }
    }

    @Test func noIgnoreFilesFound() throws {
      try withTempDirectory { tempDir in
        let manager = IgnoreManager()
        let foundFiles = manager.findIgnoreFiles(for: tempDir.appendingPathComponent("test.swift"))

        #expect(foundFiles.isEmpty)
      }
    }
  }

  // MARK: - File Loading Tests

  @Suite
  struct LoadIgnoreFileTests {
    @Test func loadValidIgnoreFile() throws {
      try withTempDirectory { tempDir in
        let ignoreFile = tempDir.appendingPathComponent(".swift-format-ignore")
        let content = """
          *.generated.swift
          build/
          !important.generated.swift
          # This is a comment

          test/**/*.tmp
          """
        try content.write(to: ignoreFile, atomically: true, encoding: .utf8)

        let manager = IgnoreManager()
        let patterns = try manager.loadIgnoreFile(at: ignoreFile)

        #expect(patterns.count == 4)  // Should ignore comments and blank lines
        #expect(patterns[0].pattern == "*.generated.swift")
        #expect(patterns[1].pattern == "build/")
        #expect(patterns[2].pattern == "!important.generated.swift")
        #expect(patterns[2].isNegation == true)
        #expect(patterns[3].pattern == "test/**/*.tmp")
      }
    }

    @Test func loadSkipInvalidPatternInIgnoreFile() throws {
      try withTempDirectory { tempDir in
        let ignoreFile = tempDir.appendingPathComponent(".swift-format-ignore")
        try "!".write(to: ignoreFile, atomically: true, encoding: .utf8)

        let manager = IgnoreManager()
        let patterns = try manager.loadIgnoreFile(at: ignoreFile)

        #expect(patterns.isEmpty)
      }
    }

    @Test func loadEmptyIgnoreFile() throws {
      try withTempDirectory { tempDir in
        let ignoreFile = tempDir.appendingPathComponent(".swift-format-ignore")
        try "".write(to: ignoreFile, atomically: true, encoding: .utf8)

        let manager = IgnoreManager()
        let patterns = try manager.loadIgnoreFile(at: ignoreFile)

        #expect(patterns.isEmpty)
      }
    }

    @Test func loadNonexistentIgnoreFile() throws {
      try withTempDirectory { tempDir in
        let ignoreFile = tempDir.appendingPathComponent(".swift-format-ignore")
        let manager = IgnoreManager()

        #expect(throws: IgnoreManager.IgnoreError.fileNotFound) {
          try manager.loadIgnoreFile(at: ignoreFile)
        }
      }
    }
  }

  // MARK: - shouldIgnore Integration Tests
  @Suite
  struct ShouldIgnoreTests {
    @Test func shouldIgnoreBasicPattern() throws {
      try withTempDirectory { tempDir in
        // Create ignore file
        let ignoreFile = tempDir.appendingPathComponent(".swift-format-ignore")
        try "*.generated.swift".write(to: ignoreFile, atomically: true, encoding: .utf8)

        let manager = IgnoreManager()

        // Test files
        let generatedFile = tempDir.appendingPathComponent("Model.generated.swift")
        let normalFile = tempDir.appendingPathComponent("Model.swift")

        #expect(manager.shouldIgnore(file: generatedFile, isDirectory: false) == true)
        #expect(manager.shouldIgnore(file: normalFile, isDirectory: false) == false)
      }
    }

    @Test func shouldIgnoreWithNegationPattern() throws {
      try withTempDirectory { tempDir in
        // Create ignore file with negation
        let ignoreFile = tempDir.appendingPathComponent(".swift-format-ignore")
        let content = """
          *.generated.swift
          !important.generated.swift
          """
        try content.write(to: ignoreFile, atomically: true, encoding: .utf8)

        let manager = IgnoreManager()

        let generatedFile = tempDir.appendingPathComponent("Model.generated.swift")
        let importantFile = tempDir.appendingPathComponent("important.generated.swift")
        let normalFile = tempDir.appendingPathComponent("Model.swift")

        #expect(manager.shouldIgnore(file: generatedFile, isDirectory: false) == true)
        #expect(manager.shouldIgnore(file: importantFile, isDirectory: false) == false)  // Negated
        #expect(manager.shouldIgnore(file: normalFile, isDirectory: false) == false)
      }
    }

    @Test func shouldIgnoreWithPrecedence() throws {
      try withTempDirectory { tempDir in
        // Create nested structure
        let srcDir = tempDir.appendingPathComponent("src")
        try FileManager.default.createDirectory(at: srcDir, withIntermediateDirectories: true)

        // Root ignore: ignore all .test.swift
        let rootIgnore = tempDir.appendingPathComponent(".swift-format-ignore")
        try "*.test.swift".write(to: rootIgnore, atomically: true, encoding: .utf8)

        // Src ignore: allow .test.swift (negation takes precedence)
        let srcIgnore = srcDir.appendingPathComponent(".swift-format-ignore")
        try "!*.test.swift".write(to: srcIgnore, atomically: true, encoding: .utf8)

        let manager = IgnoreManager()

        let rootTestFile = tempDir.appendingPathComponent("App.test.swift")
        let srcTestFile = srcDir.appendingPathComponent("Model.test.swift")

        #expect(manager.shouldIgnore(file: rootTestFile, isDirectory: false) == true)  // Root rule applies
        #expect(
          manager.shouldIgnore(file: srcTestFile, isDirectory: false) == false  // Src negation takes precedence
        )
      }
    }

    @Test func shouldIgnoreWithNoIgnoreFilesDetectedReturnsFalse() async throws {
      try withTempDirectory { tempDir in
        let rootTestFile = tempDir.appendingPathComponent("App.test.swift")
        let manager = IgnoreManager()

        #expect(manager.shouldIgnore(file: rootTestFile, isDirectory: false) == false)
      }
    }
  }
}

// MARK: - Helper Methods

private func withTempDirectory<T>(_ body: (URL) throws -> T) throws -> T {
  let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
  try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
  defer { try? FileManager.default.removeItem(at: tempDir) }
  return try body(tempDir)
}
