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

  /// Each rule has a list of ranges for which it is disabled.
  private var ruleMap: [String: [Range<Int>]] = [:]

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

  /// Check if a comment matches a disable/enable flag.
  private func getRule(regex: NSRegularExpression, text: String) -> String? {
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
    for token in node.tokens {
      guard let leadingtrivia = token.leadingTrivia else { continue }

      // Flags must be on lines by themselves: not at the end of an existing line.
      var firstPiece = true

      for piece in leadingtrivia {
        guard case .lineComment(let text) = piece else {
          firstPiece = false
          continue
        }
        guard !firstPiece else { continue }

        if let disableRule = getRule(regex: disableRegex, text: text) {
          guard !disableStart.keys.contains(disableRule) else { continue }
          guard let startLine = getLine(token) else { continue }
          disableStart[disableRule] = startLine
        }

        if let enableRule = getRule(regex: enableRegex, text: text) {
          guard let startLine = disableStart.removeValue(forKey: enableRule) else { continue }
          guard let endLine = getLine(token) else { continue }
          let exclusionRange = startLine..<endLine

          if ruleMap.keys.contains(enableRule) {
            ruleMap[enableRule]?.append(exclusionRange)
          } else {
            ruleMap[enableRule] = [exclusionRange]
          }
        }
        firstPiece = false
      }
    }
  }

  /// Return if the given rule is disabled on the provided line.
  public func isDisabled(_ rule: String, line: Int) -> Bool {
    guard let ranges = ruleMap[rule] else { return false }
    for range in ranges {
      if range.contains(line) { return true }
    }
    return false
  }
}
