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

  /// Create a new file iterator over the given list of file URLs.
  ///
  /// The given URLs may be files or directories. If they are directories, the iterator will recurse
  /// into them. Symlinks are never followed on Windows platforms as Foundation doesn't support it.
  /// - Parameters:
  ///   - urls: `Array` of files or directories to iterate.
  ///   - followSymlinks: `Bool` to indicate if symbolic links should be followed when iterating.
  ///   - workingDirectory: `URL` that indicates the current working directory. Used for testing.
  public init(urls: [URL], followSymlinks: Bool, workingDirectory: URL = URL(fileURLWithPath: ".")) {
    self.workingDirectory = workingDirectory
    self.urls = urls.filter(inputShouldBeProcessed(at:))
    self.urlIterator = self.urls.makeIterator()
    self.followSymlinks = followSymlinks
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
        guard var next = urlIterator.next() else {
          // If we've reached the end of all the URLs we wanted to iterate over, exit now.
          return nil
        }

        guard let fileType = fileType(at: next) else {
          continue
        }

        switch fileType {
        case .typeSymbolicLink:
          guard
            followSymlinks,
            let destination = try? FileManager.default.destinationOfSymbolicLink(atPath: next.path)
          else {
            break
          }
          next = URL(fileURLWithPath: destination, relativeTo: next)
          fallthrough

        case .typeDirectory:
          do {
            if let ignoreFile = try IgnoreFile(forDirectory: next), !ignoreFile.shouldProcess(next) {
              // skip this directory and its subdirectories if it should be ignored
              continue
            }
          } catch IgnoreFile.Error.invalidFile(let url, _) {
            // we hit an invalid ignore file
            // we return the path of the ignore file so that we can report an error
            // and process the directory as normal
            output = url
          } catch {
            // we hit another unexpected error; process the directory as normal
          }

          dirIterator = FileManager.default.enumerator(
            at: next,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
          )
          currentDirectory = next

        default:
          // We'll get here if the path is a file, or if it doesn't exist. In the latter case,
          // return the path anyway; we'll turn the error we get when we try to open the file into
          // an appropriate diagnostic instead of trying to handle it here.
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

      guard item.lastPathComponent.hasSuffix(fileSuffix), let fileType = fileType(at: item) else {
        continue
      }

      var path = item.path
      switch fileType {
      case .typeSymbolicLink where followSymlinks:
        guard
          let destination = try? FileManager.default.destinationOfSymbolicLink(atPath: path)
        else {
          break
        }
        path = URL(fileURLWithPath: destination, relativeTo: item).path
        fallthrough

      case .typeRegular:
        // We attempt to relativize the URLs based on the current working directory, not the
        // directory being iterated over, so that they can be displayed better in diagnostics. Thus,
        // if the user passes paths that are relative to the current working directory, they will
        // be displayed as relative paths. Otherwise, they will still be displayed as absolute
        // paths.
        let relativePath: String
        if !workingDirectory.isRoot, path.hasPrefix(workingDirectory.path) {
          relativePath = String(path.dropFirst(workingDirectory.path.count).drop(while: { $0 == "/" || $0 == #"\"# }))
        } else {
          relativePath = path
        }
        output = URL(fileURLWithPath: relativePath, isDirectory: false, relativeTo: workingDirectory)

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

/// Returns the type of the file at the given URL.
private func fileType(at url: URL) -> FileAttributeType? {
  // We cannot use `URL.resourceValues(forKeys:)` here because it appears to behave incorrectly on
  // Linux.
  return try? FileManager.default.attributesOfItem(atPath: url.path)[.type] as? FileAttributeType
}

/// Returns true if the file should be processed.
/// Directories are always processed.
/// For other files, we look for an ignore file in the containing
/// directory or any of its parents.
/// If there is no ignore file, we process the file.
/// If an ignore file is found, we consult it to see if the file should be processed.
/// An invalid ignore file is treated here as if it does not exist, but
/// will be reported as an error when we try to process the directory.
private func inputShouldBeProcessed(at url: URL) -> Bool {
  guard fileType(at: url) != .typeDirectory else {
    return true
  }

  let ignoreFile = try? IgnoreFile(for: url)
  return ignoreFile?.shouldProcess(url) ?? true
}

fileprivate extension URL {
  var isRoot: Bool {
    #if os(Windows)
    // FIXME: We should call into Windows' native check to check if this path is a root once https://github.com/swiftlang/swift-foundation/issues/976 is fixed.
    // https://github.com/swiftlang/swift-format/issues/844
    return self.pathComponents.count <= 1
    #else
    // On Linux, we may end up with an string for the path due to https://github.com/swiftlang/swift-foundation/issues/980
    // TODO: Remove the check for "" once https://github.com/swiftlang/swift-foundation/issues/980 is fixed.
    return self.path == "/" || self.path == ""
    #endif
  }
}