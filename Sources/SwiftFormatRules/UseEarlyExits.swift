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

/// Early exits should be used whenever possible.
///
/// This means that `if ... else { return/throw/break/continue }` constructs should be replaced by
/// `guard ... else { return/throw/break/continue }` constructs in order to keep indentation levels
/// low. Specifically, code of the following form:
///
/// ```swift
/// if condition {
///   trueBlock
/// } else {
///   falseBlock
///   return/throw/break/continue
/// }
/// ```
///
/// will be transformed into:
///
/// ```swift
/// guard condition else {
///   falseBlock
///   return/throw/break/continue
/// }
/// trueBlock
/// ```
///
/// Lint: `if ... else { return/throw/break/continue }` constructs will yield a lint error.
///
/// Format: `if ... else { return/throw/break/continue }` constructs will be replaced with
///         equivalent `guard ... else { return/throw/break/continue }` constructs.
public final class UseEarlyExits: SyntaxFormatRule {

  /// Identifies this rule as being opt-in. This rule is experimental and not yet stable enough to
  /// be enabled by default.
  public override class var isOptIn: Bool { return true }

  public override func visit(_ node: CodeBlockItemListSyntax) -> Syntax {
    // Continue recursing down the tree first, so that any nested/child nodes get transformed first.
    let nodeAfterTransformingChildren = super.visit(node)
    guard let codeBlockItems = nodeAfterTransformingChildren.as(CodeBlockItemListSyntax.self) else {
      return nodeAfterTransformingChildren
    }

    let result = CodeBlockItemListSyntax(
      codeBlockItems.flatMap { (codeBlockItem: CodeBlockItemSyntax) -> [CodeBlockItemSyntax] in
        // The `elseBody` of an `IfStmtSyntax` will be a `CodeBlockSyntax` if it's an `else` block,
        // or another `IfStmtSyntax` if it's an `else if` block. We only want to handle the former.
        guard let ifStatement = codeBlockItem.item.as(IfStmtSyntax.self),
          let elseBody = ifStatement.elseBody?.as(CodeBlockSyntax.self),
          codeBlockEndsWithEarlyExit(elseBody)
        else {
          return [codeBlockItem]
        }

        diagnose(.useGuardStatement, on: ifStatement.elseKeyword)

        let trueBlock = ifStatement.body.withLeftBrace(nil).withRightBrace(nil)

        let guardKeyword = TokenSyntax.guardKeyword(
          leadingTrivia: ifStatement.ifKeyword.leadingTrivia,
          trailingTrivia: .spaces(1))
        let guardStatement = GuardStmtSyntax(
          guardKeyword: guardKeyword,
          conditions: ifStatement.conditions,
          elseKeyword: TokenSyntax.elseKeyword(trailingTrivia: .spaces(1)),
          body: elseBody)

        return [
          CodeBlockItemSyntax(item: Syntax(guardStatement), semicolon: nil, errorTokens: nil),
          CodeBlockItemSyntax(item: Syntax(trueBlock), semicolon: nil, errorTokens: nil),
        ]
      })
    return Syntax(result)
  }

  /// Returns true if the last statement in the given code block is one that will cause an early
  /// exit from the control flow construct or function.
  private func codeBlockEndsWithEarlyExit(_ codeBlock: CodeBlockSyntax) -> Bool {
    guard let lastStatement = codeBlock.statements.last else { return false }

    switch lastStatement.item.as(SyntaxEnum.self) {
    case .returnStmt, .throwStmt, .breakStmt, .continueStmt:
      return true
    default:
      return false
    }
  }
}

extension Finding.Message {
  public static let useGuardStatement: Finding.Message =
    "replace the `if/else` block with a `guard` statement containing the early exit"
}
