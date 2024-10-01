//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2023 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import SwiftSyntax

/// Replace `forEach` with `for-in` loop unless its argument is a function reference.
///
/// Lint:  invalid use of `forEach` yield will yield a lint error.
@_spi(Rules)
public final class ReplaceForEachWithForLoop: SyntaxLintRule {
  public override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
    // We are only interested in calls with a single trailing closure
    // argument.
    if !node.arguments.isEmpty || node.trailingClosure == nil || !node.additionalTrailingClosures.isEmpty {
      return .visitChildren
    }

    guard let member = node.calledExpression.as(MemberAccessExprSyntax.self) else {
      return .visitChildren
    }

    let memberName = member.declName.baseName
    guard memberName.text == "forEach" else {
      return .visitChildren
    }

    // If there is another chained member after `.forEach`,
    // let's skip the diagnostic because resulting code might
    // be less understandable.
    if node.parent?.is(MemberAccessExprSyntax.self) == true {
      return .visitChildren
    }

    diagnose(.replaceForEachWithLoop(), on: memberName)
    return .visitChildren
  }
}

extension Finding.Message {
  fileprivate static func replaceForEachWithLoop() -> Finding.Message {
    "replace use of '.forEach { ... }' with for-in loop"
  }
}
