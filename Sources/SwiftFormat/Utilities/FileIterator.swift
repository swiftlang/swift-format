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

#if os(Windows)
import WinSDK
#endif

/// Iterator for looping over lists of files and directories. Directories are automatically
/// traversed recursively, and we check for files with a ".swift" extension.
@_spi(Internal)
public struct FileIterator: Sequence, IteratorProtocol {

  /// List of file and directory URLs to iterate over.
  private let urls: [URL]

  /// If true, symlinks will be followed when iterating over directories and files. If not, they
  /// will be ignored.
  private let followSymlinks: Bool

  /// Iterator for the list of URLs.
  private var urlIterator: Array<URL>.Iterator

  /// Iterator for recursing through directories.
  private var dirIterator: FileManager.DirectoryEnumerator? = nil

  /// The current working directory of the process, which is used to relativize URLs of files found
  /// during iteration.
  private let workingDirectory: URL

  /// Keep track of the current directory we're recursing through.
  private var currentDirectory = URL(fileURLWithPath: "")

  /// Keep track of files we have visited to prevent duplicates.
  private var visited: Set<String> = []

  /// The file extension to check for when recursing through directories.
  private let fileSuffix = ".swift"

  /// Optional ignore manager for filtering files based on .swift-format-ignore files.
  private let ignoreManager: IgnoreManager

  /// Create a new file iterator over the given list of file URLs.
  ///
  /// The given URLs may be files or directories. If they are directories, the iterator will recurse
  /// into them. Symlinks are never followed on Windows platforms as Foundation doesn't support it.
  /// - Parameters:
  ///   - urls: `Array` of files or directories to iterate.
  ///   - followSymlinks: `Bool` to indicate if symbolic links sthe current working directory. Used for testing.
  ///   - ignoreManager: Optional `IgnoreManager`hould be followed when iterating.
  ///   - workingDirectory: `URL` that indicates  to filter files based on .swift-format-ignore files.
  package init(
    urls: [URL],
    followSymlinks: Bool,
    workingDirectory: URL = URL(fileURLWithPath: "."),
    ignoreManager: IgnoreManager
  ) {
    self.workingDirectory = workingDirectory
    self.urls = urls
    self.urlIterator = self.urls.makeIterator()
    self.followSymlinks = followSymlinks
    self.ignoreManager = ignoreManager
  }

  public init(
    urls: [URL],
    followSymlinks: Bool,
    workingDirectory: URL = URL(fileURLWithPath: ".")
  ) {
    self.init(
      urls: urls,
      followSymlinks: followSymlinks,
      workingDirectory: workingDirectory,
      ignoreManager: IgnoreManager()
    )
  }

  /// Iterate through the "paths" list, and emit the file paths in it. If we encounter a directory,
  /// recurse through it and emit .swift file paths.
  public mutating func next() -> URL? {
    var output: URL? = nil
    while output == nil {
      // Check if we're recursing through a directory.
      if dirIterator != nil {
        output = nextInDirectory()
      } else {
        guard let next = urlIterator.next() else {
          // If we've reached the end of all the URLs we wanted to iterate over, exit now.
          return nil
        }
        guard let (next, fileType) = fileAndType(at: next, followSymlinks: followSymlinks) else {
          continue
        }

        switch fileType {
        case .typeSymbolicLink:
          // If we got here, we encountered a symlink but didn't follow it. Skip it.
          continue

        case .typeDirectory:
          if self.ignoreManager.shouldIgnore(file: next, isDirectory: true) {
            continue
          }
          dirIterator = FileManager.default.enumerator(
            at: next,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
          )
          currentDirectory = next

        default:
          // We'll get here if the path is a file, or if it doesn't exist.
          if self.ignoreManager.shouldIgnore(file: next, isDirectory: false) {
            continue
          }
          // If the file does not exists, return the path anyway; we'll turn the
          // error we get when we try to open the file into an appropriate
          // diagnostic instead of trying to handle it here.
          output = next
        }
      }

      if let out = output, visited.contains(out.standardizedFileURL.path) {
        output = nil
      }
    }
    if let out = output {
      visited.insert(out.standardizedFileURL.path)
    }
    return output
  }

