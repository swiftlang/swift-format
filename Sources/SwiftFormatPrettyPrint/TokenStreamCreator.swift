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
import SwiftFormatConfiguration
import SwiftFormatCore
import SwiftSyntax

private let rangeOperators: Set = ["...", "..<"]

/// Visits the nodes of a syntax tree and constructs a linear stream of formatting tokens that
/// tell the pretty printer how the source text should be laid out.
private final class TokenStreamCreator: SyntaxVisitor {
  private var tokens = [Token]()
  private var beforeMap = [TokenSyntax: [Token]]()
  private var afterMap = [TokenSyntax: [[Token]]]()
  private let config: Configuration
  private let maxlinelength: Int

  init(configuration: Configuration) {
    self.config = configuration
    self.maxlinelength = config.lineLength
  }

  func makeStream(from node: Syntax) -> [Token] {
    // Because `walk` takes an `inout` argument, and we're a class, we have to do the following
    // dance to pass ourselves in.
    var mutableSelf = self
    node.walk(&mutableSelf)
    defer { tokens = [] }
    return tokens
  }

  var openings = 0

  /// If the syntax token is non-nil, enqueue the given list of formatting tokens before it in the
  /// token stream.
  func before(_ token: TokenSyntax?, tokens: Token...) {
    before(token, tokens: tokens)
  }

  /// If the syntax token is non-nil, enqueue the given list of formatting tokens before it in the
  /// token stream.
  func before(_ token: TokenSyntax?, tokens: [Token]) {
    guard let tok = token else { return }
    for preToken in tokens {
      if case .open = preToken {
        openings += 1
      } else if case .close = preToken {
        assert(openings > 0)
        openings -= 1
      }
    }
    beforeMap[tok, default: []] += tokens
  }

  /// If the syntax token is non-nil, enqueue the given list of formatting tokens after it in the
  /// token stream.
  func after(_ token: TokenSyntax?, tokens: Token...) {
    after(token, tokens: tokens)
  }

  /// If the syntax token is non-nil, enqueue the given list of formatting tokens after it in the
  /// token stream.
  func after(_ token: TokenSyntax?, tokens: [Token]) {
    guard let tok = token else { return }
    for postToken in tokens {
      if case .open = postToken {
        openings += 1
      } else if case .close = postToken {
        assert(openings > 0)
        openings -= 1
      }
    }
    afterMap[tok, default: []].append(tokens)
  }

  /// Enqueues the given list of formatting tokens between each element of the given syntax
  /// collection (but not before the first one nor after the last one).
  private func insertTokens<Node: SyntaxCollection>(
    _ tokens: Token...,
    betweenElementsOf collectionNode: Node
  ) where Node.Element == Syntax {
    for element in collectionNode.dropLast() {
      after(element.lastToken, tokens: tokens)
    }
  }

  /// Enqueues the given list of formatting tokens between each element of the given syntax
  /// collection (but not before the first one nor after the last one).
  private func insertTokens<Node: SyntaxCollection>(
    _ tokens: Token...,
    betweenElementsOf collectionNode: Node
  ) where Node.Element: Syntax {
    for element in collectionNode.dropLast() {
      after(element.lastToken, tokens: tokens)
    }
  }

  /// Enqueues the given list of formatting tokens between each element of the given syntax
  /// collection (but not before the first one nor after the last one).
  private func insertTokens<Node: SyntaxCollection>(
    _ tokens: Token...,
    betweenElementsOf collectionNode: Node
  ) where Node.Element == DeclSyntax {
    for element in collectionNode.dropLast() {
      after(element.lastToken, tokens: tokens)
    }
  }

  private func verbatimToken(_ node: Syntax) {
    if let firstToken = node.firstToken {
      appendBeforeTokens(firstToken)
    }

    appendToken(.verbatim(Verbatim(text: node.description)))

    if let lastToken = node.lastToken {
      // Extract any comments that trail the verbatim block since they belong to the next syntax
      // token. Leading comments don't need special handling since they belong to the current node,
      // and will get printed.
      appendAfterTokensAndTrailingComments(lastToken)
    }
  }

  // MARK: - Type declaration nodes

