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

  /// List of file and directory URLs to iterate over.
  let urls: [URL]

  /// Iterator for the list of URLs.
  var urlIterator: Array<URL>.Iterator

  /// Iterator for recursing through directories.
  var dirIterator: FileManager.DirectoryEnumerator? = nil

  /// The current working directory of the process, which is used to relativize URLs of files found
  /// during iteration.
  let workingDirectory = URL(fileURLWithPath: ".")

  /// Keep track of the current directory we're recursing through.
  var currentDirectory = URL(fileURLWithPath: "")

  /// Keep track of files we have visited to prevent duplicates.
  var visited: Set<String> = []

  /// The file extension to check for when recursing through directories.
  let fileSuffix = ".swift"

  /// Create a new file iterator over the given list of file URLs.
  ///
  /// The given URLs may be files or directories. If they are directories, the iterator will recurse
  /// into them.
  init(urls: [URL]) {
    self.urls = urls
    self.urlIterator = self.urls.makeIterator()
  }

  /// Iterate through the "paths" list, and emit the file paths in it. If we encounter a directory,
  /// recurse through it and emit .swift file paths.
  mutating func next() -> URL? {
    var output: URL? = nil
    while output == nil {
      // Check if we're recursing through a directory.
      if dirIterator != nil {
        output = nextInDirectory()
      } else {
        guard let next = urlIterator.next() else { return nil }
        var isDir: ObjCBool = false
        if FileManager.default.fileExists(atPath: next.path, isDirectory: &isDir), isDir.boolValue {
          dirIterator = FileManager.default.enumerator(at: next, includingPropertiesForKeys: nil)
          currentDirectory = next
        } else {
          // We'll get here if the path is a file, or if it doesn't exist. In the latter case,
          // return the path anyway; we'll turn the error we get when we try to open the file into
          // an appropriate diagnostic instead of trying to handle it here.
          output = next
        }
      }
      if let out = output, visited.contains(out.absoluteURL.standardized.path) {
        output = nil
      }
    }
    if let out = output {
      visited.insert(out.absoluteURL.standardized.path)
    }
    return output
  }

  /// Use the FileManager API to recurse through directories and emit .swift file paths.
  private mutating func nextInDirectory() -> URL? {
    var output: URL? = nil
    while output == nil {
      if let item = dirIterator?.nextObject() as? URL {
        if item.lastPathComponent.hasSuffix(fileSuffix) {
          var isDir: ObjCBool = false
          if FileManager.default.fileExists(atPath: item.path, isDirectory: &isDir)
            && !isDir.boolValue
          {
            // We can't use the `.producesRelativePathURLs` enumeration option because it isn't
            // supported yet on Linux, so we need to relativize the URL ourselves.
            let relativePath =
              item.path.hasPrefix(workingDirectory.path)
              ? String(item.path.dropFirst(workingDirectory.path.count + 1))
              : item.path
            output =
              URL(fileURLWithPath: relativePath, isDirectory: false, relativeTo: workingDirectory)
          }
        }
      } else { break }
    }
    // If we've exhausted the files in the directory recursion, unset the directory iterator.
    if output == nil {
      dirIterator = nil
    }
    return output
  }
}
