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

/// A rule that both formats and lints a given file.
@_spi(Rules)
public class SyntaxFormatRule: SyntaxRewriter, Rule {
  /// Whether this rule is opt-in, meaning it's disabled by default. Rules are opt-out unless they
  /// override this property.
  public class var isOptIn: Bool {
    return false
  }

  /// The context in which the rule is executed.
  public let context: Context

  /// Indicates whether this rule is currently being executed as a syntax rewriter in
  /// `FormatPipeline` (`true`) or invoked node-by-node from `LintPipeline` (`false`).
  ///
  /// When `isRewriting` is `false`, `LintPipeline` already walks the syntax tree and dispatches
  /// each visited node to the rule's `visit` methods; suppressing child traversal in `visitAny`
  /// avoids re-walking subtrees during linting and emitting duplicate findings.
  var isRewriting: Bool = true

  /// Creates a new SyntaxFormatRule in the given context.
  public required init(context: Context) {
    self.context = context
  }

  /// Rewrites the given root syntax tree and updates `context` if the tree was modified.
  public func rewrite(_ node: Syntax, detach: Bool = false) -> Syntax {
    let superRewriter: SyntaxRewriter = self
    let newNode = superRewriter.rewrite(node, detach: detach)
    if !detach && !node.hasParent && node.is(SourceFileSyntax.self) && newNode != node {
      context.updateSyntaxTree(newNode, from: node)
    }
    return newNode
  }

  public override func visitAny(_ node: Syntax) -> Syntax? {
    // When running in `FormatPipeline`, descend into any node whose full range (including trivia)
    // overlaps the active selection and for which the rule is not disabled across the entire
    // subtree. Individual `visit` methods then check `shouldFormat` on the specific syntax node or
    // trivia range being rewritten so that `format` and `lint` apply identical selection boundary
    // semantics.
    guard
      isRewriting,
      context.isRuleEnabled(type(of: self), node: node),
      context.selection.overlapsOrTouches(node.position..<node.endPosition)
    else {
      return node
    }
    return nil
  }

  /// Returns whether the given syntax node should be formatted and linted by this rule under the
  /// current selection and rule mask.
  ///
  /// A node is eligible when its non-trivia token span (`positionAfterSkippingLeadingTrivia` to
  /// `endPositionBeforeTrailingTrivia`) lies completely within the active selection and the rule is
  /// enabled for that node.
  public func shouldFormat(_ node: some SyntaxProtocol) -> Bool {
    return context.shouldFormat(type(of: self), node: Syntax(node))
  }

  /// Returns whether the given trivia range attached to `node` should be formatted and linted by
  /// this rule under the current selection and rule mask.
  ///
  /// Trivia-rewriting rules (such as converting documentation block comments or removing empty
  /// lines adjacent to braces) use this helper so that selecting the lines containing the trivia
  /// formats and lints it even when the declaration or block to which the trivia is attached spans
  /// lines outside the selection.
  public func shouldFormat(_ node: some SyntaxProtocol, triviaRange: Range<AbsolutePosition>) -> Bool {
    return context.shouldFormat(type(of: self), node: Syntax(node), triviaRange: triviaRange)
  }
}
