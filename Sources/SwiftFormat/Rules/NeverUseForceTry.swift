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

/// Force-try (`try!`) is forbidden.
///
/// This rule does not apply to test code, defined as code which:
///   * Contains the line `import XCTest`
///   * The function is marked with `@Test` attribute
///
/// Lint: Using `try!` results in a lint error.
///
/// TODO: Create exception for NSRegularExpression
@_spi(Rules)
public final class NeverUseForceTry: SyntaxLintRule {

  /// Identifies this rule as being opt-in. While force try is an unsafe pattern (i.e. it can
  /// crash), there are valid contexts for force try where it won't crash. This rule can't
  /// evaluate the context around the force try to make that determination.
  public override class var isOptIn: Bool { return true }

  public override func visit(_ node: SourceFileSyntax) -> SyntaxVisitorContinueKind {
    setImportsXCTest(context: context, sourceFile: node)
    return .visitChildren
  }

  public override func visit(_ node: TryExprSyntax) -> SyntaxVisitorContinueKind {
    guard context.importsXCTest == .doesNotImportXCTest else { return .skipChildren }
    guard let mark = node.questionOrExclamationMark else { return .visitChildren }
    // Allow force try if it is in a function marked with @Test attribute.
    if node.hasTestAncestor { return .skipChildren }
    if mark.tokenKind == .exclamationMark {
      diagnose(.doNotForceTry, on: node.tryKeyword)
    }
    return .visitChildren
  }
}

extension Finding.Message {
  fileprivate static let doNotForceTry: Finding.Message = "do not use force try"
}
