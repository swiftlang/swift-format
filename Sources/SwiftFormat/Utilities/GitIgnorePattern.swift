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

/// A pattern matcher that follows gitignore-style pattern matching rules.
///
/// GitIgnorePattern implements pattern matching compatible with `.gitignore` files,
/// supporting wildcards, negation, directory-only patterns, and more complex matching rules.
@_spi(Internal)
public struct GitIgnorePattern {

  /// The original pattern string provided during initialization
  public let pattern: String

  /// Whether this pattern is a negation pattern (starts with `!`)
  public let isNegation: Bool

  /// Whether this pattern only matches directories (ends with `/`)
  public let isDirectoryOnly: Bool

  /// The processed pattern used for matching (with leading `!` and trailing `/` removed)
  private let matchPattern: String

  /// Error types that can occur during pattern parsing
  public enum PatternError: Error, CustomStringConvertible {
    case invalidPattern(String)

    public var description: String {
      switch self {
      case .invalidPattern(let pattern):
        return "Invalid gitignore pattern: '\(pattern)'"
      }
    }
  }

  /// Initialize a new GitIgnorePattern from the given pattern string
  ///
  /// - Parameter pattern: The gitignore-style pattern string
  /// - Throws: `PatternError.invalidPattern` if the pattern is invalid
  public init(_ pattern: String) throws {
    self.pattern = pattern

    // Handle negation patterns (starting with !)
    if pattern.hasPrefix("!") {
      self.isNegation = true
      let withoutNegation = String(pattern.dropFirst())

      // Handle directory-only patterns (ending with /)
      if withoutNegation.hasSuffix("/") {
        self.isDirectoryOnly = true
        self.matchPattern = String(withoutNegation.dropLast())
      } else {
        self.isDirectoryOnly = false
        self.matchPattern = withoutNegation
      }
    } else {
      self.isNegation = false

      // Handle directory-only patterns (ending with /)
      if pattern.hasSuffix("/") {
        self.isDirectoryOnly = true
        self.matchPattern = String(pattern.dropLast())
      } else {
        self.isDirectoryOnly = false
        self.matchPattern = pattern
      }
    }

    // Basic validation - empty patterns are invalid
    if matchPattern.isEmpty {
      throw PatternError.invalidPattern(pattern)
    }
  }

  /// Test whether the given path matches this pattern
  ///
  /// - Parameters:
  ///   - path: The file path to test against this pattern
  ///   - isDirectory: Whether the path represents a directory
  /// - Returns: `true` if the path matches this pattern, `false` otherwise
  public func matches(_ path: String, isDirectory: Bool) -> Bool {
    // For directory-only patterns, we need special handling
    if isDirectoryOnly {
      // If we're checking a directory itself, it should match if the pattern matches
      if isDirectory {
        return advancedMatch(path, pattern: matchPattern)
      }

      // If we're checking a file, it should match if it's INSIDE a directory that matches the pattern
      // For example: pattern "build/" should match "build/file.txt"
      let pathComponents = path.components(separatedBy: "/")

      // Check if any parent directory matches the pattern
      for i in 1..<pathComponents.count {
        let parentPath = pathComponents[..<i].joined(separator: "/")
        if advancedMatch(parentPath, pattern: matchPattern) {
          return true
        }
      }

      return false
    }

    // For non-directory-only patterns, use normal matching
    return advancedMatch(path, pattern: matchPattern, isDirectory: isDirectory)
  }

  /// Advanced pattern matching implementation supporting gitignore-style patterns
  private func advancedMatch(_ path: String, pattern: String, isDirectory: Bool = false) -> Bool {
    // Handle absolute patterns (starting with /)
    if pattern.hasPrefix("/") {
      let absolutePattern = String(pattern.dropFirst())
      return simpleMatch(path, pattern: absolutePattern)
    }

    // Handle double asterisk patterns
    if pattern.contains("**") {
      return doubleAsteriskMatch(path, pattern: pattern, isDirectory: isDirectory)
    }

    // For patterns without slashes, match the filename anywhere in the path
    // This includes patterns with wildcards like "*.swift" which should match filenames at any depth
    if !pattern.contains("/") {
      // Simple patterns with file extensions should only match files, not directories
      // Simple patterns without extensions should match both files and directories
      if isDirectory && pattern.contains(".") {
        // If it's a directory and the pattern looks like a filename with extension, don't match
        return false
      }
      let pathComponents = path.components(separatedBy: "/")
      let filename = pathComponents.last ?? path
      return simpleMatch(filename, pattern: pattern)
    }

    // Handle patterns with slashes (path-based patterns)
    return simpleMatch(path, pattern: pattern)
  }

