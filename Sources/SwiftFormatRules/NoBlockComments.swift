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

import SwiftFormatCore
import SwiftSyntax

/// Block comments should be avoided in favor of line comments.
///
/// Lint: If a block comment appears, a lint error is raised.
public final class NoBlockComments: SyntaxLintRule {
  public override func visit(_ token: TokenSyntax) -> SyntaxVisitorContinueKind {
    for triviaIndex in token.leadingTrivia.indices {
      let piece = token.leadingTrivia[triviaIndex]
      if case .blockComment = piece {
        diagnose(.avoidBlockComment, on: token, leadingTriviaIndex: triviaIndex)
      }
    }
    return .skipChildren
  }
}

extension Finding.Message {
  public static let avoidBlockComment: Finding.Message =
    "replace block comment with line comments"
}
