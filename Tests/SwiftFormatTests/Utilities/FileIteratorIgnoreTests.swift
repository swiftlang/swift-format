//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import Foundation
@_spi(Testing) import SwiftFormat
@_spi(Internal) import SwiftFormat
import Testing

@Suite
struct FileIteratorIgnoreTests {

  // MARK: - Integration Tests

  @Test func fileIteratorRespectsIgnoreFiles() throws {
    try withTempDirectory { tempDir in
      // Create some Swift files
      let fileA = tempDir.appendingPathComponent("FileA.swift")
      let fileB = tempDir.appendingPathComponent("FileB.generated.swift")
      let fileC = tempDir.appendingPathComponent("FileC.swift")

      try "// FileA".write(to: fileA, atomically: true, encoding: .utf8)
      try "// FileB Generated".write(to: fileB, atomically: true, encoding: .utf8)
      try "// FileC".write(to: fileC, atomically: true, encoding: .utf8)

      // Create ignore file
      let ignoreFile = tempDir.appendingPathComponent(".swift-format-ignore")
      try "*.generated.swift".write(to: ignoreFile, atomically: true, encoding: .utf8)

      // Create FileIterator with ignore support
      var iterator = FileIterator(
        urls: [tempDir],
        followSymlinks: false,
        workingDirectory: tempDir,
        ignoreManager: IgnoreManager()
      )

      var foundFiles: [URL] = []
      while let file = iterator.next() {
        foundFiles.append(file)
      }

      // Should find FileA.swift and FileC.swift, but not FileB.generated.swift
      #expect(foundFiles.count == 2)

      let filenames = foundFiles.map { $0.lastPathComponent }.sorted()
      #expect(filenames == ["FileA.swift", "FileC.swift"])
    }
  }

  @Test func fileIteratorWithoutIgnoreManagerIncludesAllFiles() throws {
    try withTempDirectory { tempDir in
      // Create some Swift files
      let fileA = tempDir.appendingPathComponent("FileA.swift")
      let fileB = tempDir.appendingPathComponent("FileB.generated.swift")

      try "// FileA".write(to: fileA, atomically: true, encoding: .utf8)
      try "// FileB Generated".write(to: fileB, atomically: true, encoding: .utf8)

      // Create FileIterator without ignore support
      var iterator = FileIterator(urls: [tempDir], followSymlinks: false, workingDirectory: tempDir)

      var foundFiles: [URL] = []
      while let file = iterator.next() {
        foundFiles.append(file)
      }

      // Should find both files when ignoring is disabled
      #expect(foundFiles.count == 2)

      let filenames = foundFiles.map { $0.lastPathComponent }.sorted()
      #expect(filenames == ["FileA.swift", "FileB.generated.swift"])
    }
  }

  @Test func fileIteratorRespectsNestedIgnoreFiles() throws {
    try withTempDirectory { tempDir in
      // Create nested directory structure
      let srcDir = tempDir.appendingPathComponent("src")
      let testDir = tempDir.appendingPathComponent("0test")
      try FileManager.default.createDirectory(at: srcDir, withIntermediateDirectories: true)
      try FileManager.default.createDirectory(at: testDir, withIntermediateDirectories: true)

      // Create files
      let mainFile = srcDir.appendingPathComponent("Main.swift")
      let generatedFile = srcDir.appendingPathComponent("Generated.swift")
      let testFile = testDir.appendingPathComponent("Test.swift")
      let testGeneratedFile = testDir.appendingPathComponent("TestGenerated.swift")

      try "// Main".write(to: mainFile, atomically: true, encoding: .utf8)
      try "// Generated".write(to: generatedFile, atomically: true, encoding: .utf8)
      try "// Test".write(to: testFile, atomically: true, encoding: .utf8)
      try "// TestGenerated".write(to: testGeneratedFile, atomically: true, encoding: .utf8)

      // Root ignore: ignore Generated.swift files
      let rootIgnore = tempDir.appendingPathComponent(".swift-format-ignore")
      try "Generated.swift".write(to: rootIgnore, atomically: true, encoding: .utf8)

      // Test ignore: allow TestGenerated.swift (negation)
      let testIgnore = testDir.appendingPathComponent(".swift-format-ignore")
      try "!TestGenerated.swift".write(to: testIgnore, atomically: true, encoding: .utf8)

      // Create FileIterator with ignore support
      var iterator = FileIterator(
        urls: [tempDir],
        followSymlinks: false,
        workingDirectory: tempDir,
        ignoreManager: IgnoreManager()
      )

      var foundFiles: [URL] = []
      while let file = iterator.next() {
        foundFiles.append(file)
      }

      // Should find: Main.swift, Test.swift, TestGenerated.swift (negation overrides)
      // Should NOT find: Generated.swift (ignored by root)
      #expect(foundFiles.count == 3)

      let filenames = foundFiles.map { $0.lastPathComponent }.sorted()
      #expect(filenames == ["Main.swift", "Test.swift", "TestGenerated.swift"])
    }
  }

