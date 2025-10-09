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

/// Read-only computed properties must use implicit `get` blocks.
///
/// Lint: Read-only computed properties with explicit `get` blocks yield a lint error.
///
/// Format: Explicit `get` blocks are rendered implicit by removing the `get`.
@_spi(Rules)
public final class UseSingleLinePropertyGetter: SyntaxFormatRule {

  public override func visit(_ node: PatternBindingSyntax) -> PatternBindingSyntax {
    guard
      let accessorBlock = node.accessorBlock,
      case .accessors(let accessors) = accessorBlock.accessors,
      let acc = accessors.first,
      let body = acc.body,
      accessors.count == 1,
      acc.accessorSpecifier.tokenKind == .keyword(.get),
      acc.modifier == nil,
      acc.effectSpecifiers == nil
    else { return node }

    diagnose(.removeExtraneousGetBlock, on: acc)

    var result = node
    result.accessorBlock?.accessors = .getter(body.statements.trimmed)

    var triviaBeforeStatements = Trivia()
    if let accessorPrecedingTrivia = node.accessorBlock?.accessors.allPrecedingTrivia {
      triviaBeforeStatements += accessorPrecedingTrivia
    }
    if acc.accessorSpecifier.trailingTrivia.hasAnyComments {
      triviaBeforeStatements += acc.accessorSpecifier.trailingTrivia
      triviaBeforeStatements += .newline
    }
    triviaBeforeStatements += body.statements.allPrecedingTrivia
    result.accessorBlock?.leftBrace.trailingTrivia =
      triviaBeforeStatements.trimmingSuperfluousNewlines(fromClosingBrace: false).0

    var triviaAfterStatements = body.statements.allFollowingTrivia
    if let accessorsFollowingTrivia = node.accessorBlock?.accessors.allFollowingTrivia {
      triviaAfterStatements += accessorsFollowingTrivia
    }
    result.accessorBlock?.accessors.trailingTrivia =
      triviaAfterStatements.trimmingSuperfluousNewlines(fromClosingBrace: true).0
    result.accessorBlock?.rightBrace.leadingTrivia = []
    return result
  }
}

extension Finding.Message {
  fileprivate static let removeExtraneousGetBlock: Finding.Message =
    "remove 'get {...}' around the accessor and move its body directly into the computed property"
}
