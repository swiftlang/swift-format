//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2019 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import Foundation

/// Iterator for looping over lists of files and directories. Directories are automatically
/// traversed recursively, and we check for files with a ".swift" extension.
struct FileIterator: Sequence, IteratorProtocol {

  /// List of file and directory paths to iterate over.
  let paths: [String]

  /// Iterator for "paths" list.
  var pathIterator: Array<String>.Iterator

  /// Iterator for recursing through directories.
  var dirIterator: FileManager.DirectoryEnumerator? = nil

  /// Keep track of the current directory we're recursing through.
  var currentDirectory: String = ""

  /// Keep track of paths we have visited to prevent duplicates.
  var visited: Set<String> = []

  /// The file extension to check for when recursing through directories.
  let fileSuffix = ".swift"

  /// The input is a list of paths as Strings. Some will be file paths, and others directories.
  public init(paths: [String]) {
    self.paths = paths
    self.pathIterator = self.paths.makeIterator()
  }

  /// Iterate through the "paths" list, and emit the file paths in it. If we encounter a directory,
  /// recurse through it and emit .swift file paths.
  mutating func next() -> String? {
    var output: String? = nil
    while output == nil {
      // Check if we're recursing through a directory
      if dirIterator != nil {
        output = nextInDirectory()
      } else {
        guard let next = pathIterator.next() else { return nil }
        var isDir: ObjCBool = false
        if FileManager.default.fileExists(atPath: next, isDirectory: &isDir) {
          if isDir.boolValue {
            dirIterator = FileManager.default.enumerator(atPath: next)
            currentDirectory = next
          } else { output = next }
        } else {
          // If a path doesn't exist, allow it pass down into the SwiftFormat API so it can throw
          // the appropriate exception. We don't want to kill the entire process if this happens.
          output = next
        }
      }
      if let out = output, visited.contains(out) { output = nil }
    }
    if let out = output { visited.insert(out) }
    return output
  }

  /// Use the FileManager API to recurse through directories and emit .swift file paths.
  private mutating func nextInDirectory() -> String? {
    var output: String? = nil
    while output == nil {
      var isDir: ObjCBool = false
      if let item = dirIterator?.nextObject() as? String {
        if item.hasSuffix(fileSuffix)
          && FileManager.default.fileExists(
            atPath: currentDirectory + "/" + item, isDirectory: &isDir)
          && !isDir.boolValue
        {
          output = currentDirectory + "/" + item
        }
      } else { break }
    }
    // If we've exhausted the files in the directory recursion, unset the directory iterator.
    if output == nil { dirIterator = nil }
    return output
  }
}
