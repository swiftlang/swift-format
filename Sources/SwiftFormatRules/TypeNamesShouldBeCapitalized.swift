//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2023 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import SwiftFormatCore
import SwiftSyntax

/// `struct`, `class`, `enum` and `protocol` declarations should have a capitalized name.
///
/// Lint:  Types with un-capitalized names will yield a lint error.
public final class TypeNamesShouldBeCapitalized : SyntaxLintRule {
  public override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
    diagnoseNameConventionMismatch(node, name: node.name)
    return .visitChildren
  }

  public override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
    diagnoseNameConventionMismatch(node, name: node.name)
    return .visitChildren
  }

  public override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
    diagnoseNameConventionMismatch(node, name: node.name)
    return .visitChildren
  }

  public override func visit(_ node: ProtocolDeclSyntax) -> SyntaxVisitorContinueKind {
    diagnoseNameConventionMismatch(node, name: node.name)
    return .visitChildren
  }

  public override func visit(_ node: ActorDeclSyntax) -> SyntaxVisitorContinueKind {
    diagnoseNameConventionMismatch(node, name: node.name)
    return .visitChildren
  }

  public override func visit(_ node: AssociatedTypeDeclSyntax) -> SyntaxVisitorContinueKind {
    diagnoseNameConventionMismatch(node, name: node.name)
    return .visitChildren
  }

  public override func visit(_ node: TypeAliasDeclSyntax) -> SyntaxVisitorContinueKind {
    diagnoseNameConventionMismatch(node, name: node.name)
    return .visitChildren
  }

  private func diagnoseNameConventionMismatch<T: DeclSyntaxProtocol>(_ type: T, name: TokenSyntax) {
    if let firstChar = name.text.first, !firstChar.isUppercase {
      diagnose(.capitalizeTypeName(name: name.text), on: type, severity: .convention)
    }
  }
}

extension Finding.Message {
  public static func capitalizeTypeName(name: String) -> Finding.Message {
    let capitalized = name.prefix(1).uppercased() + name.dropFirst()
    return "type names should be capitalized: \(name) -> \(capitalized)"
  }
}
