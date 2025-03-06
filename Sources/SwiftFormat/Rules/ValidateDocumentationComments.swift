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
import Markdown
import SwiftSyntax

/// Documentation comments must be complete and valid.
///
/// "Command + Option + /" in Xcode produces a minimal valid documentation comment.
///
/// Lint: Documentation comments that are incomplete (e.g. missing parameter documentation) or
///       invalid (uses `Parameters` when there is only one parameter) will yield a lint error.
///
/// Format: Documentation comments that use `Parameters` with only one parameter, or that use
///         multiple `Parameter` lines, will be corrected.
@_spi(Rules)
public final class ValidateDocumentationComments: SyntaxFormatRule {
  /// Identifies this rule as being opt-in. Accurate and complete documentation comments are
  /// important, but this rule isn't able to handle situations where portions of documentation are
  /// redundant. For example when the returns clause is redundant for a simple declaration.
  public override class var isOptIn: Bool { return true }

  public override func visit(_ node: InitializerDeclSyntax) -> DeclSyntax {
    checkFunctionLikeDocumentation(
      DeclSyntax(node),
      name: "init",
      signature: node.signature
    )
  }

  public override func visit(_ node: FunctionDeclSyntax) -> DeclSyntax {
    checkFunctionLikeDocumentation(
      DeclSyntax(node),
      name: node.name.text,
      signature: node.signature,
      returnClause: node.signature.returnClause
    )
  }

  private func checkFunctionLikeDocumentation(
    _ node: DeclSyntax,
    name: String,
    signature: FunctionSignatureSyntax,
    returnClause: ReturnClauseSyntax? = nil
  ) -> DeclSyntax {
    guard
      let docComment = DocumentationComment(extractedFrom: node),
      !docComment.parameters.isEmpty
    else {
      return node
    }

    // If a single sentence summary is the only documentation, parameter(s) and
    // returns tags may be omitted.
    if docComment.briefSummary != nil
      && docComment.bodyNodes.isEmpty
      && docComment.parameters.isEmpty
      && docComment.returns == nil
    {
      return node
    }

    validateThrows(
      signature.effectSpecifiers?.throwsClause?.throwsSpecifier,
      name: name,
      throwsDescription: docComment.throws,
      node: node
    )
    validateReturn(
      returnClause,
      name: name,
      returnsDescription: docComment.returns,
      node: node
    )
    let funcParameters = funcParametersIdentifiers(in: signature.parameterClause.parameters)
    // Note: Don't try to restructure the documentation if there's a mismatch in
    // the number of described parameters.
    let docCountMatchesDeclCount = docComment.parameters.count == funcParameters.count

    // If the documentation of the parameters is wrong, 'docCommentInfo' won't
    // parse the parameters correctly. The documentation has to be fixed
    // in order to validate the other conditions.
    if docComment.parameterLayout != .separated && funcParameters.count == 1 {
      diagnose(.useSingularParameter, on: node)
      return docCountMatchesDeclCount
        ? convertToSeparated(node, docComment: docComment)
        : node
    } else if docComment.parameterLayout != .outline && funcParameters.count > 1 {
      diagnose(.usePluralParameters, on: node)
      return docCountMatchesDeclCount
        ? convertToOutline(node, docComment: docComment)
        : node
    }

    // Ensures that the parameters of the documentation and the function signature
    // are the same.
    if !docCountMatchesDeclCount
      || !parametersAreEqual(params: docComment.parameters, funcParam: funcParameters)
    {
      diagnose(.parametersDontMatch(funcName: name), on: node)
    }

    return node
  }