  /// Handle double asterisk (**) patterns
  private func doubleAsteriskMatch(_ path: String, pattern: String, isDirectory: Bool) -> Bool {
    // Split pattern by **
    let parts = pattern.components(separatedBy: "**")

    if parts.count == 2 {
      let prefix = parts[0]
      let suffix = parts[1]

      // Pattern: **/suffix (matches suffix at any depth)
      if prefix.isEmpty {
        let cleanSuffix = suffix.hasPrefix("/") ? String(suffix.dropFirst()) : suffix
        return path.hasSuffix(cleanSuffix) || simpleMatch(path, pattern: cleanSuffix)
      }

      // Pattern: prefix/** (matches everything under prefix)
      if suffix.isEmpty || suffix == "/" {
        let cleanPrefix = prefix.hasSuffix("/") ? String(prefix.dropLast()) : prefix
        return path.hasPrefix(cleanPrefix + "/")
      }

      // Pattern: prefix/**/suffix (matches suffix under prefix at any depth)
      let cleanPrefix = prefix.hasSuffix("/") ? String(prefix.dropLast()) : prefix
      let cleanSuffix = suffix.hasPrefix("/") ? String(suffix.dropFirst()) : suffix

      if path.hasPrefix(cleanPrefix + "/") {
        let remainder = String(path.dropFirst(cleanPrefix.count + 1))

        // The suffix might contain wildcards, so use pattern matching
        // But we need to check if the suffix pattern would match directories for file patterns
        if shouldSuffixMatch(remainder, pattern: cleanSuffix, isDirectory: isDirectory) {
          return true
        }

        // Also check if any part of the remainder matches the suffix pattern
        let remainderComponents = remainder.components(separatedBy: "/")
        for i in 0..<remainderComponents.count {
          let subPath = remainderComponents[i...].joined(separator: "/")
          // For intermediate components, treat as files unless it's the final component
          let isIntermediateDirectory = (i < remainderComponents.count - 1) || isDirectory
          if shouldSuffixMatch(
            subPath,
            pattern: cleanSuffix,
            isDirectory: isIntermediateDirectory && i == remainderComponents.count - 1
          ) {
            return true
          }
        }
      }
    }

    return false
  }

  /// Helper to determine if a suffix pattern should match, considering directory vs file distinction
  private func shouldSuffixMatch(_ path: String, pattern: String, isDirectory: Bool) -> Bool {
    // If the pattern looks like a file pattern (contains extension) and target is directory, don't match
    if isDirectory && pattern.contains(".") && !pattern.contains("/") {
      // Simple pattern with extension like "*.swift" should not match directories
      return false
    }
    return simpleMatch(path, pattern: pattern)
  }

  /// Simple pattern matching implementation
  private func simpleMatch(_ path: String, pattern: String) -> Bool {
    // Handle patterns with multiple wildcards
    if pattern.contains("*") {
      return wildcardMatch(path, pattern: pattern)
    }

    // Handle single character wildcard
    if pattern.contains("?") {
      return questionMarkMatch(path, pattern: pattern)
    }

    // Exact match
    return path == pattern
  }

  /// Advanced wildcard matching for patterns containing `*`
  private func wildcardMatch(_ path: String, pattern: String) -> Bool {
    return globMatch(path, pattern: pattern)
  }

  /// Glob-style pattern matching supporting multiple wildcards
  private func globMatch(_ path: String, pattern: String) -> Bool {
    let pathChars = Array(path)
    let patternChars = Array(pattern)

    return globMatchRecursive(
      path: pathChars,
      pathIndex: 0,
      pattern: patternChars,
      patternIndex: 0
    )
  }

  /// Recursive glob matching implementation
  private func globMatchRecursive(
    path: [Character],
    pathIndex: Int,
    pattern: [Character],
    patternIndex: Int
  ) -> Bool {
    // If we've consumed the entire pattern, check if path is also consumed
    if patternIndex >= pattern.count {
      return pathIndex >= path.count
    }

    // If we've consumed the entire path but pattern remains
    if pathIndex >= path.count {
      // Only valid if remaining pattern is all '*'
      for i in patternIndex..<pattern.count {
        if pattern[i] != "*" {
          return false
        }
      }
      return true
    }

    let currentPatternChar = pattern[patternIndex]

    if currentPatternChar == "*" {
      // Try matching zero characters (skip *)
      if globMatchRecursive(
        path: path,
        pathIndex: pathIndex,
        pattern: pattern,
        patternIndex: patternIndex + 1
      ) {
        return true
      }

      // Try matching one or more characters
      for i in pathIndex..<path.count {
        // Don't let * match across directory boundaries
        if path[i] == "/" {
          break
        }
        if globMatchRecursive(
          path: path,
          pathIndex: i + 1,
          pattern: pattern,
          patternIndex: patternIndex + 1
        ) {
          return true
        }
      }

      return false
    } else if currentPatternChar == "?" {
      // Match exactly one character (but not /)
      if path[pathIndex] == "/" {
        return false
      }
      return globMatchRecursive(
        path: path,
        pathIndex: pathIndex + 1,
        pattern: pattern,
        patternIndex: patternIndex + 1
      )
    } else {
      // Exact character match
      if path[pathIndex] != currentPatternChar {
        return false
      }
      return globMatchRecursive(
        path: path,
        pathIndex: pathIndex + 1,
        pattern: pattern,
        patternIndex: patternIndex + 1
      )
    }
  }

  /// Question mark wildcard matching for patterns containing `?`
  private func questionMarkMatch(_ path: String, pattern: String) -> Bool {
    // Use the glob matcher which handles ? properly
    return globMatch(path, pattern: pattern)
  }
}
