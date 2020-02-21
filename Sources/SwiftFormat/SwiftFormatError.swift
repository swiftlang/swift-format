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

import SwiftSyntax

/// Errors that can be thrown by the `SwiftFormatter` and `SwiftLinter` APIs.
public enum SwiftFormatError: Error {

  /// The requested file was not readable or it did not exist.
  case fileNotReadable

  /// The requested file was a directory.
  case isDirectory

  /// The file contains invalid or unrecognized Swift syntax and cannot be handled safely.
  case fileContainsInvalidSyntax(position: AbsolutePosition)
}
