//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2024 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import Foundation

/// A file that describes which files and directories should be ignored by the formatter.
/// In the future, this file may contain complex rules for ignoring files, based
/// on pattern matching file paths.
/// 
/// Currently, the only valid content for an ignore file is a single asterisk "*",
/// optionally surrounded by whitespace.
public class IgnoreFile {
  /// Name of the ignore file to look for.
  /// The presence of this file in a directory will cause the formatter
  /// to skip formatting files in that directory and its subdirectories.
  fileprivate static let fileName = ".swift-format-ignore"

  /// Errors that can be thrown by the IgnoreFile initializer.
  public enum Error: Swift.Error {
    /// Error thrown when an ignore file has invalid content.
    case invalidContent(URL)
  }

  /// Create an instance from the contents of the file at the given URL.
  /// Throws an error if the file content can't be read, or is not valid.
  public init(contentsOf url: URL) throws {
    let content = try String(contentsOf: url, encoding: .utf8)
      guard content.trimmingCharacters(in: .whitespacesAndNewlines) == "*" else {
        throw Error.invalidContent(url)
      }
  } 

  /// Create an instance for the given directory, if a valid
  /// ignore file with the standard name is found in that directory.
  /// Returns nil if no ignore file is found.
  /// Throws an error if an invalid ignore file is found.
  ///
  /// Note that this initializer does not search parent directories for ignore files.
  public convenience init?(forDirectory directory: URL) throws {
    let url = directory.appendingPathComponent(IgnoreFile.fileName)
    guard FileManager.default.isReadableFile(atPath: url.path) else {
      return nil
    }

    try self.init(contentsOf: url)
  }

  /// Create an instance to use for the given URL.
  /// We search for an ignore file starting from the given URL's container,
  /// and moving up the directory tree, until we reach the root directory.
  /// Returns nil if no ignore file is found.
  /// Throws an error if an invalid ignore file is found somewhere 
  /// in the directory tree.
  ///
  /// Note that we start the search from the given URL's **container**,
  /// not the URL itself; the URL passed in is expected to be for a file.
  /// If you pass a directory URL, the search will not include the contents
  /// of that directory.
  public convenience init?(for url: URL) throws {
      var containingDirectory = url.absoluteURL.standardized
      repeat {
        containingDirectory.deleteLastPathComponent()
        let url = containingDirectory.appendingPathComponent(IgnoreFile.fileName)
        if FileManager.default.isReadableFile(atPath: url.path) {
          try self.init(contentsOf: url)
          return
        }
      } while !containingDirectory.isRoot
      return nil
  }

  /// Should the given URL be processed?
  /// Currently the only valid ignore file content is "*",
  /// which means that all files should be ignored.
  func shouldProcess(_ url: URL) -> Bool {
    return false
  }

  /// Returns true if the name of the given URL matches 
  /// the standard ignore file name.
  public static func isStandardIgnoreFile(_ url: URL) -> Bool {
    return url.lastPathComponent == fileName
  }
}