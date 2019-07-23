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

/// A rule that both formats and lints a given file.
open class SyntaxFormatRule: SyntaxRewriter, Rule {
  /// The context in which the rule is executed.
  public let context: Context

  /// Creates a new SyntaxFormatRule in the given context.
  public required init(context: Context) {
    self.context = context
  }

  open override func visitAny(_ node: Syntax) -> Syntax? {
    // If the rule is not enabled, then return the node unmodified; otherwise, returning nil tells
    // SwiftSyntax to continue with the standard dispatch.
    guard context.isRuleEnabled(Self.ruleName, node: node) else { return node }
    return nil
  }
}
