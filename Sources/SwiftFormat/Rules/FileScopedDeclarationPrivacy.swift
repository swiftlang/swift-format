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

import SwiftSyntax

/// Declarations at file scope with effective private access should be consistently declared as
/// either `fileprivate` or `private`, determined by configuration.
///
/// Lint: If a file-scoped declaration has formal access opposite to the desired access level in the
///       formatter's configuration, a lint error is raised.
///
/// Format: File-scoped declarations that have formal access opposite to the desired access level in
///         the formatter's configuration will have their access level changed.
@_spi(Rules)
public final class FileScopedDeclarationPrivacy: SyntaxFormatRule {
  public override func visit(_ node: SourceFileSyntax) -> SourceFileSyntax {
    var result = node
    result.statements = rewrittenCodeBlockItems(node.statements)
    return result
  }

  /// Returns a list of code block items equivalent to the given list, but where any file-scoped
  /// declarations with effective private access have had their formal access level rewritten, if
  /// necessary, to be either `private` or `fileprivate`, as determined by the formatter
  /// configuration.
  ///
  /// - Parameter codeBlockItems: The list of code block items to rewrite.
  /// - Returns: A new `CodeBlockItemListSyntax` that has possibly been rewritten.
  private func rewrittenCodeBlockItems(
    _ codeBlockItems: CodeBlockItemListSyntax
  ) -> CodeBlockItemListSyntax {
    let newCodeBlockItems = codeBlockItems.map { codeBlockItem -> CodeBlockItemSyntax in
      switch codeBlockItem.item {
      case .decl(let decl):
        var result = codeBlockItem
        result.item = .decl(rewrittenDecl(decl))
        return result
      default:
        return codeBlockItem
      }
    }
    return CodeBlockItemListSyntax(newCodeBlockItems)
  }

  private func rewrittenDecl(_ decl: DeclSyntax) -> DeclSyntax {
    switch Syntax(decl).as(SyntaxEnum.self) {
    case .ifConfigDecl(let ifConfigDecl):
      // We need to look through `#if/#elseif/#else` blocks because the decls directly inside
      // them are still considered file-scope for our purposes.
      return DeclSyntax(rewrittenIfConfigDecl(ifConfigDecl))

    case .functionDecl(let functionDecl):
      return DeclSyntax(rewrittenDecl(functionDecl))

    case .variableDecl(let variableDecl):
      return DeclSyntax(rewrittenDecl(variableDecl))

    case .classDecl(let classDecl):
      return DeclSyntax(rewrittenDecl(classDecl))

    case .structDecl(let structDecl):
      return DeclSyntax(rewrittenDecl(structDecl))

    case .enumDecl(let enumDecl):
      return DeclSyntax(rewrittenDecl(enumDecl))

    case .protocolDecl(let protocolDecl):
      return DeclSyntax(rewrittenDecl(protocolDecl))

    case .typeAliasDecl(let typealiasDecl):
      return DeclSyntax(rewrittenDecl(typealiasDecl))

    default:
      return decl
    }
  }

  /// Returns a new `IfConfigDeclSyntax` equivalent to the given node, but where any file-scoped
  /// declarations with effective private access have had their formal access level rewritten, if
  /// necessary, to be either `private` or `fileprivate`, as determined by the formatter
  /// configuration.
  ///
  /// - Parameter ifConfigDecl: The `IfConfigDeclSyntax` to rewrite.
  /// - Returns: A new `IfConfigDeclSyntax` that has possibly been rewritten.
  private func rewrittenIfConfigDecl(_ ifConfigDecl: IfConfigDeclSyntax) -> IfConfigDeclSyntax {
    let newClauses = ifConfigDecl.clauses.map { clause -> IfConfigClauseSyntax in
      switch clause.elements {
      case .statements(let codeBlockItemList)?:
        var result = clause
        result.elements = .statements(rewrittenCodeBlockItems(codeBlockItemList))
        return result
      default:
        return clause
      }
    }

    var result = ifConfigDecl
    result.clauses = IfConfigClauseListSyntax(newClauses)
    return result
  }

  /// Returns a rewritten version of the given declaration if its modifier list contains `private`
  /// that contains `fileprivate` instead.
  ///
  /// If the modifier list is not inconsistent with the configured access level, the original
  /// declaration is returned unchanged.
  ///
  /// - Parameters:
  ///   - decl: The declaration to possibly rewrite.
  ///   - modifiers: The modifier list of the declaration (i.e., `decl.modifiers`).
  ///   - factory: A reference to the `decl`'s `withModifiers` instance method that is called to
  ///     rewrite the node if needed.
  /// - Returns: A new node if the modifiers were rewritten, or the original node if not.
  private func rewrittenDecl<DeclType: DeclSyntaxProtocol & WithModifiersSyntax>(
    _ decl: DeclType
  ) -> DeclType {
    let invalidAccess: Keyword
    let validAccess: Keyword
    let diagnostic: Finding.Message

    switch context.configuration.fileScopedDeclarationPrivacy.accessLevel {
    case .private:
      invalidAccess = .fileprivate
      validAccess = .private
      diagnostic = .replaceFileprivateWithPrivate
    case .fileprivate:
      invalidAccess = .private
      validAccess = .fileprivate
      diagnostic = .replacePrivateWithFileprivate
    }

    guard decl.modifiers.contains(anyOf: [invalidAccess]) else {
      return decl
    }

    let newModifiers = decl.modifiers.map { modifier -> DeclModifierSyntax in
      var modifier = modifier

      let name = modifier.name
      if case .keyword(invalidAccess) = name.tokenKind {
        diagnose(diagnostic, on: name)
        modifier.name.tokenKind = .keyword(validAccess)
      }
      return modifier
    }

    var result = decl
    result.modifiers = DeclModifierListSyntax(newModifiers)
    return result
  }
}

extension Finding.Message {
  fileprivate static let replacePrivateWithFileprivate: Finding.Message =
    "replace 'private' with 'fileprivate' on file-scoped declarations"

  fileprivate static let replaceFileprivateWithPrivate: Finding.Message =
    "replace 'fileprivate' with 'private' on file-scoped declarations"
}
