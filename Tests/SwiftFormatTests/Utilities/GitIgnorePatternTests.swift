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

@_spi(Internal) import SwiftFormat
import Testing

@Suite
struct GitIgnorePatternTests {

  // MARK: - Basic Pattern Matching Tests

  @Test func exactMatch() throws {
    let pattern = try GitIgnorePattern("test.swift")

    #expect(pattern.matches("test.swift", isDirectory: false) == true)
    #expect(pattern.matches("other.swift", isDirectory: false) == false)
    #expect(pattern.matches("test.swif", isDirectory: false) == false)
  }

  @Test func exactMatchWithDirectory() throws {
    let pattern = try GitIgnorePattern("src")

    #expect(pattern.matches("src", isDirectory: true) == true)
    #expect(pattern.matches("src", isDirectory: false) == true)
    #expect(pattern.matches("source", isDirectory: true) == false)
  }

  @Test func singleWildcardPattern() throws {
    let pattern = try GitIgnorePattern("*.swift")

    #expect(pattern.matches("test.swift", isDirectory: false) == true)
    #expect(pattern.matches("main.swift", isDirectory: false) == true)
    #expect(pattern.matches("src/foo/testa.swift", isDirectory: false) == true)
    #expect(pattern.matches("/absolute/pathsrc/foo/testa.swift", isDirectory: false) == true)
    #expect(pattern.matches("test.java", isDirectory: false) == false)
    #expect(pattern.matches("swift", isDirectory: false) == false)
  }

  @Test func questionMarkWildcard() throws {
    let pattern = try GitIgnorePattern("test?.swift")

    #expect(pattern.matches("test1.swift", isDirectory: false) == true)
    #expect(pattern.matches("testa.swift", isDirectory: false) == true)
    #expect(pattern.matches("src/foo/testa.swift", isDirectory: false) == true)
    #expect(pattern.matches("/absolute/pathsrc/foo/testa.swift", isDirectory: false) == true)
    #expect(pattern.matches("test.swift", isDirectory: false) == false)
    #expect(pattern.matches("test12.swift", isDirectory: false) == false)
  }

  @Test func directoryOnlyPattern() throws {
    let pattern = try GitIgnorePattern("build/")

    #expect(pattern.matches("build", isDirectory: true) == true)
    #expect(pattern.matches("build", isDirectory: false) == false)
    #expect(pattern.matches("build.txt", isDirectory: false) == false)
  }

  // MARK: - Pattern Properties Tests

  @Test func negationPatternDetection() throws {
    let normalPattern = try GitIgnorePattern("test.swift")
    let negationPattern = try GitIgnorePattern("!test.swift")

    #expect(normalPattern.isNegation == false)
    #expect(negationPattern.isNegation == true)
  }

  @Test func directoryOnlyPatternDetection() throws {
    let filePattern = try GitIgnorePattern("test.swift")
    let dirPattern = try GitIgnorePattern("build/")

    #expect(filePattern.isDirectoryOnly == false)
    #expect(dirPattern.isDirectoryOnly == true)
  }

  // MARK: - Advanced Pattern Matching Tests (These will fail initially)

  @Test func doubleAsteriskPattern() throws {
    let pattern = try GitIgnorePattern("**/test.swift")

    // Should match files at any depth
    #expect(pattern.matches("test.swift", isDirectory: false) == true)
    #expect(pattern.matches("src/test.swift", isDirectory: false) == true)
    #expect(pattern.matches("src/main/test.swift", isDirectory: false) == true)
    #expect(pattern.matches("/src/main/test.swift", isDirectory: false) == true)
    #expect(pattern.matches("test.java", isDirectory: false) == false)
  }

  @Test func doubleAsteriskDirectoryPattern() throws {
    let pattern = try GitIgnorePattern("src/**/build")

    // Should match directories under src at any depth
    #expect(pattern.matches("src/build", isDirectory: true) == true)
    #expect(pattern.matches("src/main/build", isDirectory: true) == true)
    #expect(pattern.matches("src/main/java/build", isDirectory: true) == true)
    #expect(pattern.matches("build", isDirectory: true) == false)
    #expect(pattern.matches("other/build", isDirectory: true) == false)
  }

  @Test func trailingDoubleAsteriskPattern() throws {
    let pattern = try GitIgnorePattern("build/**")

    // Should match everything under build directory
    #expect(pattern.matches("build/file.swift", isDirectory: false) == true)
    #expect(pattern.matches("build/sub/file.swift", isDirectory: false) == true)
    #expect(pattern.matches("build/sub/deep/file.swift", isDirectory: false) == true)
    #expect(pattern.matches("build", isDirectory: true) == false)  // build itself should not match
    #expect(pattern.matches("other/file.swift", isDirectory: false) == false)
  }

