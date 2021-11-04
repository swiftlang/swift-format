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

/// Identifiers in declarations and patterns should not have leading underscores.
///
/// This is intended to avoid certain antipatterns; `self.member = member` should be preferred to
/// `member = _member` and the leading underscore should not be used to signal access level.
///
/// This rule intentionally checks only the parameter variable names of a function declaration, not
/// the parameter labels. It also only checks identifiers at the declaration site, not at usage
/// sites.
///
/// Lint: Declaring an identifier with a leading underscore yields a lint error.
public final class NoLeadingUnderscores: SyntaxLintRule {

  /// Identifies this rule as being opt-in. While leading underscores aren't meant to be used in
  /// normal circumstances, there are situations where they can be used to hint which APIs should be
  /// avoided by general users. In particular when APIs must be exported publicly, but the author
  /// doesn't intend for arbitrary usage.
  public override class var isOptIn: Bool { return true }

  public override func visit(_ node: AssociatedtypeDeclSyntax) -> SyntaxVisitorContinueKind {
    diagnoseIfNameStartsWithUnderscore(node.identifier)
    return .visitChildren
  }

  public override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
    diagnoseIfNameStartsWithUnderscore(node.identifier)
    return .visitChildren
  }

  public override func visit(_ node: EnumCaseElementSyntax) -> SyntaxVisitorContinueKind {
    diagnoseIfNameStartsWithUnderscore(node.identifier)
    return .visitChildren
  }

  public override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
    diagnoseIfNameStartsWithUnderscore(node.identifier)
    return .visitChildren
  }

  public override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
    diagnoseIfNameStartsWithUnderscore(node.identifier)
    return .visitChildren
  }

  public override func visit(_ node: FunctionParameterSyntax) -> SyntaxVisitorContinueKind {
    // If both names are provided, we want to check `secondName`, which will be the parameter name
    // (in that case, `firstName` is the label). If only one name is present, then it is recorded in
    // `firstName`, and it is both the label and the parameter name.
    if let variableIdentifier = node.secondName ?? node.firstName {
      diagnoseIfNameStartsWithUnderscore(variableIdentifier)
    }
    return .visitChildren
  }

  public override func visit(_ node: GenericParameterSyntax) -> SyntaxVisitorContinueKind {
    diagnoseIfNameStartsWithUnderscore(node.name)
    return .visitChildren
  }

  public override func visit(_ node: IdentifierPatternSyntax) -> SyntaxVisitorContinueKind {
    diagnoseIfNameStartsWithUnderscore(node.identifier)
    return .visitChildren
  }

  public override func visit(_ node: PrecedenceGroupDeclSyntax) -> SyntaxVisitorContinueKind {
    diagnoseIfNameStartsWithUnderscore(node.identifier)
    return .visitChildren
  }

  public override func visit(_ node: ProtocolDeclSyntax) -> SyntaxVisitorContinueKind {
    diagnoseIfNameStartsWithUnderscore(node.identifier)
    return .visitChildren
  }

  public override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
    diagnoseIfNameStartsWithUnderscore(node.identifier)
    return .visitChildren
  }

  public override func visit(_ node: TypealiasDeclSyntax) -> SyntaxVisitorContinueKind {
    diagnoseIfNameStartsWithUnderscore(node.identifier)
    return .visitChildren
  }

  /// Checks the given token to determine if it begins with an underscore (but is not *just* an
  /// underscore, which is allowed), emitting a diagnostic if it does.
  ///
  /// - Parameter token: The token to check.
  private func diagnoseIfNameStartsWithUnderscore(_ token: TokenSyntax) {
    let text = token.text
    if text.count > 1 && text.first == "_" {
      diagnose(.doNotStartWithUnderscore(identifier: text), on: token)
    }
  }
}

extension Finding.Message {
  public static func doNotStartWithUnderscore(identifier: String) -> Finding.Message {
    "remove leading '_' from identifier '\(identifier)'"
  }
}
