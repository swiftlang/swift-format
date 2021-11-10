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
public final class NeverForceUnwrap: SyntaxLintRule {

  /// Identifies this rule as being opt-in. While force unwrap is an unsafe pattern (i.e. it can
  /// crash), there are valid contexts for force unwrap where it won't crash. This rule can't
  /// evaluate the context around the force unwrap to make that determination.
  public override class var isOptIn: Bool { return true }

  public override func visit(_ node: SourceFileSyntax) -> SyntaxVisitorContinueKind {
    // Tracks whether "XCTest" is imported in the source file before processing individual nodes.
    setImportsXCTest(context: context, sourceFile: node)
    return .visitChildren
  }

  public override func visit(_ node: ForcedValueExprSyntax) -> SyntaxVisitorContinueKind {
    guard context.importsXCTest == .doesNotImportXCTest else { return .skipChildren }
    diagnose(.doNotForceUnwrap(name: node.expression.withoutTrivia().description), on: node)
    return .skipChildren
  }

  public override func visit(_ node: AsExprSyntax) -> SyntaxVisitorContinueKind {
    // Only fire if we're not in a test file and if there is an exclamation mark following the `as`
    // keyword.
    guard context.importsXCTest == .doesNotImportXCTest else { return .skipChildren }
    guard let questionOrExclamation = node.questionOrExclamationMark else { return .skipChildren }
    guard questionOrExclamation.tokenKind == .exclamationMark else { return .skipChildren }
    diagnose(.doNotForceCast(name: node.typeName.withoutTrivia().description), on: node)
    return .skipChildren
  }
}

extension Finding.Message {
  public static func doNotForceUnwrap(name: String) -> Finding.Message {
    "do not force unwrap '\(name)'"
  }

  public static func doNotForceCast(name: String) -> Finding.Message {
    "do not force cast to '\(name)'"
  }
}
