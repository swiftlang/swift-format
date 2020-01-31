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

import Foundation
import SwiftFormatCore
import SwiftSyntax

/// All public or open declarations must have a top-level documentation comment.
///
/// Lint: If a public declaration is missing a documentation comment, a lint error is raised.
public final class AllPublicDeclarationsHaveDocumentation: SyntaxLintRule {

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
    diagnoseMissingDocComment(DeclSyntax(node), name: node.identifier.text, modifiers: node.modifiers)
    return .skipChildren
  }

  public override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
    guard let mainBinding = node.bindings.firstAndOnly else { return .skipChildren }
    diagnoseMissingDocComment(DeclSyntax(node), name: "\(mainBinding.pattern)", modifiers: node.modifiers)
    return .skipChildren
  }

  public override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
    diagnoseMissingDocComment(DeclSyntax(node), name: node.identifier.text, modifiers: node.modifiers)
    return .skipChildren
  }

  public override func visit(_ node: ProtocolDeclSyntax) -> SyntaxVisitorContinueKind {
    diagnoseMissingDocComment(DeclSyntax(node), name: node.identifier.text, modifiers: node.modifiers)
    return .skipChildren
  }

  public override func visit(_ node: TypealiasDeclSyntax) -> SyntaxVisitorContinueKind {
    diagnoseMissingDocComment(DeclSyntax(node), name: node.identifier.text, modifiers: node.modifiers)
    return .skipChildren
  }

  func diagnoseMissingDocComment(
    _ decl: DeclSyntax,
    name: String,
    modifiers: ModifierListSyntax?
  ) {
    guard decl.docComment == nil else { return }
    guard let mods = modifiers,
      mods.has(modifier: "public"),
      !mods.has(modifier: "override")
    else {
      return
    }

    diagnose(.declRequiresComment(name), on: decl)
  }
}

extension Diagnostic.Message {
  static func declRequiresComment(_ name: String) -> Diagnostic.Message {
    return .init(.warning, "add a documentation comment for '\(name)'")
  }
}