  /// Ensures the function has a return documentation if it actually returns
  /// a value.
  private func validateReturn(
    _ returnClause: ReturnClauseSyntax?,
    name: String,
    returnsDescription: Paragraph?,
    node: DeclSyntax
  ) {
    if returnClause == nil && returnsDescription != nil {
      diagnose(.removeReturnComment(funcName: name), on: node)
    } else if let returnClause = returnClause, returnsDescription == nil {
      if let returnTypeIdentifier = returnClause.type.as(IdentifierTypeSyntax.self),
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
    throwsDescription: Paragraph?,
    node: DeclSyntax
  ) {
    // Documentation is required for functions marked as `throws`.
    // For functions marked as `rethrows`, documentation is not enforced
    // since they don’t introduce new errors of their own.
    // However, it can still be included if needed.
    let needsThrowsDesc = throwsOrRethrowsKeyword?.tokenKind == .keyword(.throws)

    if throwsOrRethrowsKeyword == nil && throwsDescription != nil {
      diagnose(
        .removeThrowsComment(funcName: name),
        on: throwsOrRethrowsKeyword ?? node.firstToken(viewMode: .sourceAccurate)
      )
    } else if needsThrowsDesc && throwsDescription == nil {
      diagnose(.documentErrorsThrown(funcName: name), on: throwsOrRethrowsKeyword)
    }
  }

  private func convertToSeparated(
    _ node: DeclSyntax,
    docComment: DocumentationComment
  ) -> DeclSyntax {
    guard #available(macOS 13, *) else { return node }  // Regexes ahead
    guard docComment.parameterLayout == .outline else { return node }

    // Find the start of the documentation that is attached to this
    // identifier, skipping over any trivia that doesn't actually
    // attach (like `//` comments or full blank lines).
    var docCommentTrivia = Array(node.leadingTrivia)
    guard let startOfActualDocumentation = findStartOfDocComments(in: docCommentTrivia)
    else { return node }

    // We're required to have a '- Parameters:' header followed by exactly one
    // '- identifier: ....' block; find the index of both of those lines.
    guard
      let headerIndex = docCommentTrivia[startOfActualDocumentation...]
        .firstIndex(where: \.isOutlineParameterHeader)
    else { return node }

    guard
      let paramIndex = docCommentTrivia[headerIndex...].dropFirst()
        .firstIndex(where: \.isOutlineParameter),
      let originalCommentLine = docCommentTrivia[paramIndex].docLineString
    else { return node }

    // Update the comment to be a single parameter description, and then remove
    // the outline header.
    docCommentTrivia[paramIndex] = .docLineComment(
      originalCommentLine.replacing("///   - ", with: "/// - Parameter ")
    )

    let endOfHeader = docCommentTrivia[headerIndex...].dropFirst()
      .firstIndex(where: { !$0.isWhitespace })!
    docCommentTrivia.removeSubrange(headerIndex..<endOfHeader)

    // Return the original node with the modified trivia.
    var result = node
    result.leadingTrivia = Trivia(pieces: docCommentTrivia)
    return result
  }

  private func convertToOutline(
    _ node: DeclSyntax,
    docComment: DocumentationComment
  ) -> DeclSyntax {
    guard #available(macOS 13, *) else { return node }  // Regexes ahead
    guard docComment.parameterLayout == .separated else { return node }

    // Find the start of the documentation that is attached to this
    // identifier, skipping over any trivia that doesn't actually
    // attach (like `//` comments or full blank lines).
    var docCommentTrivia = Array(node.leadingTrivia)
    guard let startOfActualDocumentation = findStartOfDocComments(in: docCommentTrivia)
    else { return node }

    // Find the indexes of all the lines that start with a separate parameter
    // doc pattern, then convert them to outline syntax.
    let parameterIndexes = docCommentTrivia[startOfActualDocumentation...]
      .indices
      .filter { i in docCommentTrivia[i].isSeparateParameter }

    for i in parameterIndexes {
      docCommentTrivia[i] = .docLineComment(
        docCommentTrivia[i].docLineString!.replacing("/// - Parameter ", with: "///   - ")
      )
    }

    // Add in the parameter outline header.
    guard let firstParamIndex = parameterIndexes.first else { return node }
    let interstitialSpace = docCommentTrivia[firstParamIndex...].dropFirst()
      .prefix(while: \.isWhitespace)

    docCommentTrivia.insert(
      contentsOf: [.docLineComment("/// - Parameters:")] + interstitialSpace,
      at: firstParamIndex
    )

    // Return the original node with the modified trivia.
    var result = node
    result.leadingTrivia = Trivia(pieces: docCommentTrivia)
    return result
  }
}

/// Iterates through every parameter of paramList and returns a list of the
/// parameters identifiers.
fileprivate func funcParametersIdentifiers(in paramList: FunctionParameterListSyntax) -> [String] {
  var funcParameters = [String]()
  for parameter in paramList {
    // If there is a label and an identifier, then the identifier (`secondName`) is the name that
    // should be documented. Otherwise, the label and identifier are the same, occupying
    // `firstName`.
    let parameterIdentifier = parameter.secondName ?? parameter.firstName
    funcParameters.append(parameterIdentifier.text)
  }
  return funcParameters
}

/// Indicates if the parameters name from the documentation and the parameters
/// from the declaration are the same.
fileprivate func parametersAreEqual(
  params: [DocumentationComment.Parameter],
  funcParam: [String]
) -> Bool {
  for index in 0..<params.count {
    if params[index].name != funcParam[index] {
      return false
    }
  }
  return true
}

fileprivate func findStartOfDocComments(in trivia: [TriviaPiece]) -> Int? {
  let startOfCommentSection =
    trivia
    .lastIndex(where: { !$0.continuesDocComment })
    ?? trivia.startIndex
  return trivia[startOfCommentSection...].firstIndex(where: \.isDocComment)
}

extension TriviaPiece {
  fileprivate var docLineString: String? {
    if case .docLineComment(let str) = self { return str } else { return nil }
  }

