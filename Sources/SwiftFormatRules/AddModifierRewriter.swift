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

fileprivate final class AddModifierRewriter: SyntaxRewriter {
  private let modifierKeyword: DeclModifierSyntax

  init(modifierKeyword: DeclModifierSyntax) {
    self.modifierKeyword = modifierKeyword
  }

  override func visit(_ node: VariableDeclSyntax) -> DeclSyntax {
    // Check for modifiers, and, if none, insert the modifier and relocate trivia from the displaced
    // token.
    guard !node.modifiers.isEmpty else {
      let result = setOnlyModifier(in: node, keywordKeypath: \.bindingSpecifier)
      return DeclSyntax(result)
    }
    var node = node

    // If variable already has an accessor keyword, skip (do not overwrite)
    guard node.modifiers.accessLevelModifier == nil else { return DeclSyntax(node) }

    // Put accessor keyword before the first modifier keyword in the declaration
    node.modifiers.triviaPreservingInsert(modifierKeyword, at: node.modifiers.startIndex)
    return DeclSyntax(node)
  }

  override func visit(_ node: FunctionDeclSyntax) -> DeclSyntax {
    // Check for modifiers, and, if none, insert the modifier and relocate trivia from the displaced
    // token.
    guard !node.modifiers.isEmpty else {
      let result = setOnlyModifier(in: node, keywordKeypath: \.funcKeyword)
      return DeclSyntax(result)
    }
    guard node.modifiers.accessLevelModifier == nil else { return DeclSyntax(node) }
    var node = node
    node.modifiers.triviaPreservingInsert(modifierKeyword, at: node.modifiers.startIndex)
    return DeclSyntax(node)
  }

  override func visit(_ node: AssociatedTypeDeclSyntax) -> DeclSyntax {
    // Check for modifiers, and, if none, insert the modifier and relocate trivia from the displaced
    // token.
    guard !node.modifiers.isEmpty else {
      let result = setOnlyModifier(in: node, keywordKeypath: \.associatedtypeKeyword)
      return DeclSyntax(result)
    }
    guard node.modifiers.accessLevelModifier == nil else { return DeclSyntax(node) }
    var node = node
    node.modifiers.triviaPreservingInsert(modifierKeyword, at: node.modifiers.startIndex)
    return DeclSyntax(node)
  }

  override func visit(_ node: ClassDeclSyntax) -> DeclSyntax {
    // Check for modifiers, and, if none, insert the modifier and relocate trivia from the displaced
    // token.
    guard !node.modifiers.isEmpty else {
      let result = setOnlyModifier(in: node, keywordKeypath: \.classKeyword)
      return DeclSyntax(result)
    }
    guard node.modifiers.accessLevelModifier == nil else { return DeclSyntax(node) }
    var node = node
    node.modifiers.triviaPreservingInsert(modifierKeyword, at: node.modifiers.startIndex)
    return DeclSyntax(node)
  }

  override func visit(_ node: EnumDeclSyntax) -> DeclSyntax {
    // Check for modifiers, and, if none, insert the modifier and relocate trivia from the displaced
    // token.
    guard !node.modifiers.isEmpty else {
      let result = setOnlyModifier(in: node, keywordKeypath: \.enumKeyword)
      return DeclSyntax(result)
    }
    guard node.modifiers.accessLevelModifier == nil else { return DeclSyntax(node) }
    var node = node
    node.modifiers.triviaPreservingInsert(modifierKeyword, at: node.modifiers.startIndex)
    return DeclSyntax(node)
  }

  override func visit(_ node: ProtocolDeclSyntax) -> DeclSyntax {
    // Check for modifiers, and, if none, insert the modifier and relocate trivia from the displaced
    // token.

    guard !node.modifiers.isEmpty else {
      let result = setOnlyModifier(in: node, keywordKeypath: \.protocolKeyword)
      return DeclSyntax(result)
    }
    guard node.modifiers.accessLevelModifier == nil else { return DeclSyntax(node) }
    var node = node
    node.modifiers.triviaPreservingInsert(modifierKeyword, at: node.modifiers.startIndex)
    return DeclSyntax(node)
  }

  override func visit(_ node: StructDeclSyntax) -> DeclSyntax {
    // Check for modifiers, and, if none, insert the modifier and relocate trivia from the displaced
    // token.
    guard !node.modifiers.isEmpty else {
      let result = setOnlyModifier(in: node, keywordKeypath: \.structKeyword)
      return DeclSyntax(result)
    }
    guard node.modifiers.accessLevelModifier == nil else { return DeclSyntax(node) }
    var node = node
    node.modifiers.triviaPreservingInsert(modifierKeyword, at: node.modifiers.startIndex)
    return DeclSyntax(node)
  }

  override func visit(_ node: TypeAliasDeclSyntax) -> DeclSyntax {
    // Check for modifiers, and, if none, insert the modifier and relocate trivia from the displaced
    // token.
    guard !node.modifiers.isEmpty else {
      let result = setOnlyModifier(in: node, keywordKeypath: \.typealiasKeyword)
      return DeclSyntax(result)
    }
    guard node.modifiers.accessLevelModifier == nil else { return DeclSyntax(node) }
    var node = node
    node.modifiers.triviaPreservingInsert(modifierKeyword, at: node.modifiers.startIndex)
    return DeclSyntax(node)
  }

  override func visit(_ node: InitializerDeclSyntax) -> DeclSyntax {
    // Check for modifiers, and, if none, insert the modifier and relocate trivia from the displaced
    // token.
    guard !node.modifiers.isEmpty else {
      let result = setOnlyModifier(in: node, keywordKeypath: \.initKeyword)
      return DeclSyntax(result)
    }
    guard node.modifiers.accessLevelModifier == nil else { return DeclSyntax(node) }
    var node = node
    node.modifiers.triviaPreservingInsert(modifierKeyword, at: node.modifiers.startIndex)
    return DeclSyntax(node)
  }

  override func visit(_ node: SubscriptDeclSyntax) -> DeclSyntax {
    // Check for modifiers, and, if none, insert the modifier and relocate trivia from the displaced
    // token.
    guard !node.modifiers.isEmpty else {
      let result = setOnlyModifier(in: node, keywordKeypath: \.subscriptKeyword)
      return DeclSyntax(result)
    }
    guard node.modifiers.accessLevelModifier == nil else { return DeclSyntax(node) }
    var node = node
    node.modifiers.triviaPreservingInsert(modifierKeyword, at: node.modifiers.startIndex)
    return DeclSyntax(node)
  }

  /// Moves trivia in the given node to correct the placement of potentially displaced trivia in the
  /// node after the first modifier was added to the given node. The added modifier is assumed to be
  /// the first and only modifier of the node. After the first modifier is added to a node, any
  /// leading trivia on the token immediately after the modifier is considered displaced. This
  /// method moves that displaced trivia onto the new modifier. When there is no displaced trivia,
  /// this method does nothing and returns the given node as-is.
  /// - Parameter node: A node that was updated to include a new modifier.
  /// - Parameter modifiersProvider: A closure that returns all modifiers for the given node.
  private func setOnlyModifier<NodeType: DeclSyntaxProtocol & WithModifiersSyntax>(
    in node: NodeType,
    keywordKeypath: WritableKeyPath<NodeType, TokenSyntax>
  ) -> NodeType {
    var node = node
    var modifier = modifierKeyword
    modifier.leadingTrivia = node[keyPath: keywordKeypath].leadingTrivia
    node[keyPath: keywordKeypath].leadingTrivia = []
    node.modifiers = .init([modifier])
    return node
  }
}

func addModifier(
  declaration: DeclSyntax,
  modifierKeyword: DeclModifierSyntax
) -> Syntax {
  return AddModifierRewriter(modifierKeyword: modifierKeyword).rewrite(Syntax(declaration))
}
