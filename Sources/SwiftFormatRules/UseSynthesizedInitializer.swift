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

/// When possible, the synthesized `struct` initializer should be used.
///
/// This means the creation of a (non-public) memberwise initializer with the same structure as the
/// synthesized initializer is forbidden.
///
/// Lint: (Non-public) memberwise initializers with the same structure as the synthesized
///       initializer will yield a lint error.
public final class UseSynthesizedInitializer: SyntaxLintRule {

  public override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
    var storedProperties: [VariableDeclSyntax] = []
    var initializers: [InitializerDeclSyntax] = []

    for memberItem in node.members.members {
      let member = memberItem.decl
      // Collect all stored variables into a list
      if let varDecl = member.as(VariableDeclSyntax.self) {
        guard let modifiers = varDecl.modifiers else {
          storedProperties.append(varDecl)
          continue
        }
        guard !modifiers.has(modifier: "static") else { continue }
        storedProperties.append(varDecl)
        // Collect any possible redundant initializers into a list
      } else if let initDecl = member.as(InitializerDeclSyntax.self) {
        guard initDecl.optionalMark == nil else { continue }
        guard initDecl.signature.effectSpecifiers?.throwsSpecifier == nil else { continue }
        initializers.append(initDecl)
      }
    }

    // Collects all of the initializers that could be replaced by the synthesized memberwise
    // initializer(s).
    var extraneousInitializers = [InitializerDeclSyntax]()
    for initializer in initializers {
      guard
        matchesPropertyList(
          parameters: initializer.signature.input.parameterList,
          properties: storedProperties)
      else { continue }
      guard
        matchesAssignmentBody(
          variables: storedProperties,
          initBody: initializer.body)
      else { continue }
      guard matchesAccessLevel(modifiers: initializer.modifiers, properties: storedProperties)
      else { continue }
      extraneousInitializers.append(initializer)
    }

    // The synthesized memberwise initializer(s) are only created when there are no initializers.
    // If there are other initializers that cannot be replaced by a synthesized memberwise
    // initializer, then all of the initializers must remain.
    let initializersCount = node.members.members.filter { $0.decl.is(InitializerDeclSyntax.self) }.count
    if extraneousInitializers.count == initializersCount {
      extraneousInitializers.forEach { diagnose(.removeRedundantInitializer, on: $0) }
    }

    return .skipChildren
  }

  /// Compares the actual access level of an initializer with the access level of a synthesized
  /// memberwise initializer.
  ///
  /// - Parameters:
  ///   - modifiers: The modifier list from the initializer.
  ///   - properties: The properties from the enclosing type.
  /// - Returns: Whether the initializer has the same access level as the synthesized initializer.
  private func matchesAccessLevel(
    modifiers: ModifierListSyntax?, properties: [VariableDeclSyntax]
  ) -> Bool {
    let synthesizedAccessLevel = synthesizedInitAccessLevel(using: properties)
    let accessLevel = modifiers?.accessLevelModifier
    switch synthesizedAccessLevel {
    case .internal:
      // No explicit access level or internal are equivalent.
      return accessLevel == nil || accessLevel!.name.tokenKind == .keyword(.internal)
    case .fileprivate:
      return accessLevel != nil && accessLevel!.name.tokenKind == .keyword(.fileprivate)
    case .private:
      return accessLevel != nil && accessLevel!.name.tokenKind == .keyword(.private)
    }
  }

  // Compares initializer parameters to stored properties of the struct
  private func matchesPropertyList(
    parameters: FunctionParameterListSyntax,
    properties: [VariableDeclSyntax]
  ) -> Bool {
    guard parameters.count == properties.count else { return false }
    for (idx, parameter) in parameters.enumerated() {

      guard parameter.secondName == nil else { return false }

      let property = properties[idx]
      let propertyId = property.firstIdentifier
      guard let propertyType = property.firstType else { return false }

      // Ensure that parameters that correspond to properties declared using 'var' have a default
      // argument that is identical to the property's default value. Otherwise, a default argument
      // doesn't match the memberwise initializer.
      let isVarDecl = property.bindingKeyword.tokenKind == .keyword(.var)
      if isVarDecl, let initializer = property.firstInitializer {
        guard let defaultArg = parameter.defaultArgument else { return false }
        guard initializer.value.description == defaultArg.value.description else { return false }
      } else if parameter.defaultArgument != nil {
        return false
      }

      if propertyId.identifier.text != parameter.firstName.text
        || propertyType.description.trimmingCharacters(
          in: .whitespaces) != parameter.type.description.trimmingCharacters(in: .whitespacesAndNewlines)
      { return false }
    }
    return true
  }

  // Evaluates if all, and only, the stored properties are initialized in the body
  private func matchesAssignmentBody(
    variables: [VariableDeclSyntax],
    initBody: CodeBlockSyntax?
  ) -> Bool {
    guard let initBody = initBody else { return false }
    guard variables.count == initBody.statements.count else { return false }

    var statements: [String] = []
    for statement in initBody.statements {
      guard
        let expr = statement.item.as(InfixOperatorExprSyntax.self),
        expr.operatorOperand.is(AssignmentExprSyntax.self)
      else {
        return false
      }

      var leftName = ""
      var rightName = ""

      if let memberAccessExpr = expr.leftOperand.as(MemberAccessExprSyntax.self) {
        guard
          let base = memberAccessExpr.base,
          base.description.trimmingCharacters(in: .whitespacesAndNewlines) == "self"
        else {
          return false
        }

        leftName = memberAccessExpr.name.text
      } else {
        return false
      }

      if let identifierExpr = expr.rightOperand.as(IdentifierExprSyntax.self) {
        rightName = identifierExpr.identifier.text
      } else {
        return false
      }

      guard leftName == rightName else { return false }
      statements.append(leftName)
    }

    for variable in variables {
      let id = variable.firstIdentifier.identifier.text
      guard statements.contains(id) else { return false }
      guard let idx = statements.firstIndex(of: id) else { return false }
      statements.remove(at: idx)
    }
    return statements.isEmpty
  }
}

extension Finding.Message {
  public static let removeRedundantInitializer: Finding.Message =
    "remove initializer and use the synthesized initializer"
}

/// Defines the access levels which may be assigned to a synthesized memberwise initializer.
fileprivate enum AccessLevel {
  case `internal`
  case `fileprivate`
  case `private`
}

/// Computes the access level which would be applied to the synthesized memberwise initializer of
/// a struct that contains the given properties.
///
/// The rules for default memberwise initializer access levels are defined in The Swift
/// Programming Language:
/// https://docs.swift.org/swift-book/LanguageGuide/AccessControl.html#ID21
///
/// - Parameter properties: The properties contained within the struct.
/// - Returns: The synthesized memberwise initializer's access level.
fileprivate func synthesizedInitAccessLevel(using properties: [VariableDeclSyntax]) -> AccessLevel {
  var hasFileprivate = false
  for property in properties {
    guard let modifiers = property.modifiers else { continue }

    // Private takes precedence, so finding 1 private property defines the access level.
    if modifiers.contains(where: {$0.name.tokenKind == .keyword(.private) && $0.detail == nil}) {
      return .private
    }
    if modifiers.contains(where: {$0.name.tokenKind == .keyword(.fileprivate) && $0.detail == nil}) {
      hasFileprivate = true
      // Can't break here because a later property might be private.
    }
  }
  return hasFileprivate ? .fileprivate : .internal
}
