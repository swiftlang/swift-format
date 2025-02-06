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
import SwiftSyntax

/// Errors that can be thrown by the `SwiftFormatter` and `SwiftLinter` APIs.
public enum SwiftFormatError: LocalizedError {

  /// The requested file was not readable or it did not exist.
  case fileNotReadable

  /// The requested file was a directory.
  case isDirectory

  /// The file contains invalid or unrecognized Swift syntax and cannot be handled safely.
  case fileContainsInvalidSyntax

  /// The requested experimental feature name was not recognized by the parser.
  case unrecognizedExperimentalFeature(String)

  /// An error happened while dumping the tool's configuration.
  case configurationDumpFailed(String)

  public var errorDescription: String? {
    switch self {
    case .fileNotReadable:
      return "file is not readable or does not exist"
    case .isDirectory:
      return "requested path is a directory, not a file"
    case .fileContainsInvalidSyntax:
      return "file contains invalid Swift syntax"
    case .unrecognizedExperimentalFeature(let name):
      return "experimental feature '\(name)' was not recognized by the Swift parser"
    case .configurationDumpFailed(let message):
      return "dumping configuration failed: \(message)"
    }
  }
}

extension SwiftFormatError: Equatable {}
extension SwiftFormatError: Hashable {}
