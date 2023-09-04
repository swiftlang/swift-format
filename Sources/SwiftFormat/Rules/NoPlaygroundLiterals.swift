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

/// The playground literals (`#colorLiteral`, `#fileLiteral`, and `#imageLiteral`) are forbidden.
///
/// Lint: Using a playground literal will yield a lint error with a suggestion of an API to replace
/// it.
@_spi(Rules)
public final class NoPlaygroundLiterals: SyntaxLintRule {
  override public func visit(_ node: MacroExpansionExprSyntax) -> SyntaxVisitorContinueKind {
    switch node.macroName.text {
    case "colorLiteral":
      diagnosedColorLiteralMacroExpansion(node)
    case "fileLiteral":
      diagnosedFileLiteralMacroExpansion(node)
    case "imageLiteral":
      diagnosedImageLiteralMacroExpansion(node)
    default:
      break
    }
    return .visitChildren
  }

  private func diagnosedColorLiteralMacroExpansion(_ node: MacroExpansionExprSyntax) {
    guard isLiteralMacroCall(node, matchingLabels: ["red", "green", "blue", "alpha"]) else {
      return
    }
    diagnose(.replaceColorLiteral, on: node)
  }

  private func diagnosedFileLiteralMacroExpansion(_ node: MacroExpansionExprSyntax) {
    guard isLiteralMacroCall(node, matchingLabels: ["resourceName"]) else {
      return
    }
    diagnose(.replaceFileLiteral, on: node)
  }

  private func diagnosedImageLiteralMacroExpansion(_ node: MacroExpansionExprSyntax) {
    guard isLiteralMacroCall(node, matchingLabels: ["resourceName"]) else {
      return
    }
    diagnose(.replaceImageLiteral, on: node)
  }

  /// Returns true if the given macro expansion is a correctly constructed call with the given
  /// argument labels and has no trailing closures or generic arguments.
  private func isLiteralMacroCall(
    _ node: MacroExpansionExprSyntax,
    matchingLabels labels: [String]
  ) -> Bool {
    guard
      node.genericArgumentClause == nil,
      node.trailingClosure == nil,
      node.additionalTrailingClosures.isEmpty,
      node.arguments.count == labels.count
    else {
      return false
    }

    for (actual, expected) in zip(node.arguments, labels) {
      guard actual.label?.text == expected else { return false }
    }
    return true
  }
}

extension Finding.Message {
  fileprivate static let replaceColorLiteral: Finding.Message =
    "replace '#colorLiteral' with a call to an initializer on 'NSColor' or 'UIColor'"

  fileprivate static let replaceFileLiteral: Finding.Message =
    "replace '#fileLiteral' with a call to a method such as 'Bundle.url(forResource:withExtension:)'"

  fileprivate static let replaceImageLiteral: Finding.Message =
    "replace '#imageLiteral' with a call to an initializer on 'NSImage' or 'UIImage'"
}
