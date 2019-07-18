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

private final class AddModifierRewriter: SyntaxRewriter {
  let modifierKeyword: DeclModifierSyntax

  init(modifierKeyword: DeclModifierSyntax) {
    self.modifierKeyword = modifierKeyword
  }

  override func visit(_ node: VariableDeclSyntax) -> DeclSyntax {
    // Check for modifiers, if none, put accessor keyword before the first token
    guard let modifiers = node.modifiers else {
      guard
        let newDecl = removeFirstTokLeadingTrivia(node: node)
        as? VariableDeclSyntax
      else { return node }
      return newDecl.addModifier(modifierKeyword)
    }
    // If variable already has an accessor keyword, skip (do not overwrite)
    guard modifiers.accessLevelModifier == nil else { return node }

    // Put accessor keyword before the first modifier keyword in the declaration
    let newModifiers = modifiers.prepend(modifier: modifierKeyword)
    return node.withModifiers(newModifiers)
  }

  override func visit(_ node: FunctionDeclSyntax) -> DeclSyntax {
    guard let modifiers = node.modifiers else {
      guard
        let newDecl = removeFirstTokLeadingTrivia(node: node)
        as? FunctionDeclSyntax
      else { return node }
      return newDecl.addModifier(modifierKeyword)
    }
    guard modifiers.accessLevelModifier == nil else { return node }
    let newModifiers = modifiers.prepend(modifier: modifierKeyword)
    return node.withModifiers(newModifiers)
  }

  override func visit(_ node: AssociatedtypeDeclSyntax) -> DeclSyntax {
    guard let modifiers = node.modifiers else {
      guard
        let newDecl = removeFirstTokLeadingTrivia(node: node)
        as? AssociatedtypeDeclSyntax
      else { return node }
      return newDecl.addModifier(modifierKeyword)
    }
    guard modifiers.accessLevelModifier == nil else { return node }
    let newModifiers = modifiers.prepend(modifier: modifierKeyword)
    return node.withModifiers(newModifiers)
  }

  override func visit(_ node: ClassDeclSyntax) -> DeclSyntax {
    guard let modifiers = node.modifiers else {
      guard
        let newDecl = removeFirstTokLeadingTrivia(node: node)
        as? ClassDeclSyntax
      else { return node }
      return newDecl.addModifier(modifierKeyword)
    }
    guard modifiers.accessLevelModifier == nil else { return node }
    let newModifiers = modifiers.prepend(modifier: modifierKeyword)
    return node.withModifiers(newModifiers)
  }

  override func visit(_ node: EnumDeclSyntax) -> DeclSyntax {
    guard let modifiers = node.modifiers else {
      guard
        let newDecl = removeFirstTokLeadingTrivia(node: node)
        as? EnumDeclSyntax
      else { return node }
      return newDecl.addModifier(modifierKeyword)
    }
    guard modifiers.accessLevelModifier == nil else { return node }
    let newModifiers = modifiers.prepend(modifier: modifierKeyword)
    return node.withModifiers(newModifiers)
  }

  override func visit(_ node: ProtocolDeclSyntax) -> DeclSyntax {
    guard let modifiers = node.modifiers else {
      guard
        let newDecl = removeFirstTokLeadingTrivia(node: node)
        as? ProtocolDeclSyntax
      else { return node }
      return newDecl.addModifier(modifierKeyword)
    }
    guard modifiers.accessLevelModifier == nil else { return node }
    let newModifiers = modifiers.prepend(modifier: modifierKeyword)
    return node.withModifiers(newModifiers)
  }

  override func visit(_ node: StructDeclSyntax) -> DeclSyntax {
    guard let modifiers = node.modifiers else {
      guard
        let newDecl = removeFirstTokLeadingTrivia(node: node)
        as? StructDeclSyntax
      else { return node }
      return newDecl.addModifier(modifierKeyword)
    }
    guard modifiers.accessLevelModifier == nil else { return node }
    let newModifiers = modifiers.prepend(modifier: modifierKeyword)
    return node.withModifiers(newModifiers)
  }

  override func visit(_ node: TypealiasDeclSyntax) -> DeclSyntax {
    guard let modifiers = node.modifiers else {
      guard
        let newDecl = removeFirstTokLeadingTrivia(node: node)
        as? TypealiasDeclSyntax
      else { return node }
      return newDecl.addModifier(modifierKeyword)
    }
    guard modifiers.accessLevelModifier == nil else { return node }
    let newModifiers = modifiers.prepend(modifier: modifierKeyword)
    return node.withModifiers(newModifiers)
  }

  override func visit(_ node: InitializerDeclSyntax) -> DeclSyntax {
    guard let modifiers = node.modifiers else {
      guard
        let newDecl = removeFirstTokLeadingTrivia(node: node)
        as? InitializerDeclSyntax
      else { return node }
      return newDecl.addModifier(modifierKeyword)
    }
    guard modifiers.accessLevelModifier == nil else { return node }
    let newModifiers = modifiers.prepend(modifier: modifierKeyword)
    return node.withModifiers(newModifiers)
  }

  func removeFirstTokLeadingTrivia(node: DeclSyntax) -> DeclSyntax {
    let withoutLeadTrivia = replaceTrivia(
      on: node,
      token: node.firstToken,
      leadingTrivia: []) as! DeclSyntax
    return withoutLeadTrivia
  }
}

func addModifier(
  declaration: DeclSyntax,
  modifierKeyword: DeclModifierSyntax
) -> Syntax {
  return AddModifierRewriter(modifierKeyword: modifierKeyword).visit(declaration)
}
