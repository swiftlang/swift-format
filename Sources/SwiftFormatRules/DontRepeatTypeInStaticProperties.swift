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

/// Static properties of a type that return that type should not include a reference to their type.
///
/// "Reference to their type" means that the property name includes part, or all, of the type. If
/// the type contains a namespace (i.e. `UIColor`) the namespace is ignored;
/// `public class var redColor: UIColor` would trigger this rule.
///
/// Lint: Static properties of a type that return that type will yield a lint error.
public final class DontRepeatTypeInStaticProperties: SyntaxLintRule {

  public override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
    diagnoseStaticMembers(node.members.members, endingWith: node.identifier.text)
    return .skipChildren
  }

  public override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
    diagnoseStaticMembers(node.members.members, endingWith: node.identifier.text)
    return .skipChildren
  }

  public override func visit(_ node: ProtocolDeclSyntax) -> SyntaxVisitorContinueKind {
    diagnoseStaticMembers(node.members.members, endingWith: node.identifier.text)
    return .skipChildren
  }

  public override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
    diagnoseStaticMembers(node.members.members, endingWith: node.identifier.text)
    return .skipChildren
  }

  public override func visit(_ node: ExtensionDeclSyntax) -> SyntaxVisitorContinueKind {
    let members = node.members.members

    switch Syntax(node.extendedType).as(SyntaxEnum.self) {
    case .simpleTypeIdentifier(let simpleType):
      diagnoseStaticMembers(members, endingWith: simpleType.name.text)
    case .memberTypeIdentifier(let memberType):
      // We don't need to drill recursively into this structure because types with more than two
      // components are constructed left-heavy; that is, `A.B.C.D` is structured as `((A.B).C).D`,
      // and the final component of the top type is what we want.
      diagnoseStaticMembers(members, endingWith: memberType.name.text)
    default:
      // Do nothing for non-nominal types. If Swift adds support for extensions on non-nominals,
      // we'll need to update this if we need to support some subset of those.
      break
    }

    return .skipChildren
  }

  /// Iterates over the static/class properties in the given member list and diagnoses any where the
  /// name has the containing type name (excluding possible namespace prefixes, like `NS` or `UI`)
  /// as a suffix.
  private func diagnoseStaticMembers(_ members: MemberDeclListSyntax, endingWith typeName: String) {
    for member in members {
      guard
        let varDecl = member.decl.as(VariableDeclSyntax.self),
        let modifiers = varDecl.modifiers,
        modifiers.has(modifier: "static") || modifiers.has(modifier: "class")
      else { continue }

      let bareTypeName = removingPossibleNamespacePrefix(from: typeName)

      for pattern in varDecl.identifiers {
        let varName = pattern.identifier.text
        if varName.contains(bareTypeName) {
          diagnose(.removeTypeFromName(name: varName, type: bareTypeName), on: varDecl)
        }
      }
    }
  }

  /// Returns the portion of the given string that excludes a possible Objective-C-style capitalized
  /// namespace prefix (a leading sequence of more than one uppercase letter).
  ///
  /// If the name has zero or one leading uppercase letters, the entire name is returned.
  private func removingPossibleNamespacePrefix(from name: String) -> Substring {
    guard let first = name.first, first.isUppercase else { return name[...] }

    for index in name.indices.dropLast() {
      let nextIndex = name.index(after: index)
      if name[index].isUppercase && !name[nextIndex].isUppercase {
        return name[index...]
      }
    }

    return name[...]
  }
}

extension Finding.Message {
  public static func removeTypeFromName(name: String, type: Substring) -> Finding.Message {
    "remove '\(type)' from '\(name)'"
  }
}
