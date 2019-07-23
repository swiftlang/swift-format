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
///
/// - SeeAlso: https://google.github.io/swift#nesting-and-namespacing
public final class UseEnumForNamespacing: SyntaxFormatRule {

  public override func visit(_ node: StructDeclSyntax) -> DeclSyntax {
    guard node.genericParameterClause == nil, node.inheritanceClause == nil,
      let memberDecls = membersToKeepIfUsedAsNamespace(node.members.members)
    else {
      return node
    }

    diagnose(.convertToEnum(kind: "struct", name: node.identifier), on: node)

    return EnumDeclSyntax { builder in
      node.modifiers?.forEach { builder.addModifier($0) }
      builder.useEnumKeyword(node.structKeyword.withKind(.enumKeyword))
      builder.useIdentifier(node.identifier)
      builder.useMembers(node.members.withMembers(memberDecls))
    }
  }

  /// Returns the list of members that should be retained if all of them satisfy conditions that
  /// make them effectively a namespace.
  ///
  /// If there is a non-static private initializer with no arguments, that does not count against
  /// possibly being a namespace, since the user probably added it to prevent instantiation.
  ///
  /// If any of the members causes the type to disqualify as a namespace, this method returns nil.
  func membersToKeepIfUsedAsNamespace(_ members: MemberDeclListSyntax) -> MemberDeclListSyntax? {
    if members.count == 0 { return nil }
    var declList = [MemberDeclListItemSyntax]()

    for member in members {
      switch member.decl {
      case let decl as FunctionDeclSyntax:
        guard let modifiers = decl.modifiers, modifiers.has(modifier: "static") else { return nil }
        declList.append(member)

      case let decl as VariableDeclSyntax:
        guard let modifiers = decl.modifiers, modifiers.has(modifier: "static") else { return nil }
        declList.append(member)

      case let decl as InitializerDeclSyntax:
        guard let modifiers = decl.modifiers, modifiers.has(modifier: "private"),
          decl.parameters.parameterList.isEmpty
        else {
          return nil
        }
        // Do not append private initializer.

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
