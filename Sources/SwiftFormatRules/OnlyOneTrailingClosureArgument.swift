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

/// Function calls should never mix normal closure arguments and trailing closures.
///
/// Lint: If a function call with a trailing closure also contains a non-trailing closure argument,
///       a lint error is raised.
public final class OnlyOneTrailingClosureArgument: SyntaxLintRule {

  public override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
    guard (node.argumentList.contains { $0.expression.is(ClosureExprSyntax.self) }) else {
      return .skipChildren
    }
    guard node.trailingClosure != nil else { return .skipChildren }
    diagnose(.removeTrailingClosure, on: node)
    return .skipChildren
  }
}

extension Finding.Message {
  public static let removeTrailingClosure: Finding.Message =
    "revise function call to avoid using both closure arguments and a trailing closure"
}
