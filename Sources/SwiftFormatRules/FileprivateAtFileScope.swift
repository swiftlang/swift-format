//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2020 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import SwiftFormatCore
import SwiftSyntax

/// Declarations at file scope should be declared `fileprivate`, not `private`.
///
/// Using `private` at file scope actually gives the declaration `fileprivate` visibility, so using
/// `fileprivate` explicitly is a better indicator of intent.
///
/// Lint: If a file-scoped declaration has `private` visibility, a lint error is raised.
///
/// Format: File-scoped declarations that have `private` visibility will have their visibility
///         changed to `fileprivate`.
public final class FileprivateAtFileScope: SyntaxFormatRule {
  public override func visit(_ node: SourceFileSyntax) -> Syntax {
    let newStatements = rewrittenCodeBlockItems(node.statements)
    return Syntax(node.withStatements(newStatements))
  }

  /// Returns a list of code block items equivalent to the given list, but where any file-scoped
  /// declarations have had their `private` modifier replaced by `fileprivate` if present.
  ///
  /// - Parameter codeBlockItems: The list of code block items to rewrite.
  /// - Returns: A new `CodeBlockItemListSyntax` that has possibly been rewritten.
  private func rewrittenCodeBlockItems(_ codeBlockItems: CodeBlockItemListSyntax)
    -> CodeBlockItemListSyntax
  {
    let newCodeBlockItems = codeBlockItems.map { codeBlockItem -> CodeBlockItemSyntax in
      switch codeBlockItem.item.as(SyntaxEnum.self) {
      case .ifConfigDecl(let ifConfigDecl):
        // We need to look through `#if/#elseif/#else` blocks because the decls directly inside
        // them are still considered file-scope for our purposes.
        return codeBlockItem.withItem(Syntax(rewrittenIfConfigDecl(ifConfigDecl)))

      case .functionDecl(let functionDecl):
        return codeBlockItem.withItem(
          Syntax(rewrittenDecl(
            functionDecl,
            modifiers: functionDecl.modifiers,
            factory: functionDecl.withModifiers)))

      case .variableDecl(let variableDecl):
        return codeBlockItem.withItem(
          Syntax(rewrittenDecl(
            variableDecl,
            modifiers: variableDecl.modifiers,
            factory: variableDecl.withModifiers)))

      case .classDecl(let classDecl):
        return codeBlockItem.withItem(
          Syntax(rewrittenDecl(
            classDecl,
            modifiers: classDecl.modifiers,
            factory: classDecl.withModifiers)))

      case .structDecl(let structDecl):
        return codeBlockItem.withItem(
          Syntax(rewrittenDecl(
            structDecl,
            modifiers: structDecl.modifiers,
            factory: structDecl.withModifiers)))

      case .enumDecl(let enumDecl):
        return codeBlockItem.withItem(
          Syntax(rewrittenDecl(
            enumDecl,
            modifiers: enumDecl.modifiers,
            factory: enumDecl.withModifiers)))

      case .protocolDecl(let protocolDecl):
        return codeBlockItem.withItem(
          Syntax(rewrittenDecl(
            protocolDecl,
            modifiers: protocolDecl.modifiers,
            factory: protocolDecl.withModifiers)))

      case .typealiasDecl(let typealiasDecl):
        return codeBlockItem.withItem(
          Syntax(rewrittenDecl(
            typealiasDecl,
            modifiers: typealiasDecl.modifiers,
            factory: typealiasDecl.withModifiers)))

      case .extensionDecl(let extensionDecl):
        return codeBlockItem.withItem(
          Syntax(rewrittenDecl(
            extensionDecl,
            modifiers: extensionDecl.modifiers,
            factory: extensionDecl.withModifiers)))

      default:
        return codeBlockItem
      }
    }
    return SyntaxFactory.makeCodeBlockItemList(newCodeBlockItems)
  }

  /// Returns a new `IfConfigDeclSyntax` equivalent to the given node, but where any file-scoped
  /// declarations have had their `private` modifier replaced by `fileprivate` if present.
  ///
  /// - Parameter ifConfigDecl: The `IfConfigDeclSyntax` to rewrite.
  /// - Returns: A new `IfConfigDeclSyntax` that has possibly been rewritten.
  private func rewrittenIfConfigDecl(_ ifConfigDecl: IfConfigDeclSyntax) -> IfConfigDeclSyntax {
    let newClauses = ifConfigDecl.clauses.map { clause -> IfConfigClauseSyntax in
      switch clause.elements.as(SyntaxEnum.self) {
      case .codeBlockItemList(let codeBlockItemList):
        return clause.withElements(Syntax(rewrittenCodeBlockItems(codeBlockItemList)))
      default:
        return clause
      }
    }
    return ifConfigDecl.withClauses(SyntaxFactory.makeIfConfigClauseList(newClauses))
  }

  /// Returns a rewritten version of the given declaration if its modifier list contains `private`
  /// that contains `fileprivate` instead.
  ///
  /// If the modifier list does not contain `private`, the original declaration is returned
  /// unchanged.
  ///
  /// - Parameters:
  ///   - decl: The declaration to possibly rewrite.
  ///   - modifiers: The modifier list of the declaration (i.e., `decl.modifiers`).
  ///   - factory: A reference to the `decl`'s `withModifiers` instance method that is called to
  ///     rewrite the node if needed.
  /// - Returns: A new node if the modifiers were rewritten, or the original node if not.
  private func rewrittenDecl<DeclType: DeclSyntaxProtocol>(
    _ decl: DeclType,
    modifiers: ModifierListSyntax?,
    factory: (ModifierListSyntax?) -> DeclType
  ) -> DeclType {
    guard let modifiers = modifiers, modifiers.has(modifier: "private") else {
      return decl
    }

    let newModifiers = modifiers.map { modifier -> DeclModifierSyntax in
      let name = modifier.name
      if name.tokenKind == .privateKeyword {
        diagnose(.replacePrivateWithFileprivate, on: name)
        return modifier.withName(name.withKind(.fileprivateKeyword))
      }
      return modifier
    }
    return factory(SyntaxFactory.makeModifierList(newModifiers))
  }
}

extension Diagnostic.Message {
  public static let replacePrivateWithFileprivate =
    Diagnostic.Message(.warning, "replace 'private' with 'fileprivate' on file-scoped declarations")
}
