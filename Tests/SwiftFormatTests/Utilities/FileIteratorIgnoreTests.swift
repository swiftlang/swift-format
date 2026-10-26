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
import _SwiftFormatTestSupport

@Suite
struct FileIteratorIgnoreTests {

  // MARK: - Integration Tests

  @Test func fileIteratorRespectsIgnoreFiles() throws {
    try withTempDirectory { tempDir in
      // Create some Swift files
      let fileA = tempDir.appendingPathComponent("FileA.swift")
      let fileB = tempDir.appendingPathComponent("FileB.generated.swift")
      let fileC = tempDir.appendingPathComponent("FileC.swift")

      try "// FileA".writeAtomicallyIfPossible(to: fileA)
      try "// FileB Generated".writeAtomicallyIfPossible(to: fileB)
      try "// FileC".writeAtomicallyIfPossible(to: fileC)

      // Create ignore file
      let ignoreFile = tempDir.appendingPathComponent(".swift-format-ignore")
      try "*.generated.swift".writeAtomicallyIfPossible(to: ignoreFile)

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

      try "// FileA".writeAtomicallyIfPossible(to: fileA)
      try "// FileB Generated".writeAtomicallyIfPossible(to: fileB)

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

      try "// Main".writeAtomicallyIfPossible(to: mainFile)
      try "// Generated".writeAtomicallyIfPossible(to: generatedFile)
      try "// Test".writeAtomicallyIfPossible(to: testFile)
      try "// TestGenerated".writeAtomicallyIfPossible(to: testGeneratedFile)

      // Root ignore: ignore Generated.swift files
      let rootIgnore = tempDir.appendingPathComponent(".swift-format-ignore")
      try "Generated.swift".writeAtomicallyIfPossible(to: rootIgnore)

      // Test ignore: allow TestGenerated.swift (negation)
      let testIgnore = testDir.appendingPathComponent(".swift-format-ignore")
      try "!TestGenerated.swift".writeAtomicallyIfPossible(to: testIgnore)

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

  @Test(
    .bug("https://github.com/swiftlang/swift-format/issues/1192")
  )
  func fileIteratorWithMultipleNonEmptySwiftIgoreFiles() throws {
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

      try "// root".writeAtomicallyIfPossible(to: rootFile)
      try "// source 1".writeAtomicallyIfPossible(to: srcFile1)
      try "// source 2".writeAtomicallyIfPossible(to: srcFile2)
      try "// fixture keep".writeAtomicallyIfPossible(to: fixtureSubFile1)
      try "// fixture keep negated in subdirectory".writeAtomicallyIfPossible(to: fixtureSubFile2)
      for (index, file) in fixtureFiles.enumerated() {
        try "// fixture ignore \(index)".writeAtomicallyIfPossible(to: file)
      }

      // Ignore source directory at root, but negate non-ignored files
      let rootIgnore = tempDir.appendingPathComponent(".swift-format-ignore")
      try """
      src/
      Fixture/
      """.writeAtomicallyIfPossible(to: rootIgnore)
      let srcIgnore = srcDir.appendingPathComponent(".swift-format-ignore")
      try "!include*.swift".writeAtomicallyIfPossible(to: srcIgnore)
      let fixtureIgnore = fixtureDir.appendingPathComponent(".swift-format-ignore")
      try "!MyFix/*-keep.swift".writeAtomicallyIfPossible(to: fixtureIgnore)
      let fixtureSubIgnore = fixtureSubDir.appendingPathComponent(".swift-format-ignore")
      try "!*-negate-in-subdir.swift".writeAtomicallyIfPossible(to: fixtureSubIgnore)

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

      // https://github.com/swiftlang/swift-format/issues/1192, Marking as intermittent as the root cause may be not be in this project
      withKnownIssue(isIntermittent: true) {
        // Should find: root.swift, src/source1.swift, Fixture/MyFixture/myfix-keep.swift, Fixture/MyFixture/myfix-negate-in-subdir.swift,
        #expect(foundFiles.count == 4)

        let actualFilenames = foundFiles.map { url in
          url.standardizedFileURL.path
        }.filter { !$0.isEmpty }.sorted()
        #expect(
          actualFilenames == [
            tempDir.standardizedFileURL.appendingPathComponent("Fixture/MyFix/myfix-keep.swift").path,
            tempDir.standardizedFileURL.appendingPathComponent("Fixture/MyFix/myfix-negate-in-subdir.swift").path,
            tempDir.standardizedFileURL.appendingPathComponent("root.swift").path,
            tempDir.standardizedFileURL.appendingPathComponent("src/include1.swift").path,
          ]
        )
        let filenames = foundFiles.map { $0.lastPathComponent }.sorted()
        #expect(filenames == ["include1.swift", "myfix-keep.swift", "myfix-negate-in-subdir.swift", "root.swift"])
      } when: {
        #if os(Windows)
        true
        #else
        false
        #endif
      }

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

      try "// Build".writeAtomicallyIfPossible(to: buildFile)
      try "// Source".writeAtomicallyIfPossible(to: srcFile)
      try "// Root build file".writeAtomicallyIfPossible(to: rootFile)

      // Ignore build directory, but not build files
      let ignoreFile = tempDir.appendingPathComponent(".swift-format-ignore")
      try "build/".writeAtomicallyIfPossible(to: ignoreFile)

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

  @Test func fileIteratorStopsAtDirectoryWithSwiftFormatFile() throws {
    try withTempDirectory { tempDir in
      // Create nested directory structure: tempDir/project/src/main/
      let projectDir = tempDir.appendingPathComponent("project")
      let srcDir = projectDir.appendingPathComponent("src")
      let mainDir = srcDir.appendingPathComponent("main")
      try FileManager.default.createDirectory(at: mainDir, withIntermediateDirectories: true)

      // Create Swift files
      let mainFile = mainDir.appendingPathComponent("Main.swift")
      let testFile = mainDir.appendingPathComponent("Root.has.this.ignore.swift")
      let utilFile = srcDir.appendingPathComponent("src.util.test.swift")

      try "// Main".writeAtomicallyIfPossible(to: mainFile)
      try "// Test Generated".writeAtomicallyIfPossible(to: testFile)
      try "// Util Test".writeAtomicallyIfPossible(to: utilFile)

      // Create .swift-format-ignore at root level (should be ignored due to project boundary)
      let rootIgnore = tempDir.appendingPathComponent(".swift-format-ignore")
      try "*.ignore.swift".writeAtomicallyIfPossible(to: rootIgnore)

      // Create .swift-format configuration file at project level (creates boundary)
      let projectConfig = projectDir.appendingPathComponent(".swift-format")
      try "{}".writeAtomicallyIfPossible(to: projectConfig)

      // Create .swift-format-ignore at src level (should be respected)
      let srcIgnore = srcDir.appendingPathComponent(".swift-format-ignore")
      try "*.test.swift".writeAtomicallyIfPossible(to: srcIgnore)

      // Create FileIterator with ignore support
      var iterator = FileIterator(
        urls: [projectDir],  // Start from project directory
        followSymlinks: false,
        workingDirectory: projectDir,
        ignoreManager: IgnoreManager()
      )

      var foundFiles: [URL] = []
      while let file = iterator.next() {
        foundFiles.append(file)
      }

      // Should find: Main.swift, Test.generated.swift (because root ignore is not applied)
      // Should NOT find: Util.test.swift (ignored by src ignore file)
      #expect(foundFiles.count == 2)

      let filenames = foundFiles.map { $0.standardizedFileURL.path }.sorted()
      #expect(
        filenames == [
          mainFile.standardizedFileURL.path,
          testFile.standardizedFileURL.path,
        ]
      )
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
