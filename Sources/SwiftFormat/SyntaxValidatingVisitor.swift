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
  /// Stores the start position of the first node that contains invalid syntax.
  var invalidSyntaxStartPosition: AbsolutePosition?

  override func visit(_ node: UnknownSyntax) -> SyntaxVisitorContinueKind {
    invalidSyntaxStartPosition = node.positionAfterSkippingLeadingTrivia
    return .skipChildren
  }

  override func visit(_ node: UnknownDeclSyntax) -> SyntaxVisitorContinueKind {
    invalidSyntaxStartPosition = node.positionAfterSkippingLeadingTrivia
    return .skipChildren
  }

  override func visit(_ node: UnknownExprSyntax) -> SyntaxVisitorContinueKind {
    invalidSyntaxStartPosition = node.positionAfterSkippingLeadingTrivia
    return .skipChildren
  }

  override func visit(_ node: UnknownStmtSyntax) -> SyntaxVisitorContinueKind {
    invalidSyntaxStartPosition = node.positionAfterSkippingLeadingTrivia
    return .skipChildren
  }

  override func visit(_ node: UnknownTypeSyntax) -> SyntaxVisitorContinueKind {
    invalidSyntaxStartPosition = node.positionAfterSkippingLeadingTrivia
    return .skipChildren
  }

  override func visit(_ node: UnknownPatternSyntax) -> SyntaxVisitorContinueKind {
    invalidSyntaxStartPosition = node.positionAfterSkippingLeadingTrivia
    return .skipChildren
  }

  override func visit(_ node: NonEmptyTokenListSyntax) -> SyntaxVisitorContinueKind {
    invalidSyntaxStartPosition = node.positionAfterSkippingLeadingTrivia
    return .skipChildren
  }

  override func visit(_ node: AttributeSyntax) -> SyntaxVisitorContinueKind {
    // The token list is used to collect any unexpected tokens. When it's missing or empty, then
    // there were no unexpected tokens. Otherwise, the attribute is invalid.
    guard node.tokenList?.isEmpty ?? true else {
      invalidSyntaxStartPosition = node.positionAfterSkippingLeadingTrivia
      return .skipChildren
    }
    return .visitChildren
  }
}

/// Determines whether the given syntax has any nodes which are invalid or unrecognized, and, if
/// so, returns the starting position of the first such node. Otherwise, returns nil indicating the
/// syntax is valid.
///
/// - Parameter syntax: The root of a tree of syntax nodes to check for compatibility.
public func _firstInvalidSyntaxPosition(in syntax: Syntax) -> AbsolutePosition? {
  let visitor = SyntaxValidatingVisitor(viewMode: .sourceAccurate)
  visitor.walk(syntax)
  return visitor.invalidSyntaxStartPosition
}
