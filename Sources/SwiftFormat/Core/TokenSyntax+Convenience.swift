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

extension TokenSyntax {
  /// Returns this token with only one space at the end of its trailing trivia.
  func withOneTrailingSpace() -> TokenSyntax {
    return with(\.trailingTrivia, trailingTrivia.withOneTrailingSpace())
  }

  /// Returns this token with only one space at the beginning of its leading
  /// trivia.
  func withOneLeadingSpace() -> TokenSyntax {
    return with(\.leadingTrivia, leadingTrivia.withOneLeadingSpace())
  }

  /// Returns this token with only one newline at the end of its leading trivia.
  func withOneTrailingNewline() -> TokenSyntax {
    return with(\.trailingTrivia, trailingTrivia.withOneTrailingNewline())
  }

  /// Returns this token with only one newline at the beginning of its leading
  /// trivia.
  func withOneLeadingNewline() -> TokenSyntax {
    return with(\.leadingTrivia, leadingTrivia.withOneLeadingNewline())
  }
}
