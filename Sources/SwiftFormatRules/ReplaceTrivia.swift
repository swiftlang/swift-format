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

/// Rewriter that replaces the trivia of a given token inside a node with the provided
/// leading/trailing trivia.
fileprivate final class ReplaceTrivia: SyntaxRewriter {
  private let leadingTrivia: Trivia?
  private let trailingTrivia: Trivia?
  private let token: TokenSyntax

  init(token: TokenSyntax, leadingTrivia: Trivia? = nil, trailingTrivia: Trivia? = nil) {
    self.token = token
    self.leadingTrivia = leadingTrivia
    self.trailingTrivia = trailingTrivia
  }

  override func visit(_ token: TokenSyntax) -> Syntax {
    guard token == self.token else { return Syntax(token) }
    let newNode = token.withLeadingTrivia(leadingTrivia ?? token.leadingTrivia)
      .withTrailingTrivia(trailingTrivia ?? token.trailingTrivia)
    return Syntax(newNode)
  }
}

/// Replaces the leading or trailing trivia of a given node to the provided
/// leading and trailing trivia.
/// - Parameters:
///   - node: The Syntax node whose containing token will have its trivia replaced.
///   - token: The token whose trivia will be replaced. Must be a child of `node`. If `nil`, this
///            function is a no-op.
///   - leadingTrivia: The new leading trivia, if applicable. If nothing is provided, no change
///                    will be made.
///   - trailingTrivia: The new trailing trivia, if applicable. If nothing is provided, no change
///                     will be made.
/// - Note: Most of the time this function is called, `token` will be `node.firstToken` or
///         `node.lastToken`, which is almost always not `nil`. But in some very rare cases, like a
///         collection, it may be empty and not have a `firstToken`. Since there's nothing to
///         replace if token is `nil`, this function just exits early.
func replaceTrivia<SyntaxType: SyntaxProtocol>(
  on node: SyntaxType,
  token: TokenSyntax?,
  leadingTrivia: Trivia? = nil,
  trailingTrivia: Trivia? = nil
) -> SyntaxType {
  guard let token = token else { return node }
  return ReplaceTrivia(
    token: token,
    leadingTrivia: leadingTrivia,
    trailingTrivia: trailingTrivia
  ).visit(Syntax(node)).as(SyntaxType.self)!
}
