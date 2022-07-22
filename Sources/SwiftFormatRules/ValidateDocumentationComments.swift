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

/// Documentation comments must be complete and valid.
///
/// "Command + Option + /" in Xcode produces a minimal valid documentation comment.
///
/// Lint: Documentation comments that are incomplete (e.g. missing parameter documentation) or
///       invalid (uses `Parameters` when there is only one parameter) will yield a lint error.
public final class ValidateDocumentationComments: SyntaxLintRule {

  /// Identifies this rule as being opt-in. Accurate and complete documentation comments are
  /// important, but this rule isn't able to handle situations where portions of documentation are
  /// redundant. For example when the returns clause is redundant for a simple declaration.
  public override class var isOptIn: Bool { return true }

  public override func visit(_ node: InitializerDeclSyntax) -> SyntaxVisitorContinueKind {
    return checkFunctionLikeDocumentation(
      DeclSyntax(node), name: "init", signature: node.signature)
  }

  public override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
    return checkFunctionLikeDocumentation(
      DeclSyntax(node), name: node.identifier.text, signature: node.signature,
      returnClause: node.signature.output)
  }

  private func checkFunctionLikeDocumentation(
    _ node: DeclSyntax,
    name: String,
    signature: FunctionSignatureSyntax,
    returnClause: ReturnClauseSyntax? = nil
  ) -> SyntaxVisitorContinueKind {
    guard let declComment = node.docComment else { return .skipChildren }
    guard let commentInfo = node.docCommentInfo else { return .skipChildren }
    guard let params = commentInfo.parameters else { return .skipChildren }

    // If a single sentence summary is the only documentation, parameter(s) and
    // returns tags may be ommitted.
    if commentInfo.oneSentenceSummary != nil && commentInfo.commentParagraphs!.isEmpty && params
      .isEmpty && commentInfo.returnsDescription == nil
    {
      return .skipChildren
    }

    // Indicates if the documentation uses 'Parameters' as description of the
    // documented parameters.
    let hasPluralDesc = declComment.components(separatedBy: .newlines).contains {
      $0.trimmingCharacters(in: .whitespaces).starts(with: "- Parameters")
    }

    validateThrows(
      signature.throwsOrRethrowsKeyword, name: name, throwsDesc: commentInfo.throwsDescription, node: node)
    validateReturn(
      returnClause, name: name, returnDesc: commentInfo.returnsDescription, node: node)
    let funcParameters = funcParametersIdentifiers(in: signature.input.parameterList)

    // If the documentation of the parameters is wrong 'docCommentInfo' won't
    // parse the parameters correctly. First the documentation has to be fix
    // in order to validate the other conditions.
    if hasPluralDesc && funcParameters.count == 1 {
      diagnose(.useSingularParameter, on: node)
      return .skipChildren
    } else if !hasPluralDesc && funcParameters.count > 1 {
      diagnose(.usePluralParameters, on: node)
      return .skipChildren
    }

    // Ensures that the parameters of the documantation and the function signature
    // are the same.
    if (params.count != funcParameters.count) || !parametersAreEqual(
      params: params, funcParam: funcParameters)
    {
      diagnose(.parametersDontMatch(funcName: name), on: node)
    }

    return .skipChildren
  }

  /// Ensures the function has a return documentation if it actually returns
  /// a value.
  private func validateReturn(
    _ returnClause: ReturnClauseSyntax?,
    name: String,
    returnDesc: String?,
    node: DeclSyntax
  ) {
    if returnClause == nil && returnDesc != nil {
      diagnose(.removeReturnComment(funcName: name), on: node)
    } else if let returnClause = returnClause, returnDesc == nil {
      if let returnTypeIdentifier = returnClause.returnType.as(SimpleTypeIdentifierSyntax.self),
         returnTypeIdentifier.name.text == "Never"
      {
        return
      }
      diagnose(.documentReturnValue(funcName: name), on: returnClause)
    }
  }

  /// Ensures the function has throws documentation if it may actually throw
  /// an error.
  private func validateThrows(
    _ throwsOrRethrowsKeyword: TokenSyntax?,
    name: String,
    throwsDesc: String?,
    node: DeclSyntax
  ) {
    // If a function is marked as `rethrows`, it doesn't have any errors of its
    // own that should be documented. So only require documentation for
    // functions marked `throws`.
    let needsThrowsDesc = throwsOrRethrowsKeyword?.tokenKind == .throwsKeyword

    if !needsThrowsDesc && throwsDesc != nil {
      diagnose(.removeThrowsComment(funcName: name), on: throwsOrRethrowsKeyword ?? node.firstToken)
    } else if needsThrowsDesc && throwsDesc == nil {
      diagnose(.documentErrorsThrown(funcName: name), on: throwsOrRethrowsKeyword)
    }
  }
}

/// Iterates through every parameter of paramList and returns a list of the
/// paramters identifiers.
fileprivate func funcParametersIdentifiers(in paramList: FunctionParameterListSyntax) -> [String] {
  var funcParameters = [String]()
  for parameter in paramList {
    // If there is a label and an identifier, then the identifier (`secondName`) is the name that
    // should be documented. Otherwise, the label and identifier are the same, occupying
    // `firstName`.
    guard let parameterIdentifier = parameter.secondName ?? parameter.firstName else {
      continue
    }
    funcParameters.append(parameterIdentifier.text)
  }
  return funcParameters
}

/// Indicates if the parameters name from the documentation and the parameters
/// from the declaration are the same.
fileprivate func parametersAreEqual(params: [ParseComment.Parameter], funcParam: [String]) -> Bool {
  for index in 0..<params.count {
    if params[index].name != funcParam[index] {
      return false
    }
  }
  return true
}

extension Finding.Message {
  public static func documentReturnValue(funcName: String) -> Finding.Message {
    "document the return value of \(funcName)"
  }

  public static func removeReturnComment(funcName: String) -> Finding.Message {
    "remove the return comment of \(funcName), it doesn't return a value"
  }

  public static func parametersDontMatch(funcName: String) -> Finding.Message {
    "change the parameters of \(funcName)'s documentation to match its parameters"
  }

  public static let useSingularParameter: Finding.Message =
    "replace the plural form of 'Parameters' with a singular inline form of the 'Parameter' tag"

  public static let usePluralParameters: Finding.Message =
    """
    replace the singular inline form of 'Parameter' tag with a plural 'Parameters' tag \
    and group each parameter as a nested list
    """

  public static func removeThrowsComment(funcName: String) -> Finding.Message {
    "remove the 'Throws' tag for non-throwing function \(funcName)"
  }

  public static func documentErrorsThrown(funcName: String) -> Finding.Message {
    "add a 'Throws' tag describing the errors thrown by \(funcName)"
  }
}
