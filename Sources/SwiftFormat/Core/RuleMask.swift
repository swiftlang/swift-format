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

/// This class takes the raw source text and scans through it searching for comments that instruct
/// the formatter to change the status of rules for the following node. The comments may include no
/// rule names to affect all rules, a single rule name to affect that rule, or a comma delimited
/// list of rule names to affect a number of rules. Ignore is the only supported operation.
///
///   1. |  // swift-format-ignore
///   2. |  let a = 123
///   Ignores all rules for line 2.
///
///   1. |  // swift-format-ignore-file
///   2. |  let a = 123
///   3. | class Foo { }
///   Ignores all rules for an entire file (lines 2-3).
///
///   1. |  // swift-format-ignore: RuleName
///   2. |  let a = 123
///   Ignores `RuleName` for line 2.
///
///   1. |  // swift-format-ignore: RuleName, OtherRuleName
///   2. |  let a = 123
///   Ignores `RuleName` and `OtherRuleName` for line 2.
///
///   1. |  // swift-format-ignore-file: RuleName
///   2. |  let a = 123
///   3. | class Foo { }
///   Ignores `RuleName` for the entire file (lines 2-3).
///
///   1. |  // swift-format-ignore-file: RuleName, OtherRuleName
///   2. |  let a = 123
///   3. | class Foo { }
///   Ignores `RuleName` and `OtherRuleName` for the entire file (lines 2-3).
///
/// The rules themselves reference RuleMask to see if it is disabled for the line it is currently
/// examining.
@_spi(Testing)
public class RuleMask {
  /// Stores the source ranges in which all rules are ignored.
  private var allRulesIgnoredRanges: [SourceRange] = []

  /// Map of rule names to list ranges in the source where the rule is ignored.
  private var ruleMap: [String: [SourceRange]] = [:]

  /// Used to compute line numbers of syntax nodes.
  private let sourceLocationConverter: SourceLocationConverter

  /// Creates a `RuleMask` that can specify whether a given rule's status is explicitly modified at
  /// a location obtained from the `SourceLocationConverter`.
  ///
  /// Ranges in the source where rules' statuses are modified are pre-computed during init so that
  /// lookups later don't require parsing the source.
  public init(syntaxNode: Syntax, sourceLocationConverter: SourceLocationConverter) {
    self.sourceLocationConverter = sourceLocationConverter
    computeIgnoredRanges(in: syntaxNode)
  }

  /// Computes the ranges in the given node where the status of rules are explicitly modified.
  private func computeIgnoredRanges(in node: Syntax) {
    let visitor = RuleStatusCollectionVisitor(sourceLocationConverter: sourceLocationConverter)
    visitor.walk(node)
    allRulesIgnoredRanges = visitor.allRulesIgnoredRanges
    ruleMap = visitor.ruleMap
  }

  /// Returns the `RuleState` for the given rule at the provided location.
  public func ruleState(_ rule: String, at location: SourceLocation) -> RuleState {
    if allRulesIgnoredRanges.contains(where: { $0.contains(location) }) {
      return .disabled
    }
    if let ignoredRanges = ruleMap[rule] {
      return ignoredRanges.contains { $0.contains(location) } ? .disabled : .default
    }
    return .default
  }
}

extension SourceRange {
  /// Returns whether the range includes the given location.
  fileprivate func contains(_ location: SourceLocation) -> Bool {
    return start.offset <= location.offset && end.offset >= location.offset
  }
}

/// Represents the kind of ignore directive encountered in the source.
enum IgnoreDirective: CustomStringConvertible {
  typealias RegexExpression = Regex<(Substring, ruleNames: Substring?)>

  /// A node-level directive that disables rules for the following node and its children.
  case node
  /// A file-level directive that disables rules for the entire file.
  case file

  var description: String {
    switch self {
    case .node:
      return "swift-format-ignore"
    case .file:
      return "swift-format-ignore-file"
    }
  }

  /// Regex pattern to match an ignore directive comment.
  /// - Captures rule names when `:` is present.
  ///
  /// Note: We are using a string-based regex instead of a regex literal (`#/regex/#`)
  /// because Windows did not have full support for regex literals until Swift 5.10.
  fileprivate func makeRegex() -> RegexExpression {
    let pattern = #"^\s*\/\/\s*"# + description + #"(?:\s*:\s*(?<ruleNames>.+))?$"#
    return try! Regex(pattern).matchingSemantics(.unicodeScalar)
  }
}