  @Test func absolutePathPattern() throws {
    let pattern = try GitIgnorePattern("/root.swift")

    // Should only match at root level
    #expect(pattern.matches("root.swift", isDirectory: false) == true)
    #expect(pattern.matches("src/root.swift", isDirectory: false) == false)
    #expect(pattern.matches("sub/dir/root.swift", isDirectory: false) == false)
  }

  @Test func negationPatternBehavior() throws {
    // This will need multiple patterns to test properly, but test basic negation matching
    let negationPattern = try GitIgnorePattern("!important.swift")

    // Negation patterns should still match the path, but be marked as negation
    #expect(negationPattern.matches("important.swift", isDirectory: false) == true)
    #expect(negationPattern.isNegation == true)
    #expect(negationPattern.matches("other.swift", isDirectory: false) == false)
  }

  @Test func complexWildcardPattern() throws {
    let pattern = try GitIgnorePattern("test*.swift")

    #expect(pattern.matches("test.swift", isDirectory: false) == true)
    #expect(pattern.matches("test1.swift", isDirectory: false) == true)
    #expect(pattern.matches("testFile.swift", isDirectory: false) == true)
    #expect(pattern.matches("mytest.swift", isDirectory: false) == false)
    #expect(pattern.matches("test.java", isDirectory: false) == false)
  }

  @Test func middleWildcardPattern() throws {
    let pattern = try GitIgnorePattern("test*file.swift")

    #expect(pattern.matches("testfile.swift", isDirectory: false) == true)
    #expect(pattern.matches("test1file.swift", isDirectory: false) == true)
    #expect(pattern.matches("testMainfile.swift", isDirectory: false) == true)
    #expect(pattern.matches("test.swift", isDirectory: false) == false)
    #expect(pattern.matches("file.swift", isDirectory: false) == false)
  }

  @Test func multipleQuestionMarkPattern() throws {
    let pattern = try GitIgnorePattern("test??.swift")

    #expect(pattern.matches("test12.swift", isDirectory: false) == true)
    #expect(pattern.matches("testAB.swift", isDirectory: false) == true)
    #expect(pattern.matches("test1.swift", isDirectory: false) == false)
    #expect(pattern.matches("test123.swift", isDirectory: false) == false)
    #expect(pattern.matches("test.swift", isDirectory: false) == false)
  }

  // MARK: - Error Handling and Edge Cases

