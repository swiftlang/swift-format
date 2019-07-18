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

/// Use caseless `enum`s for namespacing.
///
/// In practice, this means that any `class` or `struct` that consists of only `static let`s and
/// `static func`s should be converted to an `enum`.
///
/// Lint: `class`es or `struct`s consisting of only `static let/func`s will yield a lint error.
///
/// Format: Rewrite the `class` or `struct` as an `enum`.
///         TODO(abl): This can get complicated to pattern-match correctly.
// .        TODO(b/78286392): Give this formatting pass a category that makes it not run on save.
///
/// - SeeAlso: https://google.github.io/swift#nesting-and-namespacing
public final class UseEnumForNamespacing: SyntaxFormatRule {
  public override func visit(_ node: StructDeclSyntax) -> DeclSyntax {
    guard let newDecls = declsIfUsedAsNamespace(node.members.members),
      node.genericParameterClause == nil,
      node.inheritanceClause == nil
    else {
      return node
    }

    diagnose(.convertToEnum(kind: "struct", name: node.identifier), on: node)

    return makeEnum(
      declarationKeyword: node.structKeyword,
      modifiers: node.modifiers,
      name: node.identifier,
      members: node.members.withMembers(newDecls)
    )
  }

  public override func visit(_ node: ClassDeclSyntax) -> DeclSyntax {
    guard let newDecls = declsIfUsedAsNamespace(node.members.members),
      node.genericParameterClause == nil,
      node.inheritanceClause == nil
    else {
      return node
    }

    diagnose(.convertToEnum(kind: "class", name: node.identifier), on: node)

    return makeEnum(
      declarationKeyword: node.classKeyword,
      modifiers: node.modifiers,
      name: node.identifier,
      members: node.members.withMembers(newDecls)
    )
  }

  func makeEnum(
    declarationKeyword: TokenSyntax,
    modifiers: ModifierListSyntax?,
    name: TokenSyntax,
    members: MemberDeclBlockSyntax
  ) -> EnumDeclSyntax {
    // Since we remove the "final" modifier, we need to preserve its trivia if it is the first
    // modifier.
    var newLeadingTrivia: Trivia? = nil
    if let firstMod = modifiers?.first, firstMod.name.text == "final" {
      newLeadingTrivia = firstMod.leadingTrivia
    }

    let newModifiers = modifiers?.remove(name: "final")

    let outputEnum = EnumDeclSyntax {
      if let mods = newModifiers {
        for mod in mods { $0.addModifier(mod) }
      }
      $0.useEnumKeyword(declarationKeyword.withKind(.enumKeyword))
      $0.useIdentifier(name)
      $0.useMembers(members)
    }

    if let trivia = newLeadingTrivia {
      return replaceTrivia(
        on: outputEnum,
        token: outputEnum.firstToken,
        leadingTrivia: trivia
      ) as! EnumDeclSyntax
    } else {
      return outputEnum
    }
  }

  /// Determines if the set of declarations is consistent with a class or struct being used
  /// solely as a namespace for static functions. If there is a non-static private initializer
  /// with no arguments, that does not count against possibly being a namespace.
  func declsIfUsedAsNamespace(_ members: MemberDeclListSyntax) -> MemberDeclListSyntax? {
    if members.count == 0 { return nil }
    var declList = [MemberDeclListItemSyntax]()
    for member in members {
      switch member.decl {
      case let decl as FunctionDeclSyntax:
        guard let modifiers = decl.modifiers,
          modifiers.has(modifier: "static")
        else {
          return nil
        }
        declList.append(member)
      case let decl as VariableDeclSyntax:
        guard let modifiers = decl.modifiers,
          modifiers.has(modifier: "static")
        else {
          return nil
        }
        declList.append(member)
      case let decl as InitializerDeclSyntax:
        guard let modifiers = decl.modifiers,
          modifiers.has(modifier: "private"),
          decl.parameters.parameterList.count == 0
        else {
          return nil
        }
      // Do not append private initializer
      default:
        declList.append(member)
      }
    }
    return SyntaxFactory.makeMemberDeclList(declList)
  }
}

extension Diagnostic.Message {
  static func convertToEnum(kind: String, name: TokenSyntax) -> Diagnostic.Message {
    return .init(
      .warning,
      "\(kind) '\(name.text)' used as a namespace should be an enum"
    )
  }
}