  /// Use the FileManager API to recurse through directories and emit .swift file paths.
  private mutating func nextInDirectory() -> URL? {
    var output: URL? = nil
    while output == nil {
      guard let item = dirIterator?.nextObject() as? URL else {
        break
      }
      #if os(Windows)
      // Windows does not consider files and directories starting with `.` as hidden but we don't want to traverse
      // into eg. `.build`. Manually skip any items starting with `.`.
      if item.lastPathComponent.hasPrefix(".") {
        dirIterator?.skipDescendants()
        continue
      }
      #endif

      guard item.lastPathComponent.hasSuffix(fileSuffix),
        let (item, fileType) = fileAndType(at: item, followSymlinks: followSymlinks)
      else {
        continue
      }

      switch fileType {
      case .typeRegular:
        // We attempt to relativize the URLs based on the current working directory, not the
        // directory being iterated over, so that they can be displayed better in diagnostics. Thus,
        // if the user passes paths that are relative to the current working directory, they will
        // be displayed as relative paths. Otherwise, they will still be displayed as absolute
        // paths.
        let path = item.path
        let relativePath: String
        if !workingDirectory.isRoot, path.hasPrefix(workingDirectory.path) {
          relativePath = String(path.dropFirst(workingDirectory.path.count).drop(while: { $0 == "/" || $0 == #"\"# }))
        } else {
          relativePath = path
        }
        let fileURL = URL(fileURLWithPath: relativePath, isDirectory: false, relativeTo: workingDirectory)

        // Apply ignore filtering
        if self.ignoreManager.shouldIgnore(file: item, isDirectory: false) {
          output = nil
          continue  // Skip this file and continue to next
        }

        output = fileURL

      default:
        break
      }
    }
    // If we've exhausted the files in the directory recursion, unset the directory iterator.
    if output == nil {
      dirIterator = nil
    }
    return output
  }
}

/// Returns the actual URL and type of the file at the given URL, following symlinks if requested.
///
/// - Parameters:
///   - url: The URL to get the file and type of.
///   - followSymlinks: Whether to follow symlinks.
/// - Returns: The actual URL and type of the file at the given URL, or `nil` if the file does not
///   exist or is not a supported file type. If `followSymlinks` is `true`, the returned URL may be
///   different from the given URL; otherwise, it will be the same.
private func fileAndType(at url: URL, followSymlinks: Bool) -> (URL, FileAttributeType)? {
  func typeOfFile(at url: URL) -> FileAttributeType? {
    // We cannot use `URL.resourceValues(forKeys:)` here because it appears to behave incorrectly on
    // Linux.
    return try? FileManager.default.attributesOfItem(atPath: url.path)[.type] as? FileAttributeType
  }

  guard var fileType = typeOfFile(at: url) else {
    return nil
  }

  // We would use `standardizedFileURL.path` here as we do in the iterator above to ensure that
  // path components like `.` and `..` are resolved, but the standardized URLs returned by
  // Foundation pre-Swift-6.0 resolve symlinks. This causes the file type of a URL and its
  // standardized path to not match.
  var visited: Set<String> = [url.absoluteString]
  var url = url
  while followSymlinks && fileType == .typeSymbolicLink,
    let destination = try? FileManager.default.destinationOfSymbolicLink(atPath: url.path)
  {
    url = URL(fileURLWithPath: destination, relativeTo: url)
    // If this URL is in the visited set, we must have a symlink cycle. Ignore it gracefully.
    guard !visited.contains(url.absoluteString), let newType = typeOfFile(at: url) else {
      return nil
    }
    visited.insert(url.absoluteString)
    fileType = newType
  }
  return (url, fileType)
}
