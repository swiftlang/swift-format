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

import SwiftSyntax

/// Identifiers in declarations and patterns should not have leading underscores.
///
/// This is intended to avoid certain antipatterns; `self.member = member` should be preferred to
/// `member = _member` and the leading underscore should not be used to signal access level.
///
/// This rule intentionally checks only the parameter variable names of a function declaration, not
/// the parameter labels. It also only checks identifiers at the declaration site, not at usage
/// sites.
///
/// As an exception, a property whose name is a leading-underscore "backing" variable for another
/// property declared in the same type is allowed. For example, `_count` is permitted when a sibling
/// property named `count` exists, since the underscore is being used intentionally to name a backing
/// store rather than to signal access level.
///
/// Lint: Declaring an identifier with a leading underscore yields a lint error.
@_spi(Rules)
public final class NoLeadingUnderscores: SyntaxLintRule {

  /// Identifies this rule as being opt-in. While leading underscores aren't meant to be used in
  /// normal circumstances, there are situations where they can be used to hint which APIs should be
  /// avoided by general users. In particular when APIs must be exported publicly, but the author
  /// doesn't intend for arbitrary usage.
  public override class var isOptIn: Bool { return true }

  public override func visit(_ node: AssociatedTypeDeclSyntax) -> SyntaxVisitorContinueKind {
    diagnoseIfNameStartsWithUnderscore(node.name)
    return .visitChildren
  }

