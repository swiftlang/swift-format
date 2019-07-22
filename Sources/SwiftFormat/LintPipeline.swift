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

/// A syntax visitor that delegates to individual rules for linting.
///
/// This file will be extended with `visit` methods in Pipelines+Generated.swift.
struct LintPipeline: SyntaxVisitor {

  /// The formatter context.
  let context: Context

  /// Creates a new lint pipeline.
  init(context: Context) {
    self.context = context
  }

  /// Calls the `visit` method of a rule for the given node if that rule is enabled for the node.
  ///
  /// - Parameters:
  ///   - visitor: A reference to the `visit` method on the *type* of a `SyntaxLintRule` subclass.
  ///     The type of the rule in question is inferred from the signature of the method reference.
  ///   - context: The formatter context that contains information about which rules are enabled or
  ///     disabled.
  ///   - node: The syntax node on which the rule will be applied. This lets us check whether the
  ///     rule is enabled for the particular source range where the node occurs.
  func visitIfEnabled<Rule: SyntaxLintRule, Node: Syntax>(
    _ visitor: (Rule) -> (Node) -> SyntaxVisitorContinueKind, in context: Context, for node: Node
  ) {
    guard !context.isRuleDisabled(Rule.self.ruleName, node: node) else { return }
    let rule = Rule(context: context)
    _ = visitor(rule)(node)
  }

  /// Calls the `visit` method of a rule for the given node if that rule is enabled for the node.
  ///
  /// - Parameters:
  ///   - visitor: A reference to the `visit` method on the *type* of a `SyntaxFormatRule` subclass.
  ///     The type of the rule in question is inferred from the signature of the method reference.
  ///   - context: The formatter context that contains information about which rules are enabled or
  ///     disabled.
  ///   - node: The syntax node on which the rule will be applied. This lets us check whether the
  ///     rule is enabled for the particular source range where the node occurs.
  func visitIfEnabled<Rule: SyntaxFormatRule, Node: Syntax>(
    _ visitor: (Rule) -> (Node) -> Any, in context: Context, for node: Node
  ) {
    // Note that visitor function type is expressed as `Any` because we ignore the return value, but
    // more importantly because the `visit` methods return protocol refinements of `Syntax` that
    // cannot currently be expressed as constraints without duplicating this function for each of
    // them individually.
    guard !context.isRuleDisabled(Rule.self.ruleName, node: node) else { return }
    let rule = Rule(context: context)
    _ = visitor(rule)(node)
  }
}