  func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
    arrangeTypeDeclBlock(
      node,
      attributes: node.attributes,
      modifiers: node.modifiers,
      typeKeyword: node.classKeyword,
      identifier: node.identifier,
      genericParameterClause: node.genericParameterClause,
      inheritanceClause: node.inheritanceClause,
      genericWhereClause: node.genericWhereClause,
      members: node.members)
    return .visitChildren
  }

  func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
    arrangeTypeDeclBlock(
      node,
      attributes: node.attributes,
      modifiers: node.modifiers,
      typeKeyword: node.structKeyword,
      identifier: node.identifier,
      genericParameterClause: node.genericParameterClause,
      inheritanceClause: node.inheritanceClause,
      genericWhereClause: node.genericWhereClause,
      members: node.members)
    return .visitChildren
  }

  func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
    arrangeTypeDeclBlock(
      node,
      attributes: node.attributes,
      modifiers: node.modifiers,
      typeKeyword: node.enumKeyword,
      identifier: node.identifier,
      genericParameterClause: node.genericParameters,
      inheritanceClause: node.inheritanceClause,
      genericWhereClause: node.genericWhereClause,
      members: node.members)
    return .visitChildren
  }

  func visit(_ node: ProtocolDeclSyntax) -> SyntaxVisitorContinueKind {
    arrangeTypeDeclBlock(
      node,
      attributes: node.attributes,
      modifiers: node.modifiers,
      typeKeyword: node.protocolKeyword,
      identifier: node.identifier,
      genericParameterClause: nil,
      inheritanceClause: node.inheritanceClause,
      genericWhereClause: node.genericWhereClause,
      members: node.members)
    return .visitChildren
  }

  func visit(_ node: ExtensionDeclSyntax) -> SyntaxVisitorContinueKind {
    guard let lastTokenOfExtendedType = node.extendedType.lastToken else {
      fatalError("ExtensionDeclSyntax.extendedType must have at least one token")
    }
    arrangeTypeDeclBlock(
      node,
      attributes: node.attributes,
      modifiers: node.modifiers,
      typeKeyword: node.extensionKeyword,
      identifier: lastTokenOfExtendedType,
      genericParameterClause: nil,
      inheritanceClause: node.inheritanceClause,
      genericWhereClause: node.genericWhereClause,
      members: node.members)
    return .visitChildren
  }

  /// Applies formatting tokens to the tokens in the given type declaration node (i.e., a class,
  /// struct, enum, protocol, or extension).
  private func arrangeTypeDeclBlock(
    _ node: Syntax,
    attributes: AttributeListSyntax?,
    modifiers: ModifierListSyntax?,
    typeKeyword: TokenSyntax,
    identifier: TokenSyntax,
    genericParameterClause: GenericParameterClauseSyntax?,
    inheritanceClause: TypeInheritanceClauseSyntax?,
    genericWhereClause: GenericWhereClauseSyntax?,
    members: MemberDeclBlockSyntax
  ) {
    before(node.firstToken, tokens: .open)

    arrangeAttributeList(attributes)

    // Prioritize keeping "<modifiers> <keyword> <name>:" together (corresponding group close is
    // below at `lastTokenBeforeBrace`).
    let firstTokenAfterAttributes = modifiers?.firstToken ?? typeKeyword
    before(firstTokenAfterAttributes, tokens: .open)
    after(typeKeyword, tokens: .break)

    arrangeBracesAndContents(of: members, contentsKeyPath: \.members)

    if let genericWhereClause = genericWhereClause {
      before(genericWhereClause.firstToken, tokens: .break(.same), .open)
      after(members.leftBrace, tokens: .close)
    }

    let lastTokenBeforeBrace = inheritanceClause?.colon ?? genericParameterClause?.rightAngleBracket
      ?? identifier
    after(lastTokenBeforeBrace, tokens: .close)

    after(node.lastToken, tokens: .close)
  }

  // MARK: - Function and function-like declaration nodes (initializers, deinitializers, subscripts)

  func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
    // Prioritize keeping "<modifiers> func <name>" together.
    let firstTokenAfterAttributes = node.modifiers?.firstToken ?? node.funcKeyword
    before(firstTokenAfterAttributes, tokens: .open)
    after(node.funcKeyword, tokens: .break)
    after(node.identifier, tokens: .close)

    if case .spacedBinaryOperator = node.identifier.tokenKind {
      after(node.identifier.lastToken, tokens: .space)
    }

    arrangeFunctionLikeDecl(
      node,
      attributes: node.attributes,
      genericWhereClause: node.genericWhereClause,
      body: node.body,
      bodyContentsKeyPath: \.statements)

    return .visitChildren
  }

  func visit(_ node: InitializerDeclSyntax) -> SyntaxVisitorContinueKind {
    // Prioritize keeping "<modifiers> init<punctuation>" together.
    let firstTokenAfterAttributes = node.modifiers?.firstToken ?? node.initKeyword
    let lastTokenOfName = node.optionalMark ?? node.initKeyword
    if firstTokenAfterAttributes != lastTokenOfName {
      before(firstTokenAfterAttributes, tokens: .open)
      after(lastTokenOfName, tokens: .close)
    }

    before(node.throwsOrRethrowsKeyword, tokens: .break)

    arrangeFunctionLikeDecl(
      node,
      attributes: node.attributes,
      genericWhereClause: node.genericWhereClause,
      body: node.body,
      bodyContentsKeyPath: \.statements)

    return .visitChildren
  }

  func visit(_ node: DeinitializerDeclSyntax) -> SyntaxVisitorContinueKind {
    arrangeFunctionLikeDecl(
      node,
      attributes: node.attributes,
      genericWhereClause: nil,
      body: node.body,
      bodyContentsKeyPath: \.statements)
    return .visitChildren
  }

  func visit(_ node: SubscriptDeclSyntax) -> SyntaxVisitorContinueKind {
    before(node.firstToken, tokens: .open)

    // Prioritize keeping "<modifiers> subscript" together.
    if let firstModifierToken = node.modifiers?.firstToken {
      before(firstModifierToken, tokens: .open)
      after(node.subscriptKeyword, tokens: .close)
    }

    arrangeAttributeList(node.attributes)

    if let genericWhereClause = node.genericWhereClause {
      before(genericWhereClause.firstToken, tokens: .break(.same), .open)
      after(genericWhereClause.lastToken, tokens: .close)
    }

    before(node.result.firstToken, tokens: .break)

    if let accessorOrCodeBlock = node.accessor {
      arrangeAccessorOrCodeBlock(accessorOrCodeBlock)
    }

    after(node.lastToken, tokens: .close)

    return .visitChildren
  }

  /// Applies formatting tokens to the given syntax node, assuming that it is either an
  /// `AccessorBlockSyntax` or a `CodeBlockSyntax`.
  ///
  /// - Parameter node: The syntax node to arrange.
  private func arrangeAccessorOrCodeBlock(_ node: Syntax) {
    switch node {
    case let accessorBlock as AccessorBlockSyntax:
      arrangeBracesAndContents(of: accessorBlock)
    case let codeBlock as CodeBlockSyntax:
      arrangeBracesAndContents(of: codeBlock, contentsKeyPath: \.statements)
    default:
      preconditionFailure(
        """
        This should be unreachable; we expected an AccessorBlockSyntax or a CodeBlockSyntax, but \
        found: \(type(of: node))
        """
      )
    }
  }

  /// Applies formatting tokens to the tokens in the given function or function-like declaration
  /// node (e.g., initializers, deinitiailizers, and subscripts).
  private func arrangeFunctionLikeDecl<Node: BracedSyntax, BodyContents: SyntaxCollection>(
    _ node: Syntax,
    attributes: AttributeListSyntax?,
    genericWhereClause: GenericWhereClauseSyntax?,
    body: Node?,
    bodyContentsKeyPath: KeyPath<Node, BodyContents>?
  ) where BodyContents.Element: Syntax {
    before(node.firstToken, tokens: .open)

    arrangeAttributeList(attributes)
    arrangeBracesAndContents(of: body, contentsKeyPath: bodyContentsKeyPath)

    if let genericWhereClause = genericWhereClause {
      before(genericWhereClause.firstToken, tokens: .break(.same), .open)
      after(body?.leftBrace ?? genericWhereClause.lastToken, tokens: .close)
    }

    after(node.lastToken, tokens: .close)
  }

  // MARK: - Property and subscript accessor block nodes

  func visit(_ node: AccessorListSyntax) -> SyntaxVisitorContinueKind {
    for child in node.dropLast() {
      // If the child doesn't have a body (it's just the `get`/`set` keyword), then we're in a
      // protocol and we want to let them be placed on the same line if possible. Otherwise, we
      // place a newline between each accessor.
      after(child.lastToken, tokens: child.body == nil ? .break(.same) : .newline)
    }
    return .visitChildren
  }

  func visit(_ node: AccessorDeclSyntax) -> SyntaxVisitorContinueKind {
    arrangeAttributeList(node.attributes)
    arrangeBracesAndContents(of: node.body, contentsKeyPath: \.statements)
    return .visitChildren
  }

  func visit(_ node: AccessorParameterSyntax) -> SyntaxVisitorContinueKind {
    return .visitChildren
  }

  // MARK: - Control flow statement nodes

  func visit(_ node: IfStmtSyntax) -> SyntaxVisitorContinueKind {
    after(node.ifKeyword, tokens: .space)

    arrangeBracesAndContents(of: node.body, contentsKeyPath: \.statements)

    let elsePrecedingBreak = config.lineBreakBeforeControlFlowKeywords ? Token.newline : Token.space
    before(node.elseKeyword, tokens: elsePrecedingBreak)
    if node.elseBody is IfStmtSyntax {
      after(node.elseKeyword, tokens: .space)
    }

    arrangeBracesAndContents(of: node.elseBody as? CodeBlockSyntax, contentsKeyPath: \.statements)

    return .visitChildren
  }

  func visit(_ node: GuardStmtSyntax) -> SyntaxVisitorContinueKind {
    after(node.guardKeyword, tokens: .break)
    before(node.elseKeyword, tokens: .break(.reset), .open)
    after(node.elseKeyword, tokens: .break)
    before(node.body.leftBrace, tokens: .close)

    arrangeBracesAndContents(
      of: node.body, contentsKeyPath: \.statements, shouldResetBeforeLeftBrace: false)

    return .visitChildren
  }

  func visit(_ node: ForInStmtSyntax) -> SyntaxVisitorContinueKind {
    after(node.labelColon, tokens: .space)
    after(node.forKeyword, tokens: .space)
    after(node.caseKeyword, tokens: .space)
    before(node.inKeyword, tokens: .break)
    after(node.inKeyword, tokens: .space)

    arrangeBracesAndContents(of: node.body, contentsKeyPath: \.statements)

    return .visitChildren
  }

  func visit(_ node: WhileStmtSyntax) -> SyntaxVisitorContinueKind {
    after(node.labelColon, tokens: .space)
    after(node.whileKeyword, tokens: .space)

    arrangeBracesAndContents(of: node.body, contentsKeyPath: \.statements)

    return .visitChildren
  }

  func visit(_ node: RepeatWhileStmtSyntax) -> SyntaxVisitorContinueKind {
    arrangeBracesAndContents(of: node.body, contentsKeyPath: \.statements)

    let whilePrecedingBreak = config.lineBreakBeforeControlFlowKeywords
      ? Token.break(.same) : Token.space
    before(node.whileKeyword, tokens: whilePrecedingBreak)
    after(node.whileKeyword, tokens: .space)

    return .visitChildren
  }

  func visit(_ node: DoStmtSyntax) -> SyntaxVisitorContinueKind {
    arrangeBracesAndContents(of: node.body, contentsKeyPath: \.statements)
    return .visitChildren
  }

  func visit(_ node: CatchClauseSyntax) -> SyntaxVisitorContinueKind {
    let catchPrecedingBreak = config.lineBreakBeforeControlFlowKeywords
      ? Token.newline : Token.space
    before(node.catchKeyword, tokens: catchPrecedingBreak)
    before(node.pattern?.firstToken, tokens: .space)

    arrangeBracesAndContents(of: node.body, contentsKeyPath: \.statements)

    return .visitChildren
  }

  func visit(_ node: DeferStmtSyntax) -> SyntaxVisitorContinueKind {
    arrangeBracesAndContents(of: node.body, contentsKeyPath: \.statements)
    return .visitChildren
  }

  func visit(_ node: BreakStmtSyntax) -> SyntaxVisitorContinueKind {
    before(node.label, tokens: .break)
    return .visitChildren
  }

  func visit(_ node: ReturnStmtSyntax) -> SyntaxVisitorContinueKind {
    before(node.expression?.firstToken, tokens: .break)
    return .visitChildren
  }

  func visit(_ node: ThrowStmtSyntax) -> SyntaxVisitorContinueKind {
    before(node.expression.firstToken, tokens: .break)
    return .visitChildren
  }

  func visit(_ node: ContinueStmtSyntax) -> SyntaxVisitorContinueKind {
    before(node.label, tokens: .break)
    return .visitChildren
  }

  func visit(_ node: SwitchStmtSyntax) -> SyntaxVisitorContinueKind {
    before(node.switchKeyword, tokens: .open)
    after(node.switchKeyword, tokens: .space)
    before(node.leftBrace, tokens: .break(.reset))
    after(node.leftBrace, tokens: .close)

    if !areBracesCompletelyEmpty(node, contentsKeyPath: \.cases) {
      before(node.rightBrace, tokens: .newline)
    } else {
      before(node.rightBrace, tokens: .break(.same, size: 0))
    }

    return .visitChildren
  }

  func visit(_ node: SwitchCaseSyntax) -> SyntaxVisitorContinueKind {
    before(node.firstToken, tokens: .newline)
    after(node.unknownAttr?.lastToken, tokens: .space)
    after(node.label.lastToken, tokens: .break(.reset, size: 0), .break(.open), .open)
    after(node.lastToken, tokens: .break(.close, size: 0), .close)
    return .visitChildren
  }

  func visit(_ node: SwitchCaseLabelSyntax) -> SyntaxVisitorContinueKind {
    before(node.caseKeyword, tokens: .open)
    after(node.caseKeyword, tokens: .space)
    after(node.colon, tokens: .close)
    return .visitChildren
  }

  func visit(_ node: CaseItemSyntax) -> SyntaxVisitorContinueKind {
    before(node.firstToken, tokens: .open)
    if let trailingComma = node.trailingComma {
      after(trailingComma, tokens: .close, .break)
    } else {
      after(node.lastToken, tokens: .close)
    }
    return .visitChildren
  }

  func visit(_ node: SwitchDefaultLabelSyntax) -> SyntaxVisitorContinueKind {
    // Implementation not needed.
    return .visitChildren
  }

  // TODO: - Other nodes (yet to be organized)

  func visit(_ node: DeclNameArgumentsSyntax) -> SyntaxVisitorContinueKind {
    return .visitChildren
  }

  func visit(_ node: BinaryOperatorExprSyntax) -> SyntaxVisitorContinueKind {
    switch node.operatorToken.tokenKind {
    case .unspacedBinaryOperator:
      break
    default:
      before(node.operatorToken, tokens: .break)
      after(node.operatorToken, tokens: .space)
    }
    return .visitChildren
  }

  func visit(_ node: TupleExprSyntax) -> SyntaxVisitorContinueKind {
    after(node.leftParen, tokens: .break(.open, size: 0), .open)
    before(node.rightParen, tokens: .close, .break(.close, size: 0))
    return .visitChildren
  }

  func visit(_ node: TupleElementListSyntax) -> SyntaxVisitorContinueKind {
    insertTokens(.break(.same), betweenElementsOf: node)
    return .visitChildren
  }

  func visit(_ node: TupleElementSyntax) -> SyntaxVisitorContinueKind {
    before(node.firstToken, tokens: .open)
    after(node.colon, tokens: .break)
    after(node.lastToken, tokens: .close)
    return .visitChildren
  }

  func visit(_ node: ArrayExprSyntax) -> SyntaxVisitorContinueKind {
    after(node.leftSquare, tokens: .break(.open, size: 0), .open)
    before(node.rightSquare, tokens: .close, .break(.close, size: 0))
    return .visitChildren
  }

  func visit(_ node: ArrayElementListSyntax) -> SyntaxVisitorContinueKind {
    insertTokens(.break(.same), betweenElementsOf: node)
    return .visitChildren
  }

  func visit(_ node: ArrayElementSyntax) -> SyntaxVisitorContinueKind {
    before(node.firstToken, tokens: .open)
    after(node.lastToken, tokens: .close)
    return .visitChildren
  }

  func visit(_ node: DictionaryExprSyntax) -> SyntaxVisitorContinueKind {
    after(node.leftSquare, tokens: .break(.open, size: 0), .open)
    before(node.rightSquare, tokens: .close, .break(.close, size: 0))
    return .visitChildren
  }

  func visit(_ node: DictionaryElementListSyntax) -> SyntaxVisitorContinueKind {
    insertTokens(.break(.same), betweenElementsOf: node)
    return .visitChildren
  }

  func visit(_ node: DictionaryTypeSyntax) -> SyntaxVisitorContinueKind {
    after(node.colon, tokens: .break)
    return .visitChildren
  }

  func visit(_ node: DictionaryElementSyntax) -> SyntaxVisitorContinueKind {
    before(node.firstToken, tokens: .open)
    after(node.colon, tokens: .break)
    after(node.lastToken, tokens: .close)
    return .visitChildren
  }

  func visit(_ node: MemberAccessExprSyntax) -> SyntaxVisitorContinueKind {
    if node.base != nil {
      // Only insert a break before the dot if there is something preceding the dot (i.e., it is not
      // an implicit member access).
      before(node.dot, tokens: .break(.continue, size: 0))
    }
    return .visitChildren
  }

  func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
    var argumentIterator = node.argumentList.makeIterator()
    let firstArgument = argumentIterator.next()

    if firstArgument != nil {
      // If there is a trailing closure, force the right parenthesis down to the next line so it
      // stays with the open curly brace.
      let breakBeforeRightParen = node.trailingClosure != nil

      after(node.leftParen, tokens: .break(.open, size: 0), .open(argumentListConsistency()))
      before(
        node.rightParen,
        tokens: .break(.close(mustBreak: breakBeforeRightParen), size: 0), .close)
    }
    before(node.trailingClosure?.leftBrace, tokens: .break(.reset))
    return .visitChildren
  }

  func visit(_ node: FunctionCallArgumentSyntax) -> SyntaxVisitorContinueKind {
    before(node.firstToken, tokens: .open)

    // If we have an open delimiter following the colon, use a space instead of a continuation
    // break so that we don't awkwardly shift the delimiter down and indent it further if it
    // wraps.
    let tokenAfterColon: Token = startsWithOpenDelimiter(node.expression) ? .space : .break
    after(node.colon, tokens: tokenAfterColon)

    if let trailingComma = node.trailingComma {
      after(trailingComma, tokens: .close, .break(.same))
    } else {
      after(node.lastToken, tokens: .close)
    }
    return .visitChildren
  }

  func visit(_ node: ClosureExprSyntax) -> SyntaxVisitorContinueKind {
    if let signature = node.signature {
      before(signature.firstToken, tokens: .break(.open))
      if node.statements.count > 0 {
        after(signature.inTok, tokens: .newline)
      } else {
        after(signature.inTok, tokens: .break(.same, size: 0))
      }
      before(node.rightBrace, tokens: .break(.close))
    } else {
      // Closures without signatures can have their contents laid out identically to any other
      // braced structure. The leading reset is skipped because the layout depends on whether it is
      // a trailing closure of a function call (in which case that function call supplies the reset)
      // or part of some other expression (where we want that expression's same/continue behavior to
      // apply).
      arrangeBracesAndContents(
        of: node, contentsKeyPath: \.statements, shouldResetBeforeLeftBrace: false)
    }
    return .visitChildren
  }

  func visit(_ node: ClosureParamSyntax) -> SyntaxVisitorContinueKind {
    after(node.trailingComma, tokens: .break(.same))
    return .visitChildren
  }

  func visit(_ node: ClosureSignatureSyntax) -> SyntaxVisitorContinueKind {
    let consistency: GroupBreakStyle
    if node.input is ClosureParamListSyntax {
      consistency = argumentListConsistency()
    } else {
      consistency = .inconsistent
    }

    before(node.firstToken, tokens: .open)

    if let input = node.input {
      // We unconditionally put a break before the `in` keyword below, so we should only put a break
      // after the capture list's right bracket if there are arguments following it or we'll end up
      // with an extra space if the line doesn't wrap.
      after(node.capture?.rightSquare, tokens: .break(.same))
      before(input.firstToken, tokens: .open(consistency))
      after(input.lastToken, tokens: .close)
    }

    before(node.throwsTok, tokens: .break)
    before(node.output?.arrow, tokens: .break)
    after(node.lastToken, tokens: .close)
    before(node.inTok, tokens: .break(.same))
    return .visitChildren
  }

  func visit(_ node: ClosureCaptureSignatureSyntax) -> SyntaxVisitorContinueKind {
    after(node.leftSquare, tokens: .break(.open, size: 0), .open)
    before(node.rightSquare, tokens: .break(.close, size: 0), .close)
    return .visitChildren
  }

  func visit(_ node: ClosureCaptureItemSyntax) -> SyntaxVisitorContinueKind {
    before(node.firstToken, tokens: .open)
    after(node.specifier?.lastToken, tokens: .break)
    before(node.assignToken, tokens: .break)
    after(node.assignToken, tokens: .break)
    if let trailingComma = node.trailingComma {
      before(trailingComma, tokens: .close)
      after(trailingComma, tokens: .break(.same))
    } else {
      after(node.lastToken, tokens: .close)
    }
    return .visitChildren
  }

  func visit(_ node: SubscriptExprSyntax) -> SyntaxVisitorContinueKind {
    if node.argumentList.count > 0 {
      // If there is a trailing closure, force the right bracket down to the next line so it stays
      // with the open curly brace.
      let breakBeforeRightBracket = node.trailingClosure != nil

      after(node.leftBracket, tokens: .break(.open, size: 0), .open)
      before(
        node.rightBracket,
        tokens: .break(.close(mustBreak: breakBeforeRightBracket), size: 0), .close)
    }
    before(node.trailingClosure?.leftBrace, tokens: .space)
    return .visitChildren
  }

  func visit(_ node: ExpressionSegmentSyntax) -> SyntaxVisitorContinueKind {
    // TODO: For now, just use the raw text of the node and don't try to format it deeper. In the
    // future, we should find a way to format the expression but without wrapping so that at least
    // internal whitespace is fixed.
    appendToken(.syntax(node.description))
    // Visiting children is not needed here.
    return .skipChildren
  }

  func visit(_ node: ObjcKeyPathExprSyntax) -> SyntaxVisitorContinueKind {
    return .visitChildren
  }

  func visit(_ node: AssignmentExprSyntax) -> SyntaxVisitorContinueKind {
    before(node.assignToken, tokens: .break)
    after(node.assignToken, tokens: .space)
    return .visitChildren
  }

  func visit(_ node: ObjectLiteralExprSyntax) -> SyntaxVisitorContinueKind {
    return .visitChildren
  }

  func visit(_ node: ParameterClauseSyntax) -> SyntaxVisitorContinueKind {
    after(node.leftParen, tokens: .break(.open, size: 0), .open(argumentListConsistency()))
    before(node.rightParen, tokens: .break(.close, size: 0), .close)
    return .visitChildren
  }

  func visit(_ node: FunctionParameterSyntax) -> SyntaxVisitorContinueKind {
    before(node.firstToken, tokens: .open)
    after(node.colon, tokens: .break)
    before(node.secondName, tokens: .break)

    if let trailingComma = node.trailingComma {
      after(trailingComma, tokens: .close, .break(.same))
    } else {
      after(node.lastToken, tokens: .close)
    }
    return .visitChildren
  }

  func visit(_ node: ReturnClauseSyntax) -> SyntaxVisitorContinueKind {
    after(node.arrow, tokens: .space)
    return .visitChildren
  }

  func visit(_ node: IfConfigDeclSyntax) -> SyntaxVisitorContinueKind {
    return .visitChildren
  }

  func visit(_ node: IfConfigClauseSyntax) -> SyntaxVisitorContinueKind {
    switch node.poundKeyword.tokenKind {
    case .poundIfKeyword, .poundElseifKeyword:
      after(node.poundKeyword, tokens: .space)
    case .poundElseKeyword:
      break
    default:
      preconditionFailure()
    }

    let tokenToOpenWith = node.condition?.lastToken ?? node.poundKeyword
    after(tokenToOpenWith, tokens: .break(.open), .open)

    // Unlike other code blocks, where we may want a single statement to be laid out on the same
    // line as a parent construct, the content of an `#if` block must always be on its own line;
    // the newline token inserted at the end enforces this.
    if let lastElemTok = node.elements.lastToken {
      after(lastElemTok, tokens: .break(.close), .newline, .close)
    } else {
      before(tokenToOpenWith.nextToken, tokens: .break(.close), .newline, .close)
    }
    return .visitChildren
  }

  func visit(_ node: MemberDeclBlockSyntax) -> SyntaxVisitorContinueKind {
    insertTokens(.break(.reset, size: 0), .newline, betweenElementsOf: node.members)
    return .visitChildren
  }

  func visit(_ node: SourceFileSyntax) -> SyntaxVisitorContinueKind {
    before(node.eofToken, tokens: .newline)
    return .visitChildren
  }

  func visit(_ node: EnumCaseDeclSyntax) -> SyntaxVisitorContinueKind {
    before(node.firstToken, tokens: .open)

    arrangeAttributeList(node.attributes)

    after(node.caseKeyword, tokens: .break)
    after(node.lastToken, tokens: .close)
    return .visitChildren
  }

  func visit(_ node: OperatorDeclSyntax) -> SyntaxVisitorContinueKind {
    return .visitChildren
  }

  func visit(_ node: EnumCaseElementSyntax) -> SyntaxVisitorContinueKind {
    after(node.trailingComma, tokens: .break)
    return .visitChildren
  }

  func visit(_ node: ObjcSelectorExprSyntax) -> SyntaxVisitorContinueKind {
    return .visitChildren
  }

  func visit(_ node: PrecedenceGroupDeclSyntax) -> SyntaxVisitorContinueKind {
    return .visitChildren
  }

  func visit(_ node: PrecedenceGroupRelationSyntax) -> SyntaxVisitorContinueKind {
    return .visitChildren
  }

  func visit(_ node: PrecedenceGroupAssignmentSyntax) -> SyntaxVisitorContinueKind {
    return .visitChildren
  }

  func visit(_ node: PrecedenceGroupNameElementSyntax) -> SyntaxVisitorContinueKind {
    return .visitChildren
  }

  func visit(_ node: PrecedenceGroupAssociativitySyntax) -> SyntaxVisitorContinueKind {
    return .visitChildren
  }

  func visit(_ node: AccessLevelModifierSyntax) -> SyntaxVisitorContinueKind {
    return .visitChildren
  }

  func visit(_ node: CodeBlockSyntax) -> SyntaxVisitorContinueKind {
    return .visitChildren
  }

  func visit(_ node: CodeBlockItemListSyntax) -> SyntaxVisitorContinueKind {
    insertTokens(.break(.reset, size: 0), .newline, betweenElementsOf: node)
    return .visitChildren
  }

  func visit(_ node: CodeBlockItemSyntax) -> SyntaxVisitorContinueKind {
    before(node.firstToken, tokens: .open)
    after(node.lastToken, tokens: .close)
    return .visitChildren
  }

  func visit(_ node: GenericParameterClauseSyntax) -> SyntaxVisitorContinueKind {
    after(node.leftAngleBracket, tokens: .break(.open, size: 0), .open(argumentListConsistency()))
    before(node.rightAngleBracket, tokens: .break(.close, size: 0), .close)
    return .visitChildren
  }

  func visit(_ node: ArrayTypeSyntax) -> SyntaxVisitorContinueKind {
    return .visitChildren
  }

  func visit(_ node: TupleTypeSyntax) -> SyntaxVisitorContinueKind {
    after(node.leftParen, tokens: .break(.open, size: 0), .open)
    before(node.rightParen, tokens: .break(.close, size: 0), .close)
    return .visitChildren
  }

  func visit(_ node: TupleTypeElementSyntax) -> SyntaxVisitorContinueKind {
    before(node.firstToken, tokens: .open)
    after(node.colon, tokens: .break)
    before(node.secondName, tokens: .break)

    if let trailingComma = node.trailingComma {
      after(trailingComma, tokens: .close, .break(.same))
    } else {
      after(node.lastToken, tokens: .close)
    }
    return .visitChildren
  }

  func visit(_ node: FunctionTypeSyntax) -> SyntaxVisitorContinueKind {
    after(node.leftParen, tokens: .break(.open, size: 0), .open)
    before(node.rightParen, tokens: .break(.close, size: 0), .close)
    before(node.throwsOrRethrowsKeyword, tokens: .break)
    before(node.arrow, tokens: .break)
    before(node.returnType.firstToken, tokens: .break)
    return .visitChildren
  }

  func visit(_ node: GenericArgumentClauseSyntax) -> SyntaxVisitorContinueKind {
    after(node.leftAngleBracket, tokens: .break(.open, size: 0), .open)
    before(node.rightAngleBracket, tokens: .break(.close, size: 0), .close)
    return .visitChildren
  }

  func visit(_ node: TuplePatternSyntax) -> SyntaxVisitorContinueKind {
    after(node.leftParen, tokens: .break(.open, size: 0), .open)
    before(node.rightParen, tokens: .break(.close, size: 0), .close)
    return .visitChildren
  }

  func visit(_ node: AsExprSyntax) -> SyntaxVisitorContinueKind {
    before(node.asTok, tokens: .break)
    before(node.typeName.firstToken, tokens: .space)
    return .visitChildren
  }

  func visit(_ node: IsExprSyntax) -> SyntaxVisitorContinueKind {
    before(node.isTok, tokens: .break)
    before(node.typeName.firstToken, tokens: .space)
    return .visitChildren
  }

  func visit(_ node: TryExprSyntax) -> SyntaxVisitorContinueKind {
    before(node.expression.firstToken, tokens: .break)
    return .visitChildren
  }

  func visit(_ node: TypeExprSyntax) -> SyntaxVisitorContinueKind {
    return .visitChildren
  }

  func visit(_ node: ArrowExprSyntax) -> SyntaxVisitorContinueKind {
    before(node.throwsToken, tokens: .break)
    before(node.arrowToken, tokens: .break)
    after(node.arrowToken, tokens: .space)
    return .visitChildren
  }

  func handleAvailabilitySpec(leftParen: TokenSyntax?, spec: Syntax, rightParen: TokenSyntax?) {
    var tokens: [TokenSyntax] = []
    if let leftParen = leftParen {
      tokens.append(leftParen)
    }
    spec.tokens.forEach { tokens.append($0) }
    if let rightParen = rightParen {
      tokens.append(rightParen)
    }

    for i in 0..<(tokens.count - 1) {
      switch (tokens[i].tokenKind, tokens[i+1].tokenKind) {
      case (.leftParen, _): ()
      case (_, .rightParen): ()
      case (_, .comma): ()
      case (_, .colon): ()
      default:
        after(tokens[i], tokens: .space)
      }
    }
  }

  func visit(_ node: AttributeSyntax) -> SyntaxVisitorContinueKind {
    if let argument = node.argument {
      handleAvailabilitySpec(leftParen: node.leftParen, spec: argument, rightParen: node.rightParen)
    }
    return .visitChildren
  }

  func visit(_ node: ElseBlockSyntax) -> SyntaxVisitorContinueKind {
    return .visitChildren
  }

  func visit(_ node: ConditionElementSyntax) -> SyntaxVisitorContinueKind {
    before(node.firstToken, tokens: .open)
    if let comma = node.trailingComma {
      after(comma, tokens: .close, .break)
    } else {
      after(node.lastToken, tokens: .close)
    }
    return .visitChildren
  }

  func visit(_ node: InOutExprSyntax) -> SyntaxVisitorContinueKind {
    return .visitChildren
  }

  func visit(_ node: ImportDeclSyntax) -> SyntaxVisitorContinueKind {
    after(node.attributes?.lastToken, tokens: .space)
    after(node.importTok, tokens: .space)
    after(node.importKind, tokens: .space)
    return .visitChildren
  }

  func visit(_ node: KeyPathExprSyntax) -> SyntaxVisitorContinueKind {
    return .visitChildren
  }

  func visit(_ node: TernaryExprSyntax) -> SyntaxVisitorContinueKind {
    before(node.questionMark, tokens: .break, .open)
    after(node.questionMark, tokens: .space)
    before(node.colonMark, tokens: .break)
    after(node.colonMark, tokens: .space)
    after(node.secondChoice.lastToken, tokens: .close)
    return .visitChildren
  }

  func visit(_ node: WhereClauseSyntax) -> SyntaxVisitorContinueKind {
    // We need to special case `where`-clauses associated with `catch` blocks when
    // `lineBreakBeforeControlFlowKeywords == false`, because that's the one situation where we
    // want the `where` keyword to be treated as a continuation; that way, we get this:
    //
    //     } catch LongExceptionName
    //       where longCondition
    //     {
    //       ...
    //     }
    //
    // instead of this:
    //
    //     } catch LongExceptionName
    //     where longCondition {
    //       ...
    //     }
    //
    let wherePrecedingBreak: Token
    if !config.lineBreakBeforeControlFlowKeywords && node.parent is CatchClauseSyntax {
      wherePrecedingBreak = .break(.continue)
    } else {
      wherePrecedingBreak = .break(.same)
    }
    before(node.whereKeyword, tokens: wherePrecedingBreak, .open)
    after(node.whereKeyword, tokens: .break)
    after(node.lastToken, tokens: .close)
    return .visitChildren
  }

  func visit(_ node: DeclModifierSyntax) -> SyntaxVisitorContinueKind {
    after(node.lastToken, tokens: .break)
    return .visitChildren
  }

  func visit(_ node: FunctionSignatureSyntax) -> SyntaxVisitorContinueKind {
    before(node.throwsOrRethrowsKeyword, tokens: .break)
    before(node.output?.firstToken, tokens: .break)
    return .visitChildren
  }

  func visit(_ node: MetatypeTypeSyntax) -> SyntaxVisitorContinueKind {
    return .visitChildren
  }

  func visit(_ node: OptionalTypeSyntax) -> SyntaxVisitorContinueKind {
    return .visitChildren
  }

  func visit(_ node: SequenceExprSyntax) -> SyntaxVisitorContinueKind {
    return .visitChildren
  }

  func visit(_ node: SuperRefExprSyntax) -> SyntaxVisitorContinueKind {
    return .visitChildren
  }

  func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
    arrangeAttributeList(node.attributes)
    after(node.letOrVarKeyword, tokens: .space)
    return .visitChildren
  }

  func visit(_ node: AsTypePatternSyntax) -> SyntaxVisitorContinueKind {
    return .visitChildren
  }

  func visit(_ node: InheritedTypeSyntax) -> SyntaxVisitorContinueKind {
    after(node.trailingComma, tokens: .break(.same))
    return .visitChildren
  }

  func visit(_ node: IsTypePatternSyntax) -> SyntaxVisitorContinueKind {
    after(node.isKeyword, tokens: .space)
    return .visitChildren
  }

  func visit(_ node: ObjcNamePieceSyntax) -> SyntaxVisitorContinueKind {
    return .visitChildren
  }

  func visit(_ node: PoundFileExprSyntax) -> SyntaxVisitorContinueKind {
    return .visitChildren
  }

  func visit(_ node: PoundLineExprSyntax) -> SyntaxVisitorContinueKind {
    return .visitChildren
  }

  func visit(_ node: StringSegmentSyntax) -> SyntaxVisitorContinueKind {
    return .visitChildren
  }

  func visit(_ node: TypealiasDeclSyntax) -> SyntaxVisitorContinueKind {
    arrangeAttributeList(node.attributes)

    after(node.typealiasKeyword, tokens: .break)

    if let genericWhereClause = node.genericWhereClause {
      before(genericWhereClause.firstToken, tokens: .break(.same), .open)
      after(node.lastToken, tokens: .close)
    }
    return .visitChildren
  }

  func visit(_ node: TypeInitializerClauseSyntax) -> SyntaxVisitorContinueKind {
    before(node.equal, tokens: .break)
    after(node.equal, tokens: .space)
    return .visitChildren
  }

  func visit(_ node: AttributedTypeSyntax) -> SyntaxVisitorContinueKind {
    arrangeAttributeList(node.attributes)
    after(node.specifier, tokens: .break)
    return .visitChildren
  }

  func visit(_ node: ExpressionStmtSyntax) -> SyntaxVisitorContinueKind {
    return .visitChildren
  }

  func visit(_ node: IdentifierExprSyntax) -> SyntaxVisitorContinueKind {
    return .visitChildren
  }

  func visit(_ node: NilLiteralExprSyntax) -> SyntaxVisitorContinueKind {
    return .visitChildren
  }

  func visit(_ node: PatternBindingSyntax) -> SyntaxVisitorContinueKind {
    if let accessorOrCodeBlock = node.accessor {
      arrangeAccessorOrCodeBlock(accessorOrCodeBlock)
    }
    return .visitChildren
  }

  func visit(_ node: PoundErrorDeclSyntax) -> SyntaxVisitorContinueKind {
    return .visitChildren
  }

  func visit(_ node: SpecializeExprSyntax) -> SyntaxVisitorContinueKind {
    return .visitChildren
  }

  func visit(_ node: TypeAnnotationSyntax) -> SyntaxVisitorContinueKind {
    after(node.colon, tokens: .break, .open)
    after(node.lastToken, tokens: .close)
    return .visitChildren
  }

  func visit(_ node: UnknownPatternSyntax) -> SyntaxVisitorContinueKind {
    return .visitChildren
  }

  func visit(_ node: CompositionTypeSyntax) -> SyntaxVisitorContinueKind {
    return .visitChildren
  }

  func visit(_ node: DeclarationStmtSyntax) -> SyntaxVisitorContinueKind {
    return .visitChildren
  }

  func visit(_ node: EnumCasePatternSyntax) -> SyntaxVisitorContinueKind {
    return .visitChildren
  }

  func visit(_ node: FallthroughStmtSyntax) -> SyntaxVisitorContinueKind {
    return .visitChildren
  }

  func visit(_ node: ForcedValueExprSyntax) -> SyntaxVisitorContinueKind {
    return .visitChildren
  }

  func visit(_ node: GenericArgumentSyntax) -> SyntaxVisitorContinueKind {
    before(node.firstToken, tokens: .open)
    if let trailingComma = node.trailingComma {
      after(trailingComma, tokens: .close, .break(.same))
    } else {
      after(node.lastToken, tokens: .close)
    }
    return .visitChildren
  }

  func visit(_ node: OptionalPatternSyntax) -> SyntaxVisitorContinueKind {
    return .visitChildren
  }

  func visit(_ node: PoundColumnExprSyntax) -> SyntaxVisitorContinueKind {
    return .visitChildren
  }

  func visit(_ node: WildcardPatternSyntax) -> SyntaxVisitorContinueKind {
    return .visitChildren
  }

  func visit(_ node: DeclNameArgumentSyntax) -> SyntaxVisitorContinueKind {
    return .visitChildren
  }

  func visit(_ node: FloatLiteralExprSyntax) -> SyntaxVisitorContinueKind {
    return .visitChildren
  }

  func visit(_ node: GenericParameterSyntax) -> SyntaxVisitorContinueKind {
    before(node.firstToken, tokens: .open)
    after(node.colon, tokens: .break)
    if let trailingComma = node.trailingComma {
      after(trailingComma, tokens: .close, .break(.same))
    } else {
      after(node.lastToken, tokens: .close)
    }
    return .visitChildren
  }

  func visit(_ node: PostfixUnaryExprSyntax) -> SyntaxVisitorContinueKind {
    return .visitChildren
  }

  func visit(_ node: PoundWarningDeclSyntax) -> SyntaxVisitorContinueKind {
    return .visitChildren
  }

  func visit(_ node: ExpressionPatternSyntax) -> SyntaxVisitorContinueKind {
    return .visitChildren
  }

  func visit(_ node: ValueBindingPatternSyntax) -> SyntaxVisitorContinueKind {
    after(node.letOrVarKeyword, tokens: .break)
    return .visitChildren
  }

  func visit(_ node: IdentifierPatternSyntax) -> SyntaxVisitorContinueKind {
    return .visitChildren
  }

  func visit(_ node: InitializerClauseSyntax) -> SyntaxVisitorContinueKind {
    before(node.equal, tokens: .break)
    after(node.equal, tokens: .space)
    return .visitChildren
  }

  func visit(_ node: PoundFunctionExprSyntax) -> SyntaxVisitorContinueKind {
    return .visitChildren
  }

  func visit(_ node: StringLiteralExprSyntax) -> SyntaxVisitorContinueKind {
    return .visitChildren
  }

  func visit(_ node: AssociatedtypeDeclSyntax) -> SyntaxVisitorContinueKind {
    arrangeAttributeList(node.attributes)

    after(node.associatedtypeKeyword, tokens: .break)

    if let genericWhereClause = node.genericWhereClause {
      before(genericWhereClause.firstToken, tokens: .break(.same), .open)
      after(node.lastToken, tokens: .close)
    }
    return .visitChildren
  }

  func visit(_ node: BooleanLiteralExprSyntax) -> SyntaxVisitorContinueKind {
    return .visitChildren
  }

  func visit(_ node: ElseIfContinuationSyntax) -> SyntaxVisitorContinueKind {
    return .visitChildren
  }

  func visit(_ node: GenericWhereClauseSyntax) -> SyntaxVisitorContinueKind {
    after(node.whereKeyword, tokens: .break(.open))
    after(node.lastToken, tokens: .break(.close, size: 0))
    return .visitChildren
  }

  func visit(_ node: IntegerLiteralExprSyntax) -> SyntaxVisitorContinueKind {
    return .visitChildren
  }

  func visit(_ node: PoundDsohandleExprSyntax) -> SyntaxVisitorContinueKind {
    return .visitChildren
  }

  func visit(_ node: PrefixOperatorExprSyntax) -> SyntaxVisitorContinueKind {
    return .visitChildren
  }

  func visit(_ node: AccessPathComponentSyntax) -> SyntaxVisitorContinueKind {
    return .visitChildren
  }

  func visit(_ node: SameTypeRequirementSyntax) -> SyntaxVisitorContinueKind {
    before(node.firstToken, tokens: .open)
    before(node.equalityToken, tokens: .break)
    after(node.equalityToken, tokens: .space)
    if let trailingComma = node.trailingComma {
      after(trailingComma, tokens: .close, .break(.same))
    } else {
      after(node.lastToken, tokens: .close)
    }
    return .visitChildren
  }

  func visit(_ node: TuplePatternElementSyntax) -> SyntaxVisitorContinueKind {
    after(node.trailingComma, tokens: .break(.same))
    return .visitChildren
  }

  func visit(_ node: MemberTypeIdentifierSyntax) -> SyntaxVisitorContinueKind {
    return .visitChildren
  }

  func visit(_ node: OptionalChainingExprSyntax) -> SyntaxVisitorContinueKind {
    return .visitChildren
  }

  func visit(_ node: SimpleTypeIdentifierSyntax) -> SyntaxVisitorContinueKind {
    return .visitChildren
  }

  func visit(_ node: AvailabilityConditionSyntax) -> SyntaxVisitorContinueKind {
    handleAvailabilitySpec(
      leftParen: node.leftParen,
      spec: node.availabilitySpec,
      rightParen: node.rightParen)
    return .visitChildren
  }

  func visit(_ node: DiscardAssignmentExprSyntax) -> SyntaxVisitorContinueKind {
    return .visitChildren
  }

  func visit(_ node: EditorPlaceholderExprSyntax) -> SyntaxVisitorContinueKind {
    return .visitChildren
  }

  func visit(_ node: SymbolicReferenceExprSyntax) -> SyntaxVisitorContinueKind {
    return .visitChildren
  }

  func visit(_ node: TypeInheritanceClauseSyntax) -> SyntaxVisitorContinueKind {
    after(node.colon, tokens: .break(.open, size: 1))
    before(node.inheritedTypeCollection.firstToken, tokens: .open)
    after(node.inheritedTypeCollection.lastToken, tokens: .close)
    after(node.lastToken, tokens: .break(.close, size: 0))
    return .visitChildren
  }

  func visit(_ node: UnresolvedPatternExprSyntax) -> SyntaxVisitorContinueKind {
    return .visitChildren
  }

  func visit(_ node: CompositionTypeElementSyntax) -> SyntaxVisitorContinueKind {
    before(node.ampersand, tokens: .break)
    after(node.ampersand, tokens: .space)
    return .visitChildren
  }

  func visit(_ node: ConformanceRequirementSyntax) -> SyntaxVisitorContinueKind {
    before(node.firstToken, tokens: .open)
    after(node.colon, tokens: .break)

    if let trailingComma = node.trailingComma {
      after(trailingComma, tokens: .close, .break(.same))
    } else {
      after(node.lastToken, tokens: .close)
    }

    return .visitChildren
  }

  func visit(_ node: MatchingPatternConditionSyntax) -> SyntaxVisitorContinueKind {
    before(node.firstToken, tokens: .open)
    after(node.caseKeyword, tokens: .break)
    after(node.lastToken, tokens: .close)
    return .visitChildren
  }

  func visit(_ node: OptionalBindingConditionSyntax) -> SyntaxVisitorContinueKind {
    after(node.letOrVarKeyword, tokens: .break)
    return .visitChildren
  }

  func visit(_ node: ImplicitlyUnwrappedOptionalTypeSyntax) -> SyntaxVisitorContinueKind {
    return .visitChildren
  }

  func visit(_ node: UnknownDeclSyntax) -> SyntaxVisitorContinueKind {
    verbatimToken(node)
    // Visiting children is not needed here.
    return .skipChildren
  }

  func visit(_ node: UnknownStmtSyntax) -> SyntaxVisitorContinueKind {
    verbatimToken(node)
    // Visiting children is not needed here.
    return .skipChildren
  }

  func visit(_ token: TokenSyntax) -> SyntaxVisitorContinueKind {
    extractLeadingTrivia(token)
    appendBeforeTokens(token)

    let text: String
    if token.leadingTrivia.hasBackticks && token.trailingTrivia.hasBackticks {
      text = "`\(token.text)`"
    } else {
      text = token.text
    }
    appendToken(.syntax(text))

    appendAfterTokensAndTrailingComments(token)

    // It doesn't matter what we return here, tokens do not have children.
    return .skipChildren
  }

  /// Appends the before-tokens of the given syntax token to the token stream.
  private func appendBeforeTokens(_ token: TokenSyntax) {
    if let before = beforeMap[token] {
      before.forEach(appendToken)
    }
  }

  /// Appends the after-tokens and trailing comments (if present) of the given syntax token
  /// to the token stream.
  ///
  /// After-tokens require special care because the location of trailing comments (being in the
  /// trivia of the *next* token) sometimes can interfere with the ordering of formatting tokens
  /// being enqueued during visitation. Specifically:
  ///
  /// * If the trailing comment is a block comment, we append it first to the stream before any
  ///   other formatting tokens. This keeps the comment closely bound to the syntax token
  ///   preceding it; for example, if the comment occurs after the last token in a group, it
  ///   will stay inside the group.
  ///
  /// * If the trailing comment is a line comment, we first append any enqueued after-tokens
  ///   that are *not* breaks or newlines, then we append the comment, and then the remaining
  ///   after-tokens. Due to visitation ordering, this ensures that a trailing line comment is
  ///   not incorrectly inserted into the token stream *after* a break or newline.
  private func appendAfterTokensAndTrailingComments(_ token: TokenSyntax) {
    let (wasLineComment, trailingCommentTokens) = afterTokensForTrailingComment(token)
    let afterGroups = afterMap[token] ?? []
    var hasAppendedTrailingComment = false

    if !wasLineComment {
      trailingCommentTokens.forEach(appendToken)
    }

    for after in afterGroups.reversed() {
      after.forEach { afterToken in
        var shouldExtractTrailingComment = false
        if wasLineComment && !hasAppendedTrailingComment {
          switch afterToken {
          case .break, .newlines: shouldExtractTrailingComment = true
          default: break
          }
        }
        if shouldExtractTrailingComment {
          trailingCommentTokens.forEach(appendToken)
          hasAppendedTrailingComment = true
        }
        appendToken(afterToken)
      }
    }

    if wasLineComment && !hasAppendedTrailingComment {
      trailingCommentTokens.forEach(appendToken)
    }
  }

  // MARK: - Various other helper methods

  /// Applies formatting tokens around and between the attributes in an attribute list.
  private func arrangeAttributeList(_ attributes: AttributeListSyntax?) {
    if let attributes = attributes {
      before(attributes.firstToken, tokens: .open)
      insertTokens(.break(.same), betweenElementsOf: attributes)
      after(attributes.lastToken, tokens: .close, .break(.same))
    }
  }

  /// Returns a value indicating whether or not the given braced syntax node is completely empty;
  /// that is, it contains neither child syntax nodes (aside from the braces) *nor* any comments.
  ///
  /// Checking for comments separately is vitally important, because a code block that appears to be
  /// "empty" because it doesn't contain any statements might still contain comments, and if those
  /// are line comments, we need to make sure to insert the same breaks that we would if there were
  /// other statements there to get the same layout.
  ///
  /// Note the slightly different generic constraints on this and the other overloads. All are
  /// required because protocols in Swift do not conform to themselves, so if the element type of
  /// the collection is *precisely* `Syntax`, the constraint `BodyContents.Element: Syntax` is not
  /// satisfied and we must constrain it by `BodyContents.Element == Syntax` instead.
  ///
  /// - Parameters:
  ///   - node: A node that conforms to `BracedSyntax`.
  ///   - contentsKeyPath: A keypath describing how to get from `node` to the contents of the node
  ///     (a `Collection` whose elements are of a type that conforms to `Syntax`).
  /// - Returns: True if the collection at the node's keypath is empty and there are no comments.
  private func areBracesCompletelyEmpty<Node: BracedSyntax, BodyContents: SyntaxCollection>(
    _ node: Node,
    contentsKeyPath: KeyPath<Node, BodyContents>
  ) -> Bool where BodyContents.Element: Syntax {
    // If the collection is empty, then any comments that might be present in the block must be
    // leading trivia of the right brace.
    let commentPrecedesRightBrace = node.rightBrace.leadingTrivia.numberOfComments > 0
    // We can't use `count` here because it also includes missing children. Instead, we get an
    // iterator and check if it returns `nil` immediately.
    var contentsIterator = node[keyPath: contentsKeyPath].makeIterator()
    return contentsIterator.next() == nil && !commentPrecedesRightBrace
  }

  /// Returns a value indicating whether or not the given braced syntax node is completely empty;
  /// that is, it contains neither child syntax nodes (aside from the braces) *nor* any comments.
  ///
  /// - Parameters:
  ///   - node: A node that conforms to `BracedSyntax`.
  ///   - contentsKeyPath: A keypath describing how to get from `node` to the contents of the node
  ///     (a `Collection` whose elements are of type `Syntax`).
  /// - Returns: True if the collection at the node's keypath is empty and there are no comments.
  private func areBracesCompletelyEmpty<Node: BracedSyntax, BodyContents: SyntaxCollection>(
    _ node: Node,
    contentsKeyPath: KeyPath<Node, BodyContents>
  ) -> Bool where BodyContents.Element == Syntax {
    // If the collection is empty, then any comments that might be present in the block must be
    // leading trivia of the right brace.
    let commentPrecedesRightBrace = node.rightBrace.leadingTrivia.numberOfComments > 0
    // We can't use `count` here because it also includes missing children. Instead, we get an
    // iterator and check if it returns `nil` immediately.
    var contentsIterator = node[keyPath: contentsKeyPath].makeIterator()
    return contentsIterator.next() == nil && !commentPrecedesRightBrace
  }

  /// Returns a value indicating whether or not the given braced syntax node is completely empty;
  /// that is, it contains neither child syntax nodes (aside from the braces) *nor* any comments.
  ///
  /// - Parameters:
  ///   - node: A node that conforms to `BracedSyntax`.
  ///   - contentsKeyPath: A keypath describing how to get from `node` to the contents of the node
  ///     (a `Collection` whose elements are of type `DeclSyntax`).
  /// - Returns: True if the collection at the node's keypath is empty and there are no comments.
  private func areBracesCompletelyEmpty<Node: BracedSyntax, BodyContents: SyntaxCollection>(
    _ node: Node,
    contentsKeyPath: KeyPath<Node, BodyContents>
  ) -> Bool where BodyContents.Element == DeclSyntax {
    // If the collection is empty, then any comments that might be present in the block must be
    // leading trivia of the right brace.
    let commentPrecedesRightBrace = node.rightBrace.leadingTrivia.numberOfComments > 0
    // We can't use `count` here because it also includes missing children. Instead, we get an
    // iterator and check if it returns `nil` immediately.
    var contentsIterator = node[keyPath: contentsKeyPath].makeIterator()
    return contentsIterator.next() == nil && !commentPrecedesRightBrace
  }

  /// Applies consistent formatting to the braces and contents of the given node.
  ///
  /// - Parameters:
  ///   - node: A node that conforms to `BracedSyntax`.
  ///   - contentsKeyPath: A keypath describing how to get from `node` to the contents of the node
  ///     (a `Collection` whose elements are of a type that conforms to `Syntax`).
  ///   - shouldResetBeforeLeftBrace: If true, a `reset` break will be inserted before the node's
  ///     left brace (the default behavior). Passing false will suppress this break, which is useful
  ///     if you have already placed a `reset` elsewhere (for example, in a `guard` statement, the
  ///     `reset` is inserted before the `else` keyword to force both it and the brace down to the
  ///     next line).
  private func arrangeBracesAndContents<Node: BracedSyntax, BodyContents: SyntaxCollection>(
    of node: Node?,
    contentsKeyPath: KeyPath<Node, BodyContents>?,
    shouldResetBeforeLeftBrace: Bool = true
  ) where BodyContents.Element: Syntax {
    guard let node = node, let contentsKeyPath = contentsKeyPath else { return }

    if shouldResetBeforeLeftBrace {
      before(node.leftBrace, tokens: .break(.reset, size: 1, ignoresDiscretionary: true))
    }
    if !areBracesCompletelyEmpty(node, contentsKeyPath: contentsKeyPath) {
      after(node.leftBrace, tokens: .break(.open, size: 1), .open)
      before(node.rightBrace, tokens: .break(.close, size: 1), .close)
    } else {
      before(node.rightBrace, tokens: .break(.same, size: 0))
    }
  }

  /// Applies consistent formatting to the braces and contents of the given node.
  ///
  /// - Parameters:
  ///   - node: A node that conforms to `BracedSyntax`.
  ///   - contentsKeyPath: A keypath describing how to get from `node` to the contents of the node
  ///     (a `Collection` whose elements are of type `Syntax`).
  ///   - shouldResetBeforeLeftBrace: If true, a `reset` break will be inserted before the node's
  ///     left brace (the default behavior). Passing false will suppress this break, which is useful
  ///     if you have already placed a `reset` elsewhere (for example, in a `guard` statement, the
  ///     `reset` is inserted before the `else` keyword to force both it and the brace down to the
  ///     next line).
  private func arrangeBracesAndContents<Node: BracedSyntax, BodyContents: SyntaxCollection>(
    of node: Node?,
    contentsKeyPath: KeyPath<Node, BodyContents>?,
    shouldResetBeforeLeftBrace: Bool = true
  ) where BodyContents.Element == Syntax {
    guard let node = node, let contentsKeyPath = contentsKeyPath else { return }

    if shouldResetBeforeLeftBrace {
      before(node.leftBrace, tokens: .break(.reset, size: 1))
    }
    if !areBracesCompletelyEmpty(node, contentsKeyPath: contentsKeyPath) {
      after(node.leftBrace, tokens: .break(.open, size: 1), .open)
      before(node.rightBrace, tokens: .break(.close, size: 1), .close)
    } else {
      before(node.rightBrace, tokens: .break(.same, size: 0))
    }
  }

  /// Applies consistent formatting to the braces and contents of the given node.
  ///
  /// - Parameters:
  ///   - node: A node that conforms to `BracedSyntax`.
  ///   - contentsKeyPath: A keypath describing how to get from `node` to the contents of the node
  ///     (a `Collection` whose elements are of type `DeclSyntax`).
  ///   - shouldResetBeforeLeftBrace: If true, a `reset` break will be inserted before the node's
  ///     left brace (the default behavior). Passing false will suppress this break, which is useful
  ///     if you have already placed a `reset` elsewhere (for example, in a `guard` statement, the
  ///     `reset` is inserted before the `else` keyword to force both it and the brace down to the
  ///     next line).
  private func arrangeBracesAndContents<Node: BracedSyntax, BodyContents: SyntaxCollection>(
    of node: Node?,
    contentsKeyPath: KeyPath<Node, BodyContents>?,
    shouldResetBeforeLeftBrace: Bool = true
  ) where BodyContents.Element == DeclSyntax {
    guard let node = node, let contentsKeyPath = contentsKeyPath else { return }

    if shouldResetBeforeLeftBrace {
      before(node.leftBrace, tokens: .break(.reset, size: 1))
    }
    if !areBracesCompletelyEmpty(node, contentsKeyPath: contentsKeyPath) {
      after(node.leftBrace, tokens: .break(.open, size: 1), .open)
      before(node.rightBrace, tokens: .break(.close, size: 1), .close)
    } else {
      before(node.rightBrace, tokens: .break(.same, size: 0))
    }
  }

  /// Applies consistent formatting to the braces and contents of the given node.
  ///
  /// - Parameter node: An `AccessorBlockSyntax` node.
  private func arrangeBracesAndContents(of node: AccessorBlockSyntax) {
    // If the collection is empty, then any comments that might be present in the block must be
    // leading trivia of the right brace.
    let commentPrecedesRightBrace = node.rightBrace.leadingTrivia.numberOfComments > 0
    // We can't use `count` here because it also includes missing children. Instead, we get an
    // iterator and check if it returns `nil` immediately.
    var accessorsIterator = node.accessors.makeIterator()
    let areAccessorsEmpty = accessorsIterator.next() == nil
    let bracesAreCompletelyEmpty = areAccessorsEmpty && !commentPrecedesRightBrace

    before(node.leftBrace, tokens: .break(.reset, size: 1))

    if !bracesAreCompletelyEmpty {
      after(node.leftBrace, tokens: .break(.open, size: 1), .open)
      before(node.rightBrace, tokens: .break(.close, size: 1), .close)
    } else {
      before(node.rightBrace, tokens: .break(.same, size: 0))
    }
  }

  /// Returns the group consistency that should be used for argument lists based on the user's
  /// current configuration.
  private func argumentListConsistency() -> GroupBreakStyle {
    return config.lineBreakBeforeEachArgument ? .consistent : .inconsistent
  }

  private func afterTokensForTrailingComment(_ token: TokenSyntax)
    -> (isLineComment: Bool, tokens: [Token])
  {
    let nextToken = token.nextToken
    guard let trivia = nextToken?.leadingTrivia,
      let firstPiece = trivia[safe: 0]
    else {
      return (false, [])
    }

    let position = token.endPosition

    switch firstPiece {
    case .lineComment(let text):
      var tokens: [Token] = [
        .space(size: 2, flexible: true),
        .comment(Comment(kind: .line, text: text, position: position), wasEndOfLine: true),
      ]
      // If the configuration says to respect existing line breaks, then we'll already be
      // appending one elsewhere because there *must* be a line break present in the source
      // for this to be a trailing line comment. Otherwise, we'll need to append one
      // ourselves to ensure that it's present.
      if !config.respectsExistingLineBreaks {
        tokens.append(.newline)
      }
      return (true, tokens)

    case .blockComment(let text):
      return (
        false,
        [
          .space(size: 1, flexible: true),
          .comment(Comment(kind: .block, text: text, position: position), wasEndOfLine: false),
          // We place a size-0 break after the comment to allow a discretionary newline after
          // the comment if the user places one here but the comment is otherwise adjacent to a
          // text token.
          .break(.same, size: 0),
        ]
      )

    default:
      return (false, [])
    }
  }

  private func extractLeadingTrivia(_ token: TokenSyntax) {
    var isStartOfFile = token.previousToken == nil
    let trivia = token.leadingTrivia

    // If we're at the end of the file, determine at which index to stop checking trivia pieces to
    // prevent trailing newlines.
    var cutoffIndex: Int? = nil
    if token.tokenKind == TokenKind.eof {
      cutoffIndex = 0
      for (index, piece) in trivia.enumerated() {
        switch piece {
        case .newlines(_), .carriageReturns(_), .carriageReturnLineFeeds(_):
          continue
        default:
          cutoffIndex = index + 1
        }
      }
    }

    var lastPieceWasLineComment = false
    for (index, piece) in trivia.enumerated() {
      if let cutoff = cutoffIndex, index == cutoff { break }
      switch piece {
      case .lineComment(let text):
        if index > 0 || isStartOfFile {
          appendToken(.comment(Comment(kind: .line, text: text), wasEndOfLine: false))
          appendToken(.newline)
          isStartOfFile = false
        }
        lastPieceWasLineComment = true

      case .blockComment(let text):
        if index > 0 || isStartOfFile {
          appendToken(.comment(Comment(kind: .block, text: text), wasEndOfLine: false))
          // We place a size-0 break after the comment to allow a discretionary newline after the
          // comment if the user places one here but the comment is otherwise adjacent to a text
          // token.
          appendToken(.break(.same, size: 0))
          isStartOfFile = false
        }
        lastPieceWasLineComment = false

      case .docLineComment(let text):
        appendToken(.comment(Comment(kind: .docLine, text: text), wasEndOfLine: false))
        appendToken(.newline)
        isStartOfFile = false
        lastPieceWasLineComment = true

      case .docBlockComment(let text):
        appendToken(.comment(Comment(kind: .docBlock, text: text), wasEndOfLine: false))
        appendToken(.newline)
        isStartOfFile = false
        lastPieceWasLineComment = false

      case .newlines(let count), .carriageReturns(let count), .carriageReturnLineFeeds(let count):
        guard !isStartOfFile else { break }
        if config.respectsExistingLineBreaks
          && (lastPieceWasLineComment || isDiscretionaryNewlineAllowed(before: token))
        {
          appendToken(.newlines(count, discretionary: true))
        } else {
          // Even if discretionary line breaks are not being respected, we still respect multiple
          // line breaks in order to keep blank separator lines that the user might want.
          // TODO: It would be nice to restrict this to only allow multiple lines between statements
          // and declarations; as currently implemented, multiple newlines will locally the
          // configuration setting.
          if count > 1 {
            appendToken(.newlines(count, discretionary: true))
          }
        }

      default:
        break
      }
    }
  }

  /// Returns a value indicating whether or not discretionary newlines are permitted before the
  /// given syntax token.
  ///
  /// Discretionary newlines are allowed before any token (ignoring open/close group tokens, which
  /// do not contribute to this) that is preceded by an existing newline or that is preceded by a
  /// break whose `ignoresDiscretionary` property is false. In other words, this means that users
  /// may insert their own breaks in places where the pretty printer allows them, even if those
  /// breaks wouldn't cause wrapping based on the column limit, but they may not place them in
  /// places where the pretty printer would not break (for example, at a space token that is
  /// intended to keep two tokens glued together).
  ///
  /// Furthermore, breaks with `ignoresDiscretionary` equal to `true` are in effect "last resort"
  /// breaks; a user's newline will be discarded unless the algorithm *must* break there. For
  /// example, an open curly brace on a non-continuation line should always be kept on the same line
  /// as the tokens before it unless the tokens before it are exactly the length of the line and a
  /// break must be inserted there to prevent the brace from going over the limit.
  private func isDiscretionaryNewlineAllowed(before token: TokenSyntax) -> Bool {
    func isBreakMoreRecentThanNonbreakingContent(_ tokens: [Token]) -> Bool? {
      for token in tokens.reversed() as ReversedCollection {
        switch token {
        case .newlines: return true
        case .break(_, _, let ignoresDiscretionary): return !ignoresDiscretionary
        case .comment, .space, .syntax, .verbatim: return false
        default: break
        }
      }
      return nil
    }

    // First, check the pretty printer tokens that will be added before the text token. If we find
    // a break or newline before we find some other text, we allow a discretionary newline. If we
    // find some other content, we don't allow it.
    //
    // If there were no before tokens, then we do the same check the token stream created thus far,
    // returning true if there were no tokens at all in the stream (which would mean there was a
    // discretionary newline at the beginning of the file).
    if let beforeTokens = beforeMap[token],
      let foundBreakFirst = isBreakMoreRecentThanNonbreakingContent(beforeTokens)
    {
      return foundBreakFirst
    }
    return isBreakMoreRecentThanNonbreakingContent(tokens) ?? true
  }

  /// Appends a formatting token to the token stream.
  ///
  /// This function also handles collapsing neighboring tokens in situations where that is
  /// desired, like merging adjacent comments and newlines.
  private func appendToken(_ token: Token) {
    if let last = tokens.last {
      switch (last, token) {
      case (.comment(let c1, _), .comment(let c2, _))
      where c1.kind == .docLine && c2.kind == .docLine:
        var newComment = c1
        newComment.addText(c2.text)
        tokens[tokens.count - 1] = .comment(newComment, wasEndOfLine: false)
        return

      // If we see a pair of newlines where one is required and one is not, keep only the required
      // one.
      case (.newlines(_, discretionary: false), .newlines(let count, discretionary: true)),
        (.newlines(let count, discretionary: true), .newlines(_, discretionary: false)):
        tokens[tokens.count - 1] = .newlines(count, discretionary: true)
        return

      // If we see a pair of required newlines, combine them into a new token with the sum of
      // their counts.
      case (.newlines(let first, discretionary: true), .newlines(let second, discretionary: true)):
        tokens[tokens.count - 1] = .newlines(first + second, discretionary: true)
        return

      // If we see a pair of non-required newlines, keep only the larger one.
      case (
        .newlines(let first, discretionary: false),
        .newlines(let second, discretionary: false)
      ):
        tokens[tokens.count - 1] = .newlines(max(first, second), discretionary: true)
        return

      // If we see a pair of spaces where one or both are flexible, combine them into a new token
      // with the maximum of their counts.
      case (.space(let first, let firstFlexible), .space(let second, let secondFlexible))
      where firstFlexible || secondFlexible:
        tokens[tokens.count - 1] = .space(size: max(first, second), flexible: true)
        return

      default:
        break
      }
    }
    tokens.append(token)
  }

  /// Returns true if the first token of the given node is an open delimiter that may desire
  /// special breaking behavior in some cases.
  private func startsWithOpenDelimiter(_ node: Syntax) -> Bool {
    guard let token = node.firstToken else { return false }
    switch token.tokenKind {
    case .leftBrace, .leftParen, .leftSquareBracket: return true
    default: return false
    }
  }
}

extension Syntax {
  /// Creates a pretty-printable token stream for the provided Syntax node.
  func makeTokenStream(configuration: Configuration) -> [Token] {
    return TokenStreamCreator(configuration: configuration).makeStream(from: self)
  }
}

extension Collection {
  subscript(safe index: Index) -> Element? {
    return index < endIndex ? self[index] : nil
  }
}
