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

/// Use caseless `enum`s for namespacing.
///
/// In practice, this means that any `struct` that consists of only `static let`s and `static func`s
/// should be converted to an `enum`.
///
/// This is **not** a safe transformation for `class` types because the user might pass the metatype
/// as an `AnyClass` argument to an API, and changing the declaration to a non-`class` type breaks
/// that (see https://bugs.swift.org/browse/SR-11111).
///
/// Lint: `struct`s consisting of only `static let/func`s will yield a lint error.
///
/// Format: Rewrite the `struct` as an `enum`.
public final class UseEnumForNamespacing: SyntaxFormatRule {

  public override func visit(_ node: StructDeclSyntax) -> DeclSyntax {
    let rewrittenMembers = node.members.members.compactMap {
      super.visit($0).as(MemberDeclListItemSyntax.self)
    }
    guard rewrittenMembers.count == node.members.members.count else {
      // No members should be deleted - exit early instead of breaking the source.
      return DeclSyntax(node)
    }
    let rewrittenMemberDeclList = SyntaxFactory.makeMemberDeclList(rewrittenMembers)
    guard node.genericParameterClause == nil, node.inheritanceClause == nil,
      let memberDecls = membersToKeepIfUsedAsNamespace(rewrittenMemberDeclList)
    else {
      return DeclSyntax(node.withMembers(node.members.withMembers(rewrittenMemberDeclList)))
    }

    diagnose(.convertToEnum(kind: "struct", name: node.identifier), on: node)

    let result = EnumDeclSyntax { builder in
      node.modifiers?.forEach { builder.addModifier($0) }
      builder.useEnumKeyword(node.structKeyword.withKind(.enumKeyword))
      builder.useIdentifier(node.identifier)
      builder.useMembers(node.members.withMembers(memberDecls))
    }
    return DeclSyntax(result)
  }

  /// Returns the list of members that should be retained if all of them satisfy conditions that
  /// make them effectively a namespace.
  ///
  /// If there is a non-static private initializer with no arguments, that does not count against
  /// possibly being a namespace, since the user probably added it to prevent instantiation.
  ///
  /// If any of the members causes the type to disqualify as a namespace, this method returns nil.
  private func membersToKeepIfUsedAsNamespace(_ members: MemberDeclListSyntax)
    -> MemberDeclListSyntax?
  {
    if members.count == 0 { return nil }
    var declList = [MemberDeclListItemSyntax]()

    for member in members {
      switch Syntax(member.decl).as(SyntaxEnum.self) {
      case .functionDecl(let decl):
        guard let modifiers = decl.modifiers, modifiers.has(modifier: "static") else { return nil }
        declList.append(member)

      case .variableDecl(let decl):
        guard let modifiers = decl.modifiers, modifiers.has(modifier: "static") else { return nil }
        declList.append(member)

      case .initializerDecl(let decl):
        guard let modifiers = decl.modifiers, modifiers.has(modifier: "private"),
          decl.parameters.parameterList.isEmpty
        else {
          return nil
        }
        // Do not append private initializer.

      case .ifConfigDecl(let decl):
        // Note that the child nodes have already been rewritten, so any nested structs that should
        // become enums have already been transformed.
        let membersToKeep: [MemberDeclListSyntax] =
          decl.clauses.compactMap {
            ($0.elements.as(MemberDeclListSyntax.self)).flatMap(membersToKeepIfUsedAsNamespace(_:))
          }

        if membersToKeep.count < decl.clauses.count {
          return nil
        } else {
          declList.append(member)
        }

      default:
        declList.append(member)
      }
    }

    return SyntaxFactory.makeMemberDeclList(declList)
  }
}

extension Diagnostic.Message {
  public static func convertToEnum(kind: String, name: TokenSyntax) -> Diagnostic.Message {
    return .init(.warning, "replace \(kind) '\(name.text)' with an enum when used as a namespace")
  }
}
