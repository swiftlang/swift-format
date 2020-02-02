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
    guard let modifiers = node.modifiers else {
      let nodeWithModifier = node.addModifier(modifierKeyword)
      let result = nodeByRelocatingTrivia(in: nodeWithModifier) { $0.modifiers }
      return DeclSyntax(result)
    }
    // If variable already has an accessor keyword, skip (do not overwrite)
    guard modifiers.accessLevelModifier == nil else { return DeclSyntax(node) }

    // Put accessor keyword before the first modifier keyword in the declaration
    let newModifiers = modifiers.prepend(modifier: modifierKeyword)
    return DeclSyntax(node.withModifiers(newModifiers))
  }

  override func visit(_ node: FunctionDeclSyntax) -> DeclSyntax {
    // Check for modifiers, and, if none, insert the modifier and relocate trivia from the displaced
    // token.
    guard let modifiers = node.modifiers else {
      let nodeWithModifier = node.addModifier(modifierKeyword)
      let result = nodeByRelocatingTrivia(in: nodeWithModifier) { $0.modifiers }
      return DeclSyntax(result)
    }
    guard modifiers.accessLevelModifier == nil else { return DeclSyntax(node) }
    let newModifiers = modifiers.prepend(modifier: modifierKeyword)
    return DeclSyntax(node.withModifiers(newModifiers))
  }

  override func visit(_ node: AssociatedtypeDeclSyntax) -> DeclSyntax {
    // Check for modifiers, and, if none, insert the modifier and relocate trivia from the displaced
    // token.
    guard let modifiers = node.modifiers else {
      let nodeWithModifier = node.addModifier(modifierKeyword)
      let result = nodeByRelocatingTrivia(in: nodeWithModifier) { $0.modifiers }
      return DeclSyntax(result)
    }
    guard modifiers.accessLevelModifier == nil else { return DeclSyntax(node) }
    let newModifiers = modifiers.prepend(modifier: modifierKeyword)
    return DeclSyntax(node.withModifiers(newModifiers))
  }

  override func visit(_ node: ClassDeclSyntax) -> DeclSyntax {
    // Check for modifiers, and, if none, insert the modifier and relocate trivia from the displaced
    // token.
    guard let modifiers = node.modifiers else {
      let nodeWithModifier = node.addModifier(modifierKeyword)
      let result = nodeByRelocatingTrivia(in: nodeWithModifier) { $0.modifiers }
      return DeclSyntax(result)
    }
    guard modifiers.accessLevelModifier == nil else { return DeclSyntax(node) }
    let newModifiers = modifiers.prepend(modifier: modifierKeyword)
    return DeclSyntax(node.withModifiers(newModifiers))
  }

  override func visit(_ node: EnumDeclSyntax) -> DeclSyntax {
    // Check for modifiers, and, if none, insert the modifier and relocate trivia from the displaced
    // token.
    guard let modifiers = node.modifiers else {
      let nodeWithModifier = node.addModifier(modifierKeyword)
      let result = nodeByRelocatingTrivia(in: nodeWithModifier) { $0.modifiers }
      return DeclSyntax(result)
    }
    guard modifiers.accessLevelModifier == nil else { return DeclSyntax(node) }
    let newModifiers = modifiers.prepend(modifier: modifierKeyword)
    return DeclSyntax(node.withModifiers(newModifiers))
  }

  override func visit(_ node: ProtocolDeclSyntax) -> DeclSyntax {
    // Check for modifiers, and, if none, insert the modifier and relocate trivia from the displaced
    // token.
    guard let modifiers = node.modifiers else {
      let nodeWithModifier = node.addModifier(modifierKeyword)
      let result = nodeByRelocatingTrivia(in: nodeWithModifier) { $0.modifiers }
      return DeclSyntax(result)
    }
    guard modifiers.accessLevelModifier == nil else { return DeclSyntax(node) }
    let newModifiers = modifiers.prepend(modifier: modifierKeyword)
    return DeclSyntax(node.withModifiers(newModifiers))
  }

  override func visit(_ node: StructDeclSyntax) -> DeclSyntax {
    // Check for modifiers, and, if none, insert the modifier and relocate trivia from the displaced
    // token.
    guard let modifiers = node.modifiers else {
      let nodeWithModifier = node.addModifier(modifierKeyword)
      let result = nodeByRelocatingTrivia(in: nodeWithModifier) { $0.modifiers }
      return DeclSyntax(result)
    }
    guard modifiers.accessLevelModifier == nil else { return DeclSyntax(node) }
    let newModifiers = modifiers.prepend(modifier: modifierKeyword)
    return DeclSyntax(node.withModifiers(newModifiers))
  }

  override func visit(_ node: TypealiasDeclSyntax) -> DeclSyntax {
    // Check for modifiers, and, if none, insert the modifier and relocate trivia from the displaced
    // token.
    guard let modifiers = node.modifiers else {
      let nodeWithModifier = node.addModifier(modifierKeyword)
      let result = nodeByRelocatingTrivia(in: nodeWithModifier) { $0.modifiers }
      return DeclSyntax(result)
    }
    guard modifiers.accessLevelModifier == nil else { return DeclSyntax(node) }
    let newModifiers = modifiers.prepend(modifier: modifierKeyword)
    return DeclSyntax(node.withModifiers(newModifiers))
  }

  override func visit(_ node: InitializerDeclSyntax) -> DeclSyntax {
    // Check for modifiers, and, if none, insert the modifier and relocate trivia from the displaced
    // token.
    guard let modifiers = node.modifiers else {
      let nodeWithModifier = node.addModifier(modifierKeyword)
      let result = nodeByRelocatingTrivia(in: nodeWithModifier) { $0.modifiers }
      return DeclSyntax(result)
    }
    guard modifiers.accessLevelModifier == nil else { return DeclSyntax(node) }
    let newModifiers = modifiers.prepend(modifier: modifierKeyword)
    return DeclSyntax(node.withModifiers(newModifiers))
  }

  override func visit(_ node: SubscriptDeclSyntax) -> DeclSyntax {
    // Check for modifiers, and, if none, insert the modifier and relocate trivia from the displaced
    // token.
    guard let modifiers = node.modifiers else {
      let nodeWithModifier = node.addModifier(modifierKeyword)
      let result = nodeByRelocatingTrivia(in: nodeWithModifier) { $0.modifiers }
      return DeclSyntax(result)
    }
    guard modifiers.accessLevelModifier == nil else { return DeclSyntax(node) }
    let newModifiers = modifiers.prepend(modifier: modifierKeyword)
    return DeclSyntax(node.withModifiers(newModifiers))
  }

  /// Moves trivia in the given node to correct the placement of potentially displaced trivia in the
  /// node after the first modifier was added to the given node. The added modifier is assumed to be
  /// the first and only modifier of the node. After the first modifier is added to a node, any
  /// leading trivia on the token immediately after the modifier is considered displaced. This
  /// method moves that displaced trivia onto the new modifier. When there is no displaced trivia,
  /// this method does nothing and returns the given node as-is.
  /// - Parameter node: A node that was updated to include a new modifier.
  /// - Parameter modifiersProvider: A closure that returns all modifiers for the given node.
  private func nodeByRelocatingTrivia<NodeType: DeclSyntaxProtocol>(
    in node: NodeType,
    for modifiersProvider: (NodeType) -> ModifierListSyntax?
  ) -> NodeType {
    guard let modifier = modifiersProvider(node)?.firstAndOnly,
      let movingLeadingTrivia = modifier.nextToken?.leadingTrivia
    else {
      // Otherwise, there's no trivia that needs to be relocated so the node is fine.
      return node
    }
    let nodeWithTrivia = replaceTrivia(
      on: node,
      token: modifier.firstToken,
      leadingTrivia: movingLeadingTrivia)
    return replaceTrivia(
      on: nodeWithTrivia,
      token: modifiersProvider(nodeWithTrivia)?.first?.nextToken,
      leadingTrivia: [])
  }
}

func addModifier(
  declaration: DeclSyntax,
  modifierKeyword: DeclModifierSyntax
) -> Syntax {
  return AddModifierRewriter(modifierKeyword: modifierKeyword).visit(Syntax(declaration))
}
