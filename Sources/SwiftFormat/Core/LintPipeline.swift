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

/// A syntax visitor that delegates to individual rules for linting.
///
/// This file will be extended with `visit` methods in Pipelines+Generated.swift.
extension LintPipeline {
  /// Calls the `visit` method of a rule for the given node if that rule is enabled for the node.
  ///
  /// - Parameters:
  ///   - visitor: A reference to the `visit` method on the *type* of a `SyntaxLintRule` subclass.
  ///     The type of the rule in question is inferred from the signature of the method reference.
  ///   - context: The formatter context that contains information about which rules are enabled or
  ///     disabled.
  ///   - node: The syntax node on which the rule will be applied. This lets us check whether the
  ///     rule is enabled for the particular source range where the node occurs.
  func visitIfEnabled<Rule: SyntaxLintRule, Node: SyntaxProtocol>(
    _ visitor: (Rule) -> (Node) -> SyntaxVisitorContinueKind,
    for node: Node
  ) {
    guard context.shouldFormat(Rule.self, node: Syntax(node)) else { return }
    let ruleId = ObjectIdentifier(Rule.self)
    guard self.shouldSkipChildren[ruleId] == nil else { return }
    let rule = self.rule(Rule.self)
    let continueKind = visitor(rule)(node)
    if case .skipChildren = continueKind {
      self.shouldSkipChildren[ruleId] = node
    }
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
  func visitIfEnabled<Rule: SyntaxFormatRule, Node: SyntaxProtocol>(
    _ visitor: (Rule) -> (Node) -> Any,
    for node: Node
  ) {
    // Note that visitor function type is expressed as `Any` because we ignore the return value, but
    // more importantly because the `visit` methods return protocol refinements of `Syntax` that
    // cannot currently be expressed as constraints without duplicating this function for each of
    // them individually.
    guard context.shouldFormat(Rule.self, node: Syntax(node)) else { return }
    guard self.shouldSkipChildren[ObjectIdentifier(Rule.self)] == nil else { return }
    let rule = self.rule(Rule.self)
    _ = visitor(rule)(node)
  }

  /// Cleans up any state associated with `rule` when we leave syntax node `node`
  ///
  /// - Parameters:
  ///   - rule: The type of the syntax rule we're cleaning up.
  ///   - node: The syntax node htat our traversal has left.
  func onVisitPost<R: Rule, Node: SyntaxProtocol>(
    rule: R.Type,
    for node: Node
  ) {
    let rule = ObjectIdentifier(rule)
    if case .some(let skipNode) = self.shouldSkipChildren[rule] {
      if node.id == skipNode.id {
        self.shouldSkipChildren.removeValue(forKey: rule)
      }
    }
  }

  /// Retrieves an instance of a lint or format rule based on its type.
  ///
  /// There is at most 1 instance of each rule allocated per `LintPipeline`. This method will
  /// create that instance as needed, using `ruleCache` to cache rules.
  /// - Parameter type: The type of the rule to retrieve.
  /// - Returns: An instance of the given type.
  private func rule<R: Rule>(_ type: R.Type) -> R {
    let identifier = ObjectIdentifier(type)
    if let cachedRule = ruleCache[identifier] {
      return cachedRule as! R
    }
    let rule = R(context: context)
    ruleCache[identifier] = rule
    return rule
  }
}
