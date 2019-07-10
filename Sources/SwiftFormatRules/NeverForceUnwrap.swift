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

/// Force-unwraps are strongly discouraged and must be documented.
///
/// Lint: If a force unwrap is used, a lint warning is raised.
///       TODO(abl): consider having documentation (e.g. a comment) cancel the warning?
///
/// - SeeAlso: https://google.github.io/swift#force-unwrapping-and-force-casts
public struct NeverForceUnwrap: SyntaxLintRule {

  public let context: Context

  public init(context: Context) {
    self.context = context
  }

  public func visit(_ node: SourceFileSyntax) -> SyntaxVisitorContinueKind {
    // Tracks whether "XCTest" is imported in the source file before processing the individual
    setImportsXCTest(context: context, sourceFile: node)
    return .visitChildren
  }

  public func visit(_ node: ForcedValueExprSyntax) -> SyntaxVisitorContinueKind {
    guard !context.importsXCTest else { return .skipChildren }
    diagnose(.doNotForceUnwrap(name: node.expression.description), on: node)
    return .skipChildren
  }

  public func visit(_ node: AsExprSyntax) -> SyntaxVisitorContinueKind {
    // Only fire if we're not in a test file and if there is an exclamation mark following the `as`
    // keyword.
    guard !context.importsXCTest else { return .skipChildren }
    guard let questionOrExclamation = node.questionOrExclamationMark else { return .skipChildren }
    guard questionOrExclamation.tokenKind == .exclamationMark else { return .skipChildren }
    diagnose(.doNotForceCast(name: node.typeName.description), on: node)
    return .skipChildren
  }
}

extension Diagnostic.Message {
  static func doNotForceUnwrap(name: String) -> Diagnostic.Message {
    return .init(.warning, "do not force unwrap '\(name)'")
  }

  static func doNotForceCast(name: String) -> Diagnostic.Message {
    return .init(.warning, "do not force cast to '\(name)'")
  }
}
