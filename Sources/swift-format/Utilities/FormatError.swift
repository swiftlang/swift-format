//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2020 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import Foundation

struct FormatError: LocalizedError {
  var message: String
  var errorDescription: String? { message }

  static var exitWithDiagnosticErrors: FormatError {
    // The diagnostics engine has already printed errors to stderr.
    FormatError(message: "")
  }
}