  fileprivate var isDocComment: Bool {
    switch self {
    case .docBlockComment, .docLineComment: return true
    default: return false
    }
  }

  fileprivate var continuesDocComment: Bool {
    if isDocComment { return true }
    switch self {
    // Any amount of horizontal whitespace is okay
    case .spaces, .tabs:
      return true
    // One line break is okay
    case .newlines(1), .carriageReturns(1), .carriageReturnLineFeeds(1):
      return true
    default:
      return false
    }
  }
}

@available(macOS 13, *)
extension TriviaPiece {
  fileprivate var isOutlineParameterHeader: Bool {
    guard let docLineString else { return false }
    return docLineString.contains(#/^\s*/// - Parameters:/#)
  }

  fileprivate var isOutlineParameter: Bool {
    guard let docLineString else { return false }
    return docLineString.contains(#/^\s*///   - .+?:/#)
  }

  fileprivate var isSeparateParameter: Bool {
    guard let docLineString else { return false }
    return docLineString.contains(#/^\s*/// - Parameter .+?:/#)
  }

  fileprivate var isCommentBlankLine: Bool {
    guard let docLineString else { return false }
    return docLineString.contains(#/^\s*///\s*$/#)
  }
}

extension BidirectionalCollection {
  fileprivate func suffix(while predicate: (Element) throws -> Bool) rethrows -> SubSequence {
    var current = endIndex
    while current > startIndex {
      let prev = index(before: current)
      if try !predicate(self[prev]) {
        return self[current...]
      }
      current = prev
    }
    return self[...]
  }
}

extension Finding.Message {
  fileprivate static func documentReturnValue(funcName: String) -> Finding.Message {
    "add a 'Returns:' section to document the return value of '\(funcName)'"
  }

  fileprivate static func removeReturnComment(funcName: String) -> Finding.Message {
    "remove the 'Returns:' section of '\(funcName)'; it does not return a value"
  }

  fileprivate static func parametersDontMatch(funcName: String) -> Finding.Message {
    "change the parameters of the documentation of '\(funcName)' to match its parameters"
  }

  fileprivate static let useSingularParameter: Finding.Message =
    "replace the plural 'Parameters:' section with a singular inline 'Parameter' section"

  fileprivate static let usePluralParameters: Finding.Message =
    """
    replace the singular inline 'Parameter' section with a plural 'Parameters:' section \
    that has the parameters nested inside it
    """

  fileprivate static func removeThrowsComment(funcName: String) -> Finding.Message {
    "remove the 'Throws:' sections of '\(funcName)'; it does not throw any errors"
  }

  fileprivate static func documentErrorsThrown(funcName: String) -> Finding.Message {
    "add a 'Throws:' section to document the errors thrown by '\(funcName)'"
  }
}
