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

/// This class takes the raw source text and scans through it searching for comment pairs of the
/// form:
///
///   3. |  // swift-format-disable: RuleName
///   4. |  let a = 123
///   5. |  // swift-format-enable: RuleName
///
/// This class records that `RuleName` is disabled for line 4. The rules themselves reference
/// RuleMask to see if it is disabled for the line it is currently examining.
public class RuleMask {

  /// Information about whether a particular lint/format rule is enabled or disabled for a range of
  /// lines in the source file.
  private struct LineRangeState {

    /// The line range where a rule is either disabled or enabled.
    var range: Range<Int>

    /// Indicates whether the rule is enabled in this range.
    var isEnabled: Bool
  }

  /// Each rule has a list of ranges for which it is explicitly enabled or disabled.
  private var ruleMap: [String: [LineRangeState]] = [:]

  /// Regex to match the enable comments; rule name is in the first capture group.
  private let enablePattern = #"^\s*//\s*swift-format-enable:\s+(\S+)"#

  /// Regex to match the disable comments; rule name is in the first capture group.
  private let disablePattern = #"^\s*//\s*swift-format-disable:\s+(\S+)"#

  /// Rule enable regex object.
  private let enableRegex: NSRegularExpression

  /// Rule disable regex object.
  private let disableRegex: NSRegularExpression

  /// Used to compute line numbers of syntax nodes.
  private let sourceLocationConverter: SourceLocationConverter

  /// This takes the head Syntax node of the source and generates a map of the rules specified for
  /// disable/enable and the line ranges for which they are disabled.
  public init(syntaxNode: Syntax, sourceLocationConverter: SourceLocationConverter) {
    enableRegex = try! NSRegularExpression(pattern: enablePattern, options: [])
    disableRegex = try! NSRegularExpression(pattern: disablePattern, options: [])

    self.sourceLocationConverter = sourceLocationConverter
    generateDictionary(syntaxNode)
  }

  /// Calculate the starting line number of a syntax node.
  private func getLine(_ node: Syntax) -> Int? {
    let loc = node.startLocation(converter: self.sourceLocationConverter)
    return loc.line
  }

  /// Check if a comment matches a disable/enable flag, and if so, returns the name of the rule.
  private func getRule(regex: NSRegularExpression, text: String) -> String? {
    // TODO: Support multiple rules in the same comment; e.g., a comma-delimited list.
    let nsrange = NSRange(text.startIndex..<text.endIndex, in: text)
    if let match = regex.firstMatch(in: text, options: [], range: nsrange) {
      let matchRange = match.range(at: 1)
      if matchRange.location != NSNotFound, let range = Range(matchRange, in: text) {
        return String(text[range])
      }
    }
    return nil
  }

  /// Generate the dictionary (ruleMap) by walking the syntax tokens.
  private func generateDictionary(_ node: Syntax) {
    var disableStart: [String: Int] = [:]
    var enableStart: [String: Int] = [:]

    for token in node.tokens {
      guard let leadingTrivia = token.leadingTrivia else { continue }

      // Flags must be on lines by themselves: not at the end of an existing line.
      var firstPiece = true

      for piece in leadingTrivia {
        guard case .lineComment(let text) = piece else {
          firstPiece = false
          continue
        }
        guard !firstPiece else { continue }

        if let ruleName = getRule(regex: disableRegex, text: text) {
          guard !disableStart.keys.contains(ruleName) else { continue }
          guard let disableStartLine = getLine(token) else { continue }

          if let enableStartLine = enableStart[ruleName] {
            // If we're processing an enable block for the rule, finalize it.
            ruleMap[ruleName, default: []].append(
              LineRangeState(range: enableStartLine..<disableStartLine, isEnabled: true))
            enableStart[ruleName] = nil
          }

          disableStart[ruleName] = disableStartLine
        }
        else if let ruleName = getRule(regex: enableRegex, text: text) {
          guard !enableStart.keys.contains(ruleName) else { continue }
          guard let enableStartLine = getLine(token) else { continue }

          if let disableStartLine = disableStart[ruleName] {
            // If we're processing a disable block for the rule, finalize it.
            ruleMap[ruleName, default: []].append(
              LineRangeState(range: disableStartLine..<enableStartLine, isEnabled: false))
            disableStart[ruleName] = nil
          }

          enableStart[ruleName] = enableStartLine
        }

        firstPiece = false
      }
    }

    // Finalize any remaining blocks by closing them off at the last line number in the file.
    guard let lastToken = node.lastToken, let lastLine = getLine(lastToken) else { return }

    for (ruleName, disableStartLine) in disableStart {
      ruleMap[ruleName, default: []].append(
        LineRangeState(range: disableStartLine..<lastLine + 1, isEnabled: false))
    }
    for (ruleName, enableStartLine) in enableStart {
      ruleMap[ruleName, default: []].append(
        LineRangeState(range: enableStartLine..<lastLine + 1, isEnabled: true))
    }
  }

  /// Return if the given rule is disabled on the provided line.
  public func ruleState(_ rule: String, atLine line: Int) -> RuleState {
    guard let rangeStates = ruleMap[rule] else { return .default }
    for rangeState in rangeStates {
      if rangeState.range.contains(line) {
        return rangeState.isEnabled ? .enabled : .disabled
      }
    }
    return .default
  }
}
