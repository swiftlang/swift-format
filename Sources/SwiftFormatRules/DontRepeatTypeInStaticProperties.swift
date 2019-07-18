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

/// Static properties of a type that return that type should not include a reference to their type.
///
/// "Reference to their type" means that the property name includes part, or all, of the type. If
/// the type contains a namespace (i.e. `UIColor`) the namespace is ignored;
/// `public class var redColor: UIColor` would trigger this rule.
///
/// Lint: Static properties of a type that return that type will yield a lint error.
///
/// - SeeAlso: https://google.github.io/swift#static-and-class-properties
public struct DontRepeatTypeInStaticProperties: SyntaxLintRule {

  public let context: Context

  public init(context: Context) {
    self.context = context
  }

  public func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
    determinePropertyNameViolations(members: node.members.members, nodeId: node.identifier.text)
    return .skipChildren
  }

  public func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
    determinePropertyNameViolations(members: node.members.members, nodeId: node.identifier.text)
    return .skipChildren
  }

  public func visit(_ node: ProtocolDeclSyntax) -> SyntaxVisitorContinueKind {
    determinePropertyNameViolations(members: node.members.members, nodeId: node.identifier.text)
    return .skipChildren
  }

  public func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
    determinePropertyNameViolations(members: node.members.members, nodeId: node.identifier.text)
    return .skipChildren
  }

  public func visit(_ node: ExtensionDeclSyntax) -> SyntaxVisitorContinueKind {
    determinePropertyNameViolations(
      members: node.members.members,
      nodeId: node.extendedType.description)
    return .skipChildren
  }

  func determinePropertyNameViolations(members: MemberDeclListSyntax, nodeId: String) {
    for member in members {
      guard let decl = member.decl as? VariableDeclSyntax else { continue }
      guard let modifiers = decl.modifiers else { continue }
      guard modifiers.has(modifier: "static") || modifiers.has(modifier: "class") else { continue }

      let typeName = withoutPrefix(name: nodeId)

      for id in decl.identifiers {
        let varName = id.identifier.text
        guard varName.contains(typeName) else { continue }
        diagnose(.removeTypeFromName(name: varName, type: typeName), on: decl)
      }
    }
  }

  // Returns the given string without capitalized prefix in the beginning
  func withoutPrefix(name: String) -> String {
    let formattedName = name.trimmingCharacters(in: CharacterSet.whitespaces)
    let upperCase = Array(formattedName.uppercased())
    let original = Array(formattedName)
    guard original[0] == upperCase[0] else { return name }

    var prefixEndsAt = 0
    var idx = 0
    while idx <= name.count - 2 {
      if original[idx] == upperCase[idx] && original[idx + 1] != upperCase[idx + 1] {
        prefixEndsAt = idx
      }
      idx += 1
    }
    return String(formattedName.dropFirst(prefixEndsAt))
  }
}

extension Diagnostic.Message {
  static func removeTypeFromName(name: String, type: String) -> Diagnostic.Message {
    return .init(.warning, "remove '\(type)' from '\(name)'")
  }
}
