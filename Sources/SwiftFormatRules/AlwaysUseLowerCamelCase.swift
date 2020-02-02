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

/// All values should be written in lower camel-case (`lowerCamelCase`).
/// Underscores (except at the beginning of an identifier) are disallowed.
///
/// Lint: If an identifier contains underscores or begins with a capital letter, a lint error is
///       raised.
public final class AlwaysUseLowerCamelCase: SyntaxLintRule {

  public override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
    for binding in node.bindings {
      guard let pat = binding.pattern.as(IdentifierPatternSyntax.self) else {
        continue
      }
      diagnoseLowerCamelCaseViolations(pat.identifier)
    }
    return .skipChildren
  }

  public override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
    diagnoseLowerCamelCaseViolations(node.identifier)
    return .skipChildren
  }

  public override func visit(_ node: EnumCaseElementSyntax) -> SyntaxVisitorContinueKind {
    diagnoseLowerCamelCaseViolations(node.identifier)
    return .skipChildren
  }

  private func diagnoseLowerCamelCaseViolations(_ identifier: TokenSyntax) {
    guard case .identifier(let text) = identifier.tokenKind else { return }
    if text.isEmpty { return }
    if text.dropFirst().contains("_") || ("A"..."Z").contains(text.first!) {
      diagnose(.variableNameMustBeLowerCamelCase(text), on: identifier) {
        $0.highlight(identifier.sourceRange(converter: self.context.sourceLocationConverter))
      }
    }
  }
}

extension Diagnostic.Message {
  public static func variableNameMustBeLowerCamelCase(_ name: String) -> Diagnostic.Message {
    return .init(.warning, "rename variable '\(name)' using lower-camel-case")
  }
}
