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
///
/// - SeeAlso: https://google.github.io/swift#initializers-2
public struct UseSynthesizedInitializer: SyntaxLintRule {
  public let context: Context

  public init(context: Context) {
    self.context = context
  }

  public func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
    var storedProperties: [VariableDeclSyntax] = []
    var initializers: [InitializerDeclSyntax] = []

    for memberItem in node.members.members {
      let member = memberItem.decl
      // Collect all stored variables into a list
      if let varDecl = member as? VariableDeclSyntax {
        guard let modifiers = varDecl.modifiers else {
          storedProperties.append(varDecl)
          continue
        }
        guard !modifiers.has(modifier: "static") else { continue }
        storedProperties.append(varDecl)
        // Collect any possible redundant initializers into a list
      } else if let initDecl = member as? InitializerDeclSyntax {
        guard initDecl.modifiers == nil || initDecl.modifiers!.has(modifier: "internal") else {
          continue
        }
        guard initDecl.optionalMark == nil else { continue }
        guard initDecl.throwsOrRethrowsKeyword == nil else { continue }
        initializers.append(initDecl)
      }
    }

    for initializer in initializers {
      guard
        matchesPropertyList(
          parameters: initializer.parameters.parameterList,
          properties: storedProperties)
      else { continue }
      guard
        matchesAssignmentBody(
          variables: storedProperties,
          initBody: initializer.body)
      else { continue }
      diagnose(.removeRedundantInitializer, on: initializer)
    }

    return .skipChildren
  }

  // Compares initializer parameters to stored properties of the struct
  func matchesPropertyList(
    parameters: FunctionParameterListSyntax,
    properties: [VariableDeclSyntax]
  ) -> Bool {
    guard parameters.count == properties.count else { return false }
    for (idx, parameter) in parameters.enumerated() {

      guard let paramId = parameter.firstName, parameter.secondName == nil else { return false }
      guard let paramType = parameter.type else { return false }

      let property = properties[idx]
      let propertyId = property.firstIdentifier
      guard let propertyType = property.firstType else { return false }

      // Sythesized initializer only keeps default argument if the declaration uses 'var'
      if property.letOrVarKeyword.tokenKind == .varKeyword {
        if let initializer = property.firstInitializer {
          guard let defaultArg = parameter.defaultArgument else { return false }
          guard initializer.value.description == defaultArg.value.description else { return false }
        }
      }

      if propertyId.identifier.text != paramId.text || propertyType.description.trimmingCharacters(
        in: .whitespaces) != paramType.description.trimmingCharacters(in: .whitespacesAndNewlines)
      { return false }
    }
    return true
  }

  // Evaluates if all, and only, the stored properties are initialized in the body
  func matchesAssignmentBody(
    variables: [VariableDeclSyntax],
    initBody: CodeBlockSyntax?
  ) -> Bool {
    guard let initBody = initBody else { return false }
    guard variables.count == initBody.statements.count else { return false }

    var statements: [String] = []
    for statement in initBody.statements {
      guard let exp = statement.item as? SequenceExprSyntax else { return false }
      var leftName = ""
      var rightName = ""

      for element in exp.elements {
        switch element {
        case let element as MemberAccessExprSyntax:
          guard let base = element.base,
            base.description.trimmingCharacters(in: .whitespacesAndNewlines) == "self"
          else {
            return false
          }
          leftName = element.name.text
        case let element as AssignmentExprSyntax:
          guard element.assignToken.tokenKind == .equal else { return false }
        case let element as IdentifierExprSyntax:
          rightName = element.identifier.text
        default:
          return false
        }
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

extension Diagnostic.Message {
  static let removeRedundantInitializer = Diagnostic.Message(
    .warning,
    "initializer is the same as synthesized initializer")
}
