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

/// All public or open declarations must have a top-level documentation comment.
///
/// Lint: If a public declaration is missing a documentation comment, a lint error is raised.
@_spi(Rules)
public final class AllPublicDeclarationsHaveDocumentation: SyntaxLintRule {

  /// Identifies this rule as being opt-in. While docs on most public declarations are beneficial,
  /// there are a number of public decls where docs are either redundant or superfluous. This rule
  /// can't differentiate those situations and will make a lot of noise for projects that are
  /// intentionally avoiding docs on some decls.
  public override class var isOptIn: Bool { return true }

  public override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
    diagnoseMissingDocComment(DeclSyntax(node), name: node.fullDeclName, modifiers: node.modifiers)
    return .skipChildren
  }

  public override func visit(_ node: InitializerDeclSyntax) -> SyntaxVisitorContinueKind {
    diagnoseMissingDocComment(DeclSyntax(node), name: "init", modifiers: node.modifiers)
    return .skipChildren
  }

  public override func visit(_ node: DeinitializerDeclSyntax) -> SyntaxVisitorContinueKind {
    diagnoseMissingDocComment(DeclSyntax(node), name: "deinit", modifiers: node.modifiers)
    return .skipChildren
  }

  public override func visit(_ node: SubscriptDeclSyntax) -> SyntaxVisitorContinueKind {
    diagnoseMissingDocComment(DeclSyntax(node), name: "subscript", modifiers: node.modifiers)
    return .skipChildren
  }

  public override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
    diagnoseMissingDocComment(DeclSyntax(node), name: node.name.text, modifiers: node.modifiers)
    return .visitChildren
  }

  public override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
    guard let mainBinding = node.bindings.firstAndOnly else { return .skipChildren }
    diagnoseMissingDocComment(DeclSyntax(node), name: "\(mainBinding.pattern)", modifiers: node.modifiers)
    return .skipChildren
  }

  public override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
    diagnoseMissingDocComment(DeclSyntax(node), name: node.name.text, modifiers: node.modifiers)
    return .visitChildren
  }

  public override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
    diagnoseMissingDocComment(DeclSyntax(node), name: node.name.text, modifiers: node.modifiers)
    return .visitChildren
  }

  public override func visit(_ node: ActorDeclSyntax) -> SyntaxVisitorContinueKind {
    diagnoseMissingDocComment(DeclSyntax(node), name: node.name.text, modifiers: node.modifiers)
    return .visitChildren
  }

  public override func visit(_ node: ProtocolDeclSyntax) -> SyntaxVisitorContinueKind {
    diagnoseMissingDocComment(DeclSyntax(node), name: node.name.text, modifiers: node.modifiers)
    return .skipChildren
  }

  public override func visit(_ node: TypeAliasDeclSyntax) -> SyntaxVisitorContinueKind {
    diagnoseMissingDocComment(DeclSyntax(node), name: node.name.text, modifiers: node.modifiers)
    return .skipChildren
  }

  private func diagnoseMissingDocComment(
    _ decl: DeclSyntax,
    name: String,
    modifiers: DeclModifierListSyntax
  ) {
    guard
      DocumentationCommentText(extractedFrom: decl.leadingTrivia) == nil,
      modifiers.contains(anyOf: [.public]),
      !modifiers.contains(anyOf: [.override])
    else {
      return
    }

    diagnose(.declRequiresComment(name), on: decl)
  }
}

extension Finding.Message {
  fileprivate static func declRequiresComment(_ name: String) -> Finding.Message {
    "add a documentation comment for '\(name)'"
  }
}
