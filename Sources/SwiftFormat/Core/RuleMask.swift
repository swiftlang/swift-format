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

  /// Computes source locations and ranges for syntax nodes in a source file.
  private let sourceLocationConverter: SourceLocationConverter

  /// Regex pattern to match an ignore comment. This pattern supports 0 or more comma delimited rule
  /// names. The rule name(s), when present, are in capture group #3.
  private let ignorePattern =
    #"^\s*\/\/\s*swift-format-ignore((:\s+(([A-z0-9]+[,\s]*)+))?$|\s+$)"#

  /// Rule ignore regex object.
  private let ignoreRegex: NSRegularExpression

  /// Regex pattern to match an ignore comment that applies to an entire file.
  private let ignoreFilePattern = #"^\s*\/\/\s*swift-format-ignore-file$"#

  /// Rule ignore regex object.
  private let ignoreFileRegex: NSRegularExpression

  /// Stores the source ranges in which all rules are ignored.
  var allRulesIgnoredRanges: [SourceRange] = []

  /// Map of rule names to list ranges in the source where the rule is ignored.
  var ruleMap: [String: [SourceRange]] = [:]

  init(sourceLocationConverter: SourceLocationConverter) {
    ignoreRegex = try! NSRegularExpression(pattern: ignorePattern, options: [])
    ignoreFileRegex = try! NSRegularExpression(pattern: ignoreFilePattern, options: [])

    self.sourceLocationConverter = sourceLocationConverter
    super.init(viewMode: .sourceAccurate)
  }

  // MARK: - Syntax Visitation Methods

  override func visit(_ node: SourceFileSyntax) -> SyntaxVisitorContinueKind {
    guard let firstToken = node.firstToken(viewMode: .sourceAccurate) else {
      return .visitChildren
    }
    let comments = loneLineComments(in: firstToken.leadingTrivia, isFirstToken: true)
    var foundIgnoreFileComment = false
    for comment in comments {
      let range = NSRange(comment.startIndex..<comment.endIndex, in: comment)
      if ignoreFileRegex.firstMatch(in: comment, options: [], range: range) != nil {
        foundIgnoreFileComment = true
        break
      }
    }
    guard foundIgnoreFileComment else {
      return .visitChildren
    }

    let sourceRange = node.sourceRange(
      converter: sourceLocationConverter,
      afterLeadingTrivia: false,
      afterTrailingTrivia: true
    )
    allRulesIgnoredRanges.append(sourceRange)
    return .skipChildren
  }

  override func visit(_ node: CodeBlockItemSyntax) -> SyntaxVisitorContinueKind {
    guard let firstToken = node.firstToken(viewMode: .sourceAccurate) else {
      return .visitChildren
    }
    return appendRuleStatusDirectives(from: firstToken, of: Syntax(node))
  }

  override func visit(_ node: MemberBlockItemSyntax) -> SyntaxVisitorContinueKind {
    guard let firstToken = node.firstToken(viewMode: .sourceAccurate) else {
      return .visitChildren
    }
    return appendRuleStatusDirectives(from: firstToken, of: Syntax(node))
  }

  // MARK: - Helper Methods

  /// Searches for comments on the given token that explicitly modify the status of rules and adds
  /// them to the appropriate collection of those changes.
  ///
  /// - Parameters:
  ///   - token: A token that may have comments that modify the status of rules.
  ///   - node: The node to which the token belongs.
  private func appendRuleStatusDirectives(
    from token: TokenSyntax,
    of node: Syntax
  ) -> SyntaxVisitorContinueKind {
    let isFirstInFile = token.previousToken(viewMode: .sourceAccurate) == nil
    let matches = loneLineComments(in: token.leadingTrivia, isFirstToken: isFirstInFile)
      .compactMap(ruleStatusDirectiveMatch)
    let sourceRange = node.sourceRange(converter: sourceLocationConverter)
    for match in matches {
      switch match {
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
  private func ruleStatusDirectiveMatch(in text: String) -> RuleStatusDirectiveMatch? {
    let textRange = NSRange(text.startIndex..<text.endIndex, in: text)
    guard let match = ignoreRegex.firstMatch(in: text, options: [], range: textRange) else {
      return nil
    }
    guard match.numberOfRanges == 5 else { return .all }
    let matchRange = match.range(at: 3)
    guard matchRange.location != NSNotFound, let ruleNamesRange = Range(matchRange, in: text) else {
      return .all
    }
    let rules = text[ruleNamesRange].split(separator: ",")
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
