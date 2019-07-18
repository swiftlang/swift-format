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
import SwiftFormatCore
import SwiftSyntax

/// Semicolons should not be present in Swift code.
///
/// Lint: If a semicolon appears anywhere, a lint error is raised.
///
/// Format: All semicolons will be replaced with line breaks.
///
/// - SeeAlso: https://google.github.io/swift#semicolons
public final class DoNotUseSemicolons: SyntaxFormatRule {
  private func transformItems(_ items: CodeBlockItemListSyntax) -> CodeBlockItemListSyntax {
    var newItems = Array(items)

    // Because newlines belong to the _first_ token on the new line, if we remove a semicolon, we
    // need to keep track of the fact that the next statement needs a new line.
    var previousHadSemicolon = false
    for (idx, item) in items.enumerated() {

      // Store the previous statement's semicolon-ness.
      defer { previousHadSemicolon = item.semicolon != nil }

      // Check if we need to make any modifications (removing semicolon/adding newlines)
      guard item.semicolon != nil || previousHadSemicolon else {
        continue
      }

      var newItem = item

      if previousHadSemicolon {
        // Ensure the leading trivia for this statement has a newline.
        let firstTok = item.firstToken
        newItem = replaceTrivia(
          on: item,
          token: firstTok,
          leadingTrivia: firstTok?.leadingTrivia.withOneLeadingNewline() ?? .newlines(1)
        ) as! CodeBlockItemSyntax
      }

      // If there's a semicolon, diagnose and remove it.
      if idx < items.count {
        diagnose(.removeSemicolonAndMove, on: item)
      } else {
        diagnose(.removeSemicolon, on: item)
      }
      newItem = newItem.withSemicolon(nil)
      newItems[idx] = newItem
    }
    return SyntaxFactory.makeCodeBlockItemList(newItems)
  }

  public override func visit(_ node: CodeBlockSyntax) -> Syntax {
    return node.withStatements(transformItems(node.statements))
  }

  public override func visit(_ node: SourceFileSyntax) -> Syntax {
    return node.withStatements(transformItems(node.statements))
  }
}

extension Diagnostic.Message {
  static let removeSemicolon = Diagnostic.Message(.warning, "remove ';'")

  static let removeSemicolonAndMove = Diagnostic.Message(
    .warning, "remove ';' and move the next statement to a new line")
}
