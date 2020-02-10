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

import SwiftSyntax

/// A SyntaxVisitor that searches for nodes that cannot be handled safely.
fileprivate class SyntaxValidatingVisitor: SyntaxVisitor {
  /// Tracks whether an invalid node has been encountered.
  var isValidSyntax = true

  override func visit(_ node: UnknownSyntax) -> SyntaxVisitorContinueKind {
    isValidSyntax = false
    return .skipChildren
  }

  override func visit(_ node: UnknownDeclSyntax) -> SyntaxVisitorContinueKind {
    isValidSyntax = false
    return .skipChildren
  }

  override func visit(_ node: UnknownExprSyntax) -> SyntaxVisitorContinueKind {
    isValidSyntax = false
    return .skipChildren
  }

  override func visit(_ node: UnknownStmtSyntax) -> SyntaxVisitorContinueKind {
    isValidSyntax = false
    return .skipChildren
  }

  override func visit(_ node: UnknownTypeSyntax) -> SyntaxVisitorContinueKind {
    isValidSyntax = false
    return .skipChildren
  }

  override func visit(_ node: UnknownPatternSyntax) -> SyntaxVisitorContinueKind {
    isValidSyntax = false
    return .skipChildren
  }

  override func visit(_ node: NonEmptyTokenListSyntax) -> SyntaxVisitorContinueKind {
    isValidSyntax = false
    return .skipChildren
  }

  override func visit(_ node: AttributeSyntax) -> SyntaxVisitorContinueKind {
    // The token list is used to collect any unexpected tokens. When it's missing or empty, then
    // there were no unexpected tokens. Otherwise, the attribute is invalid.
    guard node.tokenList?.isEmpty ?? true else {
      isValidSyntax = false
      return .skipChildren
    }
    return .visitChildren
  }
}

/// Returns whether the given syntax contains any nodes which are invalid or unrecognized and
/// cannot be handled safely.
///
/// - Parameter syntax: The root of a tree of syntax nodes to check for compatibility.
func isSyntaxValidForProcessing(_ syntax: Syntax) -> Bool {
  let visitor = SyntaxValidatingVisitor()
  visitor.walk(syntax)
  return visitor.isValidSyntax
}