  @Test func fileIteratorWithMultipleNonEmptySwiftIgoreFiles() throws {
    try withTempDirectory { tempDir in
      let srcDir = tempDir.appendingPathComponent("src")
      let fixtureDir = tempDir.appendingPathComponent("Fixture")
      let fixtureSubDir = fixtureDir.appendingPathComponent("MyFix")
      try FileManager.default.createDirectory(at: srcDir, withIntermediateDirectories: true)
      try FileManager.default.createDirectory(at: fixtureDir, withIntermediateDirectories: true)
      try FileManager.default.createDirectory(at: fixtureSubDir, withIntermediateDirectories: true)

      let rootFile = tempDir.appendingPathComponent("root.swift")
      let srcFile1 = srcDir.appendingPathComponent("source1.swift")
      let srcFile2 = srcDir.appendingPathComponent("include1.swift")
      let fixtureSubFile1 = fixtureSubDir.appendingPathComponent("myfix-keep.swift")
      let fixtureSubFile2 = fixtureSubDir.appendingPathComponent("myfix-negate-in-subdir.swift")
      let fixtureFiles = (0...5).map {
        fixtureSubDir.appendingPathComponent("myfixture_shouldIgnore_\($0).swift")
      }

      try "// root".write(to: rootFile, atomically: true, encoding: .utf8)
      try "// source 1".write(to: srcFile1, atomically: true, encoding: .utf8)
      try "// source 2".write(to: srcFile2, atomically: true, encoding: .utf8)
      try "// fixture keep".write(to: fixtureSubFile1, atomically: true, encoding: .utf8)
      try "// fixture keep negated in subdirectory".write(to: fixtureSubFile2, atomically: true, encoding: .utf8)
      for (index, file) in fixtureFiles.enumerated() {
        try "// fixture ignore \(index)".write(to: file, atomically: true, encoding: .utf8)
      }

      // Ignore source directory at root, but negate non-ignored files
      let rootIgnore = tempDir.appendingPathComponent(".swift-format-ignore")
      try """
      src/
      Fixture/
      """.write(to: rootIgnore, atomically: true, encoding: .utf8)
      let srcIgnore = srcDir.appendingPathComponent(".swift-format-ignore")
      try "!include*.swift".write(to: srcIgnore, atomically: true, encoding: .utf8)
      let fixtureIgnore = fixtureDir.appendingPathComponent(".swift-format-ignore")
      try "!MyFix/*-keep.swift".write(to: fixtureIgnore, atomically: true, encoding: .utf8)
      let fixtureSubIgnore = fixtureSubDir.appendingPathComponent(".swift-format-ignore")
      try "!*-negate-in-subdir.swift".write(to: fixtureSubIgnore, atomically: true, encoding: .utf8)

      var iterator = FileIterator(
        urls: [tempDir],
        followSymlinks: false,
        workingDirectory: tempDir,
        ignoreManager: IgnoreManager()
      )

      var foundFiles: [URL] = []
      while let file = iterator.next() {
        foundFiles.append(file)
      }

      // Should find: root.swift, src/source1.swift, Fixture/MyFixture/myfix-keep.swift, Fixture/MyFixture/myfix-negate-in-subdir.swift,
      #expect(foundFiles.count == 4)

      let actualFilenames = foundFiles.map { url in
        // Standardize both URLs to resolve symlinks and path canonicalization
        let standardizedTempDir = tempDir.standardizedFileURL.path
        let standardizedFilePath = url.standardizedFileURL.path

        // Remove the temp dir prefix to get relative path
        if standardizedFilePath.hasPrefix(standardizedTempDir) {
          let relativePath = String(standardizedFilePath.dropFirst(standardizedTempDir.count))
          return relativePath.hasPrefix("/") ? String(relativePath.dropFirst()) : relativePath
        }
        return url.lastPathComponent
      }.filter { !$0.isEmpty }.sorted()
      #expect(
        actualFilenames == [
          "Fixture/MyFix/myfix-keep.swift",
          "Fixture/MyFix/myfix-negate-in-subdir.swift",
          "root.swift",
          "src/include1.swift",
        ]
      )
    }
  }
  @Test func fileIteratorHandlesDirectoryOnlyPatterns() throws {
    try withTempDirectory { tempDir in
      // Create directory structure
      let buildDir = tempDir.appendingPathComponent("build")
      let srcDir = tempDir.appendingPathComponent("src")
      try FileManager.default.createDirectory(at: buildDir, withIntermediateDirectories: true)
      try FileManager.default.createDirectory(at: srcDir, withIntermediateDirectories: true)

      // Create files
      let buildFile = buildDir.appendingPathComponent("Build.swift")
      let srcFile = srcDir.appendingPathComponent("Source.swift")
      let rootFile = tempDir.appendingPathComponent("build.swift")  // File, not directory

      try "// Build".write(to: buildFile, atomically: true, encoding: .utf8)
      try "// Source".write(to: srcFile, atomically: true, encoding: .utf8)
      try "// Root build file".write(to: rootFile, atomically: true, encoding: .utf8)

      // Ignore build directory, but not build files
      let ignoreFile = tempDir.appendingPathComponent(".swift-format-ignore")
      try "build/".write(to: ignoreFile, atomically: true, encoding: .utf8)

      // Create FileIterator with ignore support
      var iterator = FileIterator(
        urls: [tempDir],
        followSymlinks: false,
        workingDirectory: tempDir,
        ignoreManager: IgnoreManager()
      )

      var foundFiles: [URL] = []
      while let file = iterator.next() {
        foundFiles.append(file)
      }

      // Should find: Source.swift, build.swift (file, not directory)
      // Should NOT find: Build.swift (in ignored build/ directory)
      #expect(foundFiles.count == 2)

      let filenames = foundFiles.map { $0.lastPathComponent }.sorted()
      #expect(filenames == ["Source.swift", "build.swift"])
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
