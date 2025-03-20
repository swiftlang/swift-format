//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2021 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

/// A finding category that wraps a `Rule` type.
///
/// Findings emitted by `SyntaxLintRule` and `SyntaxFormatRule` subclasses automatically emit their
/// findings using this category type, via an instance that wraps the calling rule. The displayable
/// name of the category is the same as the rule's name provided by the `ruleName` property (which
/// defaults to the rule's type name).
struct RuleBasedFindingCategory: FindingCategorizing {
  /// The type of the rule associated with this category.
  private let ruleType: Rule.Type

  var description: String { ruleType.ruleName }

  /// Creates a finding category that wraps the given rule type.
  init(ruleType: Rule.Type) {
    self.ruleType = ruleType
  }
}
