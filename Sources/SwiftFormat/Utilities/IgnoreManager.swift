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

/// Manages `.swift-format-ignore` files for excluding files from formatting and linting.
///
/// IgnoreManager handles discovery, loading, and caching of ignore files in a directory tree,
/// implementing precedence rules where closer ignore files take priority.
@_spi(Internal)
public class IgnoreManager {

  /// Errors that can occur during ignore file operations
  public enum IgnoreError: Error, Equatable {
    case fileNotFound
    case invalidPattern(String)
  }

  /// Shared cache for loaded ignore files to avoid repeated I/O across all instances
  private var ignoreFileCache: [URL: [GitIgnorePattern]] = [:]

  private var baseDirectoryCache: [URL: URL] = [:]

  /// Initialize a new IgnoreManager
  public init() {}

  /// Find all .swift-format-ignore files that apply to the given file path
  ///
  /// Walks up the directory tree from the file's directory to find ignore files,
  /// returning them in order of precedence (closest first).
  ///
  /// - Parameter filePath: The file path to find ignore files for
  /// - Returns: Array of ignore file URLs, ordered by precedence (closest first)
  public func findIgnoreFiles(for filePath: URL) -> [URL] {
    var ignoreFiles: [URL] = []
    var currentDir = filePath.deletingLastPathComponent()

    // Walk up the directory tree
    while true {
      let ignoreFile = currentDir.appendingPathComponent(".swift-format-ignore")

      if FileManager.default.fileExists(atPath: ignoreFile.path) {
        ignoreFiles.append(ignoreFile)
      }

      if currentDir.isRoot {
        break  // We've reached the root
      }
      let parentDir = currentDir.deletingLastPathComponent()
      currentDir = parentDir
    }

    return ignoreFiles
  }

  /// Load patterns from a .swift-format-ignore file
  ///
  /// - Parameter url: URL of the ignore file to load
  /// - Returns: Array of GitIgnorePattern objects parsed from the file
  /// - Throws: `IgnoreError.fileNotFound` if the file doesn't exist
  public func loadIgnoreFile(at url: URL) throws -> [GitIgnorePattern] {
    // Check cache first (thread-safe)
    if let cachedPatterns = self.ignoreFileCache[url] {
      return cachedPatterns
    }

    // Check if file exists
    guard FileManager.default.fileExists(atPath: url.path) else {
      throw IgnoreError.fileNotFound
    }

    // Read file content
    let content = try String(contentsOf: url, encoding: .utf8)
    let lines = content.components(separatedBy: .newlines)

    var patterns: [GitIgnorePattern] = []

    for line in lines {
      let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)

      // Skip empty lines and comments
      if trimmedLine.isEmpty || trimmedLine.hasPrefix("#") {
        continue
      }

      do {
        let pattern = try GitIgnorePattern(trimmedLine)
        patterns.append(pattern)
      } catch {
        // Skip invalid patterns for now
        continue
      }
    }

    // Cache the result (thread-safe)
    self.ignoreFileCache[url] = patterns

    return patterns
  }

  public func getBaseDirectory(file: URL, isDirectory: Bool) -> URL {
    // Check the cache first
    let targetDirectory = (isDirectory) ? file : file.deletingLastPathComponent()
    if let directory = self.baseDirectoryCache[targetDirectory] {
      return directory
    }

    var directory: URL
    if let configURL = Configuration.url(forConfigurationFileApplyingTo: file) {
      directory = configURL.deletingLastPathComponent()
    } else {
      // No config file found, find ignore files and use the directory of the furthest one
      let ignoreFiles = findIgnoreFiles(for: file)
      if let furthestIgnoreFile = ignoreFiles.last {
        directory = furthestIgnoreFile.deletingLastPathComponent()
      } else {
        // No ignore files found either, use the file's directory
        let candidateDirectory = file.hasDirectoryPath ? file : file.deletingLastPathComponent()
        directory = candidateDirectory.absoluteURL.standardized
      }
    }

    self.baseDirectoryCache[targetDirectory] = directory

    return directory
  }

  /// Determine if a file should be ignored based on .swift-format-ignore files
  ///
  /// Finds all applicable ignore files, loads their patterns, and evaluates them
  /// in precedence order (closest ignore file wins). The base directory is determined
  /// by finding the directory containing the .swift-format configuration file, or
  /// the directory containing the furthest .swift-format-ignore file if no config is found.
  ///
  /// - Parameters:
  ///   - file: The file URL to check
  ///   - isFileDirectory: Whether the file is a directory
  /// - Returns: `true` if the file should be ignored, `false` otherwise
  public func shouldIgnore(file: URL, isDirectory: Bool) -> Bool {
    // Determine base directory using the same logic as .swift-format configuration files
    let baseDirectory = self.getBaseDirectory(file: file, isDirectory: isDirectory)

    let ignoreFiles = findIgnoreFiles(for: file)

    // If no ignore files found, don't ignore
    guard !ignoreFiles.isEmpty else {
      return false
    }

    // Get relative path from base directory using standardized paths
    let standardizedFile = file.standardizedFileURL
    let standardizedBase = baseDirectory.standardizedFileURL
    let relativePath = standardizedFile.path.replacingOccurrences(of: standardizedBase.path + "/", with: "")

    // Process ignore files in precedence order (closest first)
    var shouldIgnore = false

    for ignoreFile in ignoreFiles.reversed() {  // Process furthest first, then closest
      do {
        let patterns = try loadIgnoreFile(at: ignoreFile)

        // Apply patterns in order
        for pattern in patterns {
          if pattern.matches(relativePath, isDirectory: isDirectory) {
            shouldIgnore = !pattern.isNegation  // Ignore unless it's a negation pattern
          }
        }
      } catch {
        // Skip files that can't be loaded
        continue
      }
    }

    return shouldIgnore
  }
}
