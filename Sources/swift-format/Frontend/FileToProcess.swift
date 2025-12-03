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

import Foundation
import SwiftFormat

/// Represents a file to be processed by the frontend and any file-specific options associated
/// with it.
struct FileToProcess: ~Copyable {
  /// An open file handle to the source code of the file.
  private let fileHandle: FileHandle

  /// A file URL representing the path to the source file being processed.
  ///
  /// It is the responsibility of the specific frontend to make guarantees about the validity of
  /// this path. For example, the formatting frontend ensures that it is a path to an existing
  /// file only when doing in-place formatting (so that the file can be replaced). In other
  /// situations, it may correspond to a different file than the underlying file handle (if
  /// standard input is used with the `--assume-filename` flag), or it may not be a valid path at
  /// all (the string `"<stdin>"`).
  let url: URL

  /// The configuration that should applied for this file.
  let configuration: Configuration

  /// the selected ranges to process
  let selection: Selection

  /// Returns the string contents of the file.
  ///
  /// The contents of the file are assumed to be UTF-8 encoded. If there is an error decoding the
  /// contents, `nil` will be returned.
  func readString() -> String? {
    let sourceData = fileHandle.readDataToEndOfFile()
    defer { fileHandle.closeFile() }
    return String(data: sourceData, encoding: .utf8)
  }

  init(
    fileHandle: FileHandle,
    url: URL,
    configuration: Configuration,
    selection: Selection = .infinite
  ) {
    self.fileHandle = fileHandle
    self.url = url
    self.configuration = configuration
    self.selection = selection
  }
}