/// A syntax visitor that finds `SourceRange`s of nodes that have rule status modifying comment
/// directives. The changes requested in each comment is parsed and collected into a map to support
/// status lookup per rule name.
///
/// The rule status comment directives implementation intentionally supports exactly the same nodes
/// as `TokenStreamCreator` to disable pretty printing. This ensures ignore comments for pretty
/// printing and for rules are as consistent as possible.
fileprivate class RuleStatusCollectionVisitor: SyntaxVisitor {
  /// Describes the possible matches for ignore directives, in comments.
  enum RuleStatusDirectiveMatch {
    /// There is a directive that applies to all rules.
    case all

    /// There is a directive that applies to a number of rules. The names of the rules are provided
    /// in `ruleNames`.
    case subset(ruleNames: [String])
  }

  /// Cached regex object for ignoring rules at the node.
  private static let ignoreRegex: IgnoreDirective.RegexExpression = IgnoreDirective.node.makeRegex()

  /// Cached regex object for ignoring rules at the file.
  private static let ignoreFileRegex: IgnoreDirective.RegexExpression = IgnoreDirective.file.makeRegex()

  /// Computes source locations and ranges for syntax nodes in a source file.
  private let sourceLocationConverter: SourceLocationConverter

  /// Stores the source ranges in which all rules are ignored.
  var allRulesIgnoredRanges: [SourceRange] = []

  /// Map of rule names to list ranges in the source where the rule is ignored.
  var ruleMap: [String: [SourceRange]] = [:]

  init(sourceLocationConverter: SourceLocationConverter) {
    self.sourceLocationConverter = sourceLocationConverter
    super.init(viewMode: .sourceAccurate)
  }

  // MARK: - Syntax Visitation Methods

  override func visit(_ node: SourceFileSyntax) -> SyntaxVisitorContinueKind {
    guard let firstToken = node.firstToken(viewMode: .sourceAccurate) else {
      return .visitChildren
    }
    let sourceRange = node.sourceRange(
      converter: sourceLocationConverter,
      afterLeadingTrivia: false,
      afterTrailingTrivia: true
    )
    return appendRuleStatus(from: firstToken, of: sourceRange, using: Self.ignoreFileRegex)
  }

  override func visit(_ node: CodeBlockItemSyntax) -> SyntaxVisitorContinueKind {
    guard let firstToken = node.firstToken(viewMode: .sourceAccurate) else {
      return .visitChildren
    }
    let sourceRange = node.sourceRange(converter: sourceLocationConverter)
    return appendRuleStatus(from: firstToken, of: sourceRange, using: Self.ignoreRegex)
  }

  override func visit(_ node: MemberBlockItemSyntax) -> SyntaxVisitorContinueKind {
    guard let firstToken = node.firstToken(viewMode: .sourceAccurate) else {
      return .visitChildren
    }
    let sourceRange = node.sourceRange(converter: sourceLocationConverter)
    return appendRuleStatus(from: firstToken, of: sourceRange, using: Self.ignoreRegex)
  }

  // MARK: - Helper Methods

  /// Searches for comments on the given token that explicitly modify the status of rules and adds
  /// them to the appropriate collection of those changes.
  ///
  /// - Parameters:
  ///   - token: A token that may have comments that modify the status of rules.
  ///   - sourceRange: The range covering the node to which `token` belongs. If an ignore directive
  ///     is found among the comments, this entire range is used to ignore the specified rules.
  ///   - regex: The regular expression used to detect ignore directives.
  private func appendRuleStatus(
    from token: TokenSyntax,
    of sourceRange: SourceRange,
    using regex: IgnoreDirective.RegexExpression
  ) -> SyntaxVisitorContinueKind {
    let isFirstInFile = token.previousToken(viewMode: .sourceAccurate) == nil
    let comments = loneLineComments(in: token.leadingTrivia, isFirstToken: isFirstInFile)
    for comment in comments {
      guard let matchResult = ruleStatusDirectiveMatch(in: comment, using: regex) else { continue }
      switch matchResult {
      case .all:
        allRulesIgnoredRanges.append(sourceRange)

        // All rules are ignored for the entire node and its children. Any ignore comments in the
        // node's children are irrelevant because all rules are suppressed by this node.
        return .skipChildren
      case .subset(let ruleNames):
        ruleNames.forEach { ruleMap[$0, default: []].append(sourceRange) }
        break
      }
    }
    return .visitChildren
  }

  /// Checks if a comment containing the given text matches a rule status directive. When it does
  /// match, its contents (e.g. list of rule names) are returned.
  private func ruleStatusDirectiveMatch(
    in text: String,
    using regex: IgnoreDirective.RegexExpression
  ) -> RuleStatusDirectiveMatch? {
    guard let match = text.firstMatch(of: regex) else {
      return nil
    }
    guard let matchedRuleNames = match.output.ruleNames else {
      return .all
    }
    let rules = matchedRuleNames.split(separator: ",")
      .map { $0.trimmingCharacters(in: .whitespaces) }
      .filter { $0.count > 0 }
    return .subset(ruleNames: rules)
  }

  /// Returns the list of line comments in the given trivia that are on a line by themselves
  /// (excluding leading whitespace).
  ///
  /// - Parameters:
  ///   - trivia: The trivia collection to scan for comments.
  ///   - isFirstToken: True if the trivia came from the first token in the file.
  /// - Returns: The list of lone line comments from the trivia.
  private func loneLineComments(in trivia: Trivia, isFirstToken: Bool) -> [String] {
    var currentComment: String? = nil
    var lineComments = [String]()

    for piece in trivia.reversed() {
      switch piece {
      case .lineComment(let text):
        currentComment = text
      case .spaces, .tabs:
        break  // Intentionally do nothing.
      case .carriageReturnLineFeeds, .carriageReturns, .newlines:
        if let text = currentComment {
          lineComments.insert(text, at: 0)
          currentComment = nil
        }
      default:
        // If anything other than spaces intervened between the line comment and a newline, then the
        // comment isn't on a line by itself, so reset our state.
        currentComment = nil
      }
    }

    // For the first token in the file, there may not be a newline preceding the first line comment,
    // so check for that here.
    if isFirstToken, let text = currentComment {
      lineComments.insert(text, at: 0)
    }

    return lineComments
  }
}
