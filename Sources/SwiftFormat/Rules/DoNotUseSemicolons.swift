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

public import SwiftSyntax

/// Semicolons should not be present in Swift code.
///
/// Lint: If a semicolon appears anywhere, a lint error is raised.
///
/// Format: All semicolons will be replaced with line breaks.
@_spi(Rules)
public final class DoNotUseSemicolons: SyntaxFormatRule {
  /// Creates a new version of the given node which doesn't contain any semicolons. The node's
  /// items are recursively modified to remove semicolons, replacing with line breaks where needed.
  /// Items are checked recursively to support items that contain code blocks, which may have
  /// semicolons to be removed.
  ///
  /// - Parameters:
  ///   - node: A node that contains items which may have semicolons or nested code blocks.
  ///   - nodeCreator: A closure that creates a new node given an array of items.
  private func nodeByRemovingSemicolons<
    ItemType: SyntaxProtocol & WithSemicolonSyntax & Equatable,
    NodeType: SyntaxCollection
  >(from node: NodeType) -> NodeType where NodeType.Element == ItemType {
    var newItems = Array(node)

    // Keeps track of trailing trivia after a semicolon when it needs to be moved to precede the
    // next statement.
    var pendingTrivia = Trivia()

    for (idx, item) in node.enumerated() {
      // Check for semicolons in statements inside of the item, because code blocks may be nested
      // inside of other code blocks.
      guard var newItem = rewrite(Syntax(item)).as(ItemType.self) else {
        return node
      }

      // Check if we need to make any modifications (removing semicolon/adding newlines).
      guard newItem != item || item.semicolon != nil || !pendingTrivia.isEmpty else {
        continue
      }

      // Check if the leading trivia for this statement needs a new line.
      if !pendingTrivia.isEmpty {
        newItem.leadingTrivia = pendingTrivia + newItem.leadingTrivia
      }
      pendingTrivia = []

      // If there's a semicolon, diagnose and remove it.
      // Exception: Do not remove the semicolon if it is separating a `do` statement from a `while`
      // statement.
      if let semicolon = item.semicolon,
        !(idx < node.count - 1
          && isCodeBlockItem(item, containingStmtType: DoStmtSyntax.self)
          && isCodeBlockItem(newItems[idx + 1], containingStmtType: WhileStmtSyntax.self))
      {
        // When emitting the finding, tell the user to move the next statement down if there is
        // another statement following this one. Otherwise, just tell them to remove the semicolon.
        var hasNextStatement: Bool
        if let nextToken = semicolon.nextToken(viewMode: .sourceAccurate),
          nextToken.tokenKind != .rightBrace && nextToken.tokenKind != .endOfFile
            && !nextToken.leadingTrivia.containsNewlines
        {
          hasNextStatement = true
          pendingTrivia = [.newlines(1)]
          diagnose(.removeSemicolonAndMove, on: semicolon)
        } else {
          hasNextStatement = false
          diagnose(.removeSemicolon, on: semicolon)
        }

        // We treat block comments after the semicolon slightly differently from end-of-line
        // comments. Assume that an end-of-line comment should stay on the same line when a
        // semicolon is removed, but if we have something like `f(); /* blah */ g()`, assume that
        // the comment is meant to be associated with `g()` (because it's not separated from that
        // statement).
        let trailingTrivia = newItem.trailingTrivia
        newItem.semicolon = nil
        if trailingTrivia.hasLineComment || !hasNextStatement {
          newItem.trailingTrivia = trailingTrivia
        } else {
          pendingTrivia += trailingTrivia.withoutLeadingSpaces()
        }
      }
      newItems[idx] = newItem
    }

    return NodeType(newItems)
  }

  public override func visit(_ node: CodeBlockItemListSyntax) -> CodeBlockItemListSyntax {
    return nodeByRemovingSemicolons(from: node)
  }

  public override func visit(_ node: MemberBlockItemListSyntax) -> MemberBlockItemListSyntax {
    return nodeByRemovingSemicolons(from: node)
  }

  /// Returns true if the given syntax node is a `CodeBlockItem` containing a statement node of the
  /// given type.
  private func isCodeBlockItem(
    _ node: some SyntaxProtocol,
    containingStmtType stmtType: any StmtSyntaxProtocol.Type
  ) -> Bool {
    if let codeBlockItem = node.as(CodeBlockItemSyntax.self),
      case .stmt(let stmt) = codeBlockItem.item,
      stmt.is(stmtType)
    {
      return true
    }
    return false
  }
}

extension Finding.Message {
  fileprivate static let removeSemicolon: Finding.Message = "remove ';'"

  fileprivate static let removeSemicolonAndMove: Finding.Message =
    "remove ';' and move the next statement to a new line"
}