  public override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
    diagnoseIfNameStartsWithUnderscore(node.name)
    return .visitChildren
  }

  public override func visit(_ node: EnumCaseElementSyntax) -> SyntaxVisitorContinueKind {
    diagnoseIfNameStartsWithUnderscore(node.name)
    return .visitChildren
  }

  public override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
    diagnoseIfNameStartsWithUnderscore(node.name)
    return .visitChildren
  }

  public override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
    diagnoseIfNameStartsWithUnderscore(node.name)
    return .visitChildren
  }

  public override func visit(_ node: ClosureParameterSyntax) -> SyntaxVisitorContinueKind {
    // If both names are provided, we want to check `secondName`, which will be the parameter name
    // (in that case, `firstName` is the label). If only one name is present, then it is recorded in
    // `firstName`, and it is both the label and the parameter name.
    diagnoseIfNameStartsWithUnderscore(node.secondName ?? node.firstName)
    return .visitChildren
  }

  public override func visit(_ node: EnumCaseParameterSyntax) -> SyntaxVisitorContinueKind {
    // If both names are provided, we want to check `secondName`, which will be the parameter name
    // (in that case, `firstName` is the label). If only one name is present, then it is recorded in
    // `firstName`, and it is both the label and the parameter name.
    if let variableIdentifier = node.secondName ?? node.firstName {
      diagnoseIfNameStartsWithUnderscore(variableIdentifier)
    }
    return .visitChildren
  }

  public override func visit(_ node: FunctionParameterSyntax) -> SyntaxVisitorContinueKind {
    // If both names are provided, we want to check `secondName`, which will be the parameter name
    // (in that case, `firstName` is the label). If only one name is present, then it is recorded in
    // `firstName`, and it is both the label and the parameter name.
    diagnoseIfNameStartsWithUnderscore(node.secondName ?? node.firstName)
    return .visitChildren
  }

  public override func visit(_ node: GenericParameterSyntax) -> SyntaxVisitorContinueKind {
    diagnoseIfNameStartsWithUnderscore(node.name)
    return .visitChildren
  }

  public override func visit(_ node: IdentifierPatternSyntax) -> SyntaxVisitorContinueKind {
    // A property whose name backs another property declared in the same type (e.g. `_count` backing
    // a computed `count`) is a common, intentional pattern, so it's exempt from this rule.
    if !isBackingProperty(node) {
      diagnoseIfNameStartsWithUnderscore(node.identifier)
    }
    return .visitChildren
  }

  public override func visit(_ node: PrecedenceGroupDeclSyntax) -> SyntaxVisitorContinueKind {
    diagnoseIfNameStartsWithUnderscore(node.name)
    return .visitChildren
  }

  public override func visit(_ node: ProtocolDeclSyntax) -> SyntaxVisitorContinueKind {
    diagnoseIfNameStartsWithUnderscore(node.name)
    return .visitChildren
  }

  public override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
    diagnoseIfNameStartsWithUnderscore(node.name)
    return .visitChildren
  }

  public override func visit(_ node: TypeAliasDeclSyntax) -> SyntaxVisitorContinueKind {
    diagnoseIfNameStartsWithUnderscore(node.name)
    return .visitChildren
  }

  /// Checks the given token to determine if it begins with an underscore (but is not *just* an
  /// underscore, which is allowed), emitting a diagnostic if it does.
  ///
  /// - Parameter token: The token to check.
  private func diagnoseIfNameStartsWithUnderscore(_ token: TokenSyntax) {
    let text = token.text
    if text.count > 1 && text.first == "_" {
      diagnose(.doNotStartWithUnderscore(identifier: text), on: token)
    }
  }

  /// Returns whether `pattern` names a property with a leading underscore that "backs" another
  /// property declared in the same type.
  ///
  /// For example, in
  /// ```swift
  /// struct S {
  ///   private var _count: Int = 0
  ///   var count: Int { _count }
  /// }
  /// ```
  /// the name `_count` is permitted because a sibling property named `count` (the same name without
  /// the leading underscore) is declared in the same type. Using a leading underscore to name a
  /// backing store is a common and accepted pattern, so the rule doesn't flag it.
  ///
  /// Only properties that are direct members of a type (or extension) are considered; local
  /// variables and top-level bindings never qualify. The counterpart lookup is limited to the same
  /// member block, so a property declared in a separate extension is not matched.
  private func isBackingProperty(_ pattern: IdentifierPatternSyntax) -> Bool {
    let name = pattern.identifier.text
    guard name.count > 1, name.first == "_" else { return false }

    // The pattern must be the name of a property that is a direct member of a type:
    // IdentifierPattern <- PatternBinding <- PatternBindingList <- VariableDecl <- MemberBlockItem
    guard let binding = pattern.parent?.as(PatternBindingSyntax.self),
      let bindingList = binding.parent?.as(PatternBindingListSyntax.self),
      let variableDecl = bindingList.parent?.as(VariableDeclSyntax.self),
      let enclosingBlock = enclosingMemberBlock(of: variableDecl)
    else {
      return false
    }

    return propertyExists(named: String(name.dropFirst()), in: enclosingBlock)
  }

  /// Returns the member block of the type that directly contains `decl`, or `nil` if `decl` is not a
  /// direct member of a type (for example, if it's a local variable or a top-level binding).
  private func enclosingMemberBlock(of decl: VariableDeclSyntax) -> MemberBlockSyntax? {
    guard let item = decl.parent?.as(MemberBlockItemSyntax.self),
      let itemList = item.parent?.as(MemberBlockItemListSyntax.self),
      let memberBlock = itemList.parent?.as(MemberBlockSyntax.self)
    else {
      return nil
    }
    return memberBlock
  }

  /// Returns whether any property declared directly in `memberBlock` has the given `name`.
  private func propertyExists(named name: String, in memberBlock: MemberBlockSyntax) -> Bool {
    for member in memberBlock.members {
      guard let variableDecl = member.decl.as(VariableDeclSyntax.self) else { continue }
      for binding in variableDecl.bindings {
        if let identifierPattern = binding.pattern.as(IdentifierPatternSyntax.self),
          identifierPattern.identifier.text == name
        {
          return true
        }
      }
    }
    return false
  }
}

extension Finding.Message {
  fileprivate static func doNotStartWithUnderscore(identifier: String) -> Finding.Message {
    "remove the leading '_' from the name '\(identifier)'"
  }
}
