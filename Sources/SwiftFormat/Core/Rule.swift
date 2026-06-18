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

/// A Rule is a linting or formatting pass that executes in a given context.
@_spi(Rules)
public protocol Rule {
  /// The context in which the rule is executed.
  var context: Context { get }

  /// The human-readable name of the rule. This defaults to the type name.
  static var ruleName: String { get }

  /// Whether this rule is opt-in, meaning it is disabled by default.
  static var isOptIn: Bool { get }

  /// The scope of the syntax node that this rule operates on.
  static var targetScope: RuleTargetScope { get }

  /// Creates a new Rule in a given context.
  init(context: Context)
}

/// The part of a node where an emitted finding should be anchored.
@_spi(Rules)
public enum FindingAnchor {
  /// The finding is anchored at the beginning of the node's actual content, skipping any leading
  /// trivia.
  case start

  /// The finding is anchored at the beginning of the trivia piece at the given index in the node's
  /// leading trivia.
  case leadingTrivia(Trivia.Index)

  /// The finding is anchored at the beginning of the trivia piece at the given index in the node's
  /// trailing trivia.
  case trailingTrivia(Trivia.Index)
}

/// Describes the portion of a syntax node that a rule targets.
@_spi(Rules)
public enum RuleTargetScope {
  /// The rule operates on the non-trivia content of the node.
  case content

  /// The rule operates on the leading trivia of the node.
  case leadingTrivia

  /// The rule operates on the trailing trivia of the node (such as end-of-line comments).
  case trailingTrivia

  /// The rule operates on either leading or trailing trivia of the node.
  case trivia

  /// The rule operates on the entire node, including all trivia and content.
  case all
}

extension Rule {
  /// By default, the `ruleName` is just the name of the implementing rule class.
  public static var ruleName: String { String("\(self)".split(separator: ".").last!) }

  /// By default, rules target the non-trivia content of a syntax node.
  public static var targetScope: RuleTargetScope { .content }

  /// Emits the given finding.
  ///
  /// - Parameters:
  ///   - message: The finding message to emit.
  ///   - node: The syntax node to which the finding should be attached. The finding's location will
  ///     be set to the start of the node (excluding leading trivia, unless `leadingTriviaIndex` is
  ///     provided).
  ///   - anchor: The part of the node where the finding should be anchored. Defaults to the start
  ///     of the node's content (after any leading trivia).
  ///   - notes: An array of notes that provide additional detail about the finding.
  public func diagnose<SyntaxType: SyntaxProtocol>(
    _ message: Finding.Message,
    on node: SyntaxType?,
    anchor: FindingAnchor = .start,
    notes: [Finding.Note] = []
  ) {
    let syntaxLocation: SourceLocation?
    if let node = node {
      switch anchor {
      case .start:
        syntaxLocation = node.startLocation(converter: context.sourceLocationConverter)
      case .leadingTrivia(let index):
        syntaxLocation = node.startLocation(
          ofLeadingTriviaAt: index,
          converter: context.sourceLocationConverter
        )
      case .trailingTrivia(let index):
        syntaxLocation = node.startLocation(
          ofTrailingTriviaAt: index,
          converter: context.sourceLocationConverter
        )
      }
    } else {
      syntaxLocation = nil
    }

    let category = RuleBasedFindingCategory(ruleType: type(of: self))
    context.findingEmitter.emit(
      message,
      category: category,
      location: syntaxLocation.flatMap(Finding.Location.init),
      notes: notes
    )
  }
}
