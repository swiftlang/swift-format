//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2024 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import SwiftSyntax

/// `@retroactive` conformances are forbidden.
///
/// Lint: Using `@retroactive` results in a lint error.
@_spi(Rules)
public final class AvoidRetroactiveConformances: SyntaxLintRule {
  public override func visit(_ node: ExtensionDeclSyntax) -> SyntaxVisitorContinueKind {
    if let inheritanceClause = node.inheritanceClause {
      walk(inheritanceClause)
    }
    return .skipChildren
  }
  public override func visit(_ type: AttributeSyntax) -> SyntaxVisitorContinueKind {
    if let identifier = type.attributeName.as(IdentifierTypeSyntax.self) {
      if identifier.name.text == "retroactive" {
        diagnose(.doNotUseRetroactive, on: type)
      }
    }
    return .skipChildren
  }
}

extension Finding.Message {
  fileprivate static let doNotUseRetroactive: Finding.Message = "do not declare retroactive conformances"
}
