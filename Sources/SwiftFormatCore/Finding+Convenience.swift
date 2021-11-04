//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2021 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import SwiftSyntax

extension Finding.Location {
  /// Creates a new `Finding.Location` by converting the given `SourceLocation` from `SwiftSyntax`.
  ///
  /// If the source location is invalid (i.e., any of its fields are nil), then the initializer will
  /// return nil.
  public init?(_ sourceLocation: SourceLocation) {
    guard
      let file = sourceLocation.file,
      let line = sourceLocation.line,
      let column = sourceLocation.column
    else {
      return nil
    }

    self.init(file: file, line: line, column: column)
  }
}