  @Test func invalidEmptyPattern() throws {
    #expect(throws: GitIgnorePattern.PatternError.self) {
      try GitIgnorePattern("")
    }
  }

  @Test func invalidEmptyNegationPattern() throws {
    #expect(throws: GitIgnorePattern.PatternError.self) {
      try GitIgnorePattern("!")
    }
  }

  @Test func invalidEmptyDirectoryPattern() throws {
    #expect(throws: GitIgnorePattern.PatternError.self) {
      try GitIgnorePattern("/")
    }
  }

  @Test func negationDirectoryPattern() throws {
    let pattern = try GitIgnorePattern("!build/")

    #expect(pattern.isNegation == true)
    #expect(pattern.isDirectoryOnly == true)
    #expect(pattern.matches("build", isDirectory: true) == true)
    #expect(pattern.matches("build", isDirectory: false) == false)
  }

  @Test func wildcardDoesNotCrossDirectoryBoundary() throws {
    let pattern = try GitIgnorePattern("src/*.swift")

    #expect(pattern.matches("src/file.swift", isDirectory: false) == true)
    #expect(pattern.matches("src/sub/file.swift", isDirectory: false) == false)
  }

  @Test func questionMarkDoesNotMatchSlash() throws {
    let pattern = try GitIgnorePattern("test?file")

    #expect(pattern.matches("testAfile", isDirectory: false) == true)
    #expect(pattern.matches("test/file", isDirectory: false) == false)
  }

  @Test func specialCharactersInPattern() throws {
    let pattern = try GitIgnorePattern("test[abc].swift")

    // For now, this should match exactly (no character class expansion)
    #expect(pattern.matches("test[abc].swift", isDirectory: false) == true)
    #expect(pattern.matches("testa.swift", isDirectory: false) == false)
  }

  @Test func patternWithSpaces() throws {
    let pattern = try GitIgnorePattern("file with spaces.swift")

    #expect(pattern.matches("file with spaces.swift", isDirectory: false) == true)
    #expect(pattern.matches("file_with_spaces.swift", isDirectory: false) == false)
  }

  // MARK: - Directory-Only Pattern Behavior

  @Test func directoryOnlyPatternMatchesFilesInsideDirectory() throws {
    let pattern = try GitIgnorePattern("build/")

    #expect(pattern.isDirectoryOnly == true)

    // Should match the directory itself
    #expect(pattern.matches("build", isDirectory: true) == true)

    // Should match files inside the directory
    #expect(pattern.matches("build/file.swift", isDirectory: false) == true)
    #expect(pattern.matches("build/subfolder/file.swift", isDirectory: false) == true)

    // Should NOT match files at root with same name
    #expect(pattern.matches("build.swift", isDirectory: false) == false)

    // Should NOT match files in different directories
    #expect(pattern.matches("src/build.swift", isDirectory: false) == false)
    #expect(pattern.matches("src/file.swift", isDirectory: false) == false)
  }

  @Test func nestedDirectoryOnlyPattern() throws {
    let pattern = try GitIgnorePattern("src/build/")

    #expect(pattern.isDirectoryOnly)

    // Should match files inside the nested directory
    #expect(pattern.matches("src/build/file.swift", isDirectory: false) == true)
    #expect(pattern.matches("src/build/deep/file.swift", isDirectory: false) == true)

    // Should NOT match files in parent directory
    #expect(pattern.matches("src/file.swift", isDirectory: false) == false)

    // Should NOT match files in different paths
    #expect(pattern.matches("build/file.swift", isDirectory: false) == false)
    #expect(pattern.matches("other/src/build/file.swift", isDirectory: false) == false)
  }

  // MARK: - Simple Filename Pattern Behavior

  @Test func simpleFilenamePatternMatchesAnywhere() throws {
    let pattern = try GitIgnorePattern("Generated.swift")

    #expect(pattern.isDirectoryOnly == false)
    #expect(pattern.isNegation == false)

    // Should match filename at root
    #expect(pattern.matches("Generated.swift", isDirectory: false) == true)

    // Should match filename in any subdirectory
    #expect(pattern.matches("src/Generated.swift", isDirectory: false) == true)
    #expect(pattern.matches("test/models/Generated.swift", isDirectory: false) == true)
    #expect(pattern.matches("deep/nested/path/Generated.swift", isDirectory: false) == true)

    // Should NOT match partial matches
    #expect(pattern.matches("MyGenerated.swift", isDirectory: false) == false)
    #expect(pattern.matches("Generated.swift.backup", isDirectory: false) == false)

    // Should NOT match directories
    #expect(pattern.matches("src/Generated.swift", isDirectory: true) == false)
  }

  @Test func simpleFilenamePatternVsPathPattern() throws {
    let filenamePattern = try GitIgnorePattern("file.swift")
    let pathPattern = try GitIgnorePattern("src/file.swift")

    let testPath = "src/file.swift"

    // Filename pattern should match (matches filename anywhere)
    #expect(filenamePattern.matches(testPath, isDirectory: false) == true)

    // Path pattern should match (exact path match)
    #expect(pathPattern.matches(testPath, isDirectory: false) == true)

    let differentPath = "test/file.swift"

    // Filename pattern should still match (matches filename anywhere)
    #expect(filenamePattern.matches(differentPath, isDirectory: false) == true)

    // Path pattern should NOT match (different path)
    #expect(pathPattern.matches(differentPath, isDirectory: false) == false)
  }

  @Test func doubleAsteriskWithWildcardSuffix() throws {
    let pattern = try GitIgnorePattern("level1/level2/level3/**/*.swift")

    // Should match files with wildcard suffix at any depth under the prefix
    #expect(pattern.matches("level1/level2/level3/File.swift", isDirectory: false) == true)
    #expect(pattern.matches("level1/level2/level3/level4/File.swift", isDirectory: false) == true)
    #expect(pattern.matches("level1/level2/level3/level4/level5/Deep.swift", isDirectory: false) == true)
    #expect(pattern.matches("level1/level2/level3/a/b/c/d/VeryDeep.swift", isDirectory: false) == true)

    // Should not match files outside the prefix
    #expect(pattern.matches("level1/level2/File.swift", isDirectory: false) == false)
    #expect(pattern.matches("other/level3/File.swift", isDirectory: false) == false)

    // Should not match non-Swift files
    #expect(pattern.matches("level1/level2/level3/level4/File.java", isDirectory: false) == false)
    #expect(pattern.matches("level1/level2/level3/File.txt", isDirectory: false) == false)

    // Should not match directories
    #expect(pattern.matches("level1/level2/level3/level4/MyDir.swift", isDirectory: true) == false)
  }

  @Test func doubleAsteriskWithComplexWildcardSuffix() throws {
    let pattern = try GitIgnorePattern("src/**/test*.swift")

    // Should match files with complex wildcard suffix
    #expect(pattern.matches("src/test.swift", isDirectory: false) == true)
    #expect(pattern.matches("src/testUtils.swift", isDirectory: false) == true)
    #expect(pattern.matches("src/deep/testHelper.swift", isDirectory: false) == true)
    #expect(pattern.matches("src/very/deep/nested/testCase.swift", isDirectory: false) == true)

    // Should not match files that don't start with "test"
    #expect(pattern.matches("src/main.swift", isDirectory: false) == false)
    #expect(pattern.matches("src/deep/helper.swift", isDirectory: false) == false)

    // Should not match files outside src
    #expect(pattern.matches("other/test.swift", isDirectory: false) == false)
  }
}
