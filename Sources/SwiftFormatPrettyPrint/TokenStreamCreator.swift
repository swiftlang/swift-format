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

// FIXME: Remove this once we've completely moved up to a version of SwiftSyntax that has
// consolidated the TupleExprElement and FunctionCallArgument nodes.
#if HAS_CONSOLIDATED_TUPLE_AND_FUNCTION_CALL_SYNTAX
fileprivate typealias FunctionCallArgumentSyntax = TupleExprElementSyntax
fileprivate typealias FunctionCallArgumentListSyntax = TupleExprElementListSyntax
#else
fileprivate typealias TupleExprElementListSyntax = TupleElementListSyntax
fileprivate typealias TupleExprElementSyntax = TupleElementSyntax
#endif

/// Visits the nodes of a syntax tree and constructs a linear stream of formatting tokens that
/// tell the pretty printer how the source text should be laid out.
private final class TokenStreamCreator: SyntaxVisitor {
  private var tokens = [Token]()
  private var beforeMap = [TokenSyntax: [Token]]()
  private var afterMap = [TokenSyntax: [[Token]]]()
  private let config: Configuration
  private let operatorContext: OperatorContext
  private let maxlinelength: Int

  /// Keeps track of the prefix length of multiline string segments when they are visited so that
  /// the prefix can be stripped at the beginning of lines before the text is added to the token
  /// stream.
  private var pendingMultilineStringSegmentPrefixLengths = [TokenSyntax: Int]()

  init(configuration: Configuration, operatorContext: OperatorContext) {
    self.config = configuration
    self.operatorContext = operatorContext
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
    let hasArguments = !node.signature.input.parameterList.isEmpty

    // Prioritize keeping ") throws -> <return_type>" together. We can only do this if the function
    // has arguments.
    if hasArguments && config.prioritizeKeepingFunctionOutputTogether {
      // Due to visitation order, the matching .open break is added in ParameterClauseSyntax.
      after(node.signature.lastToken, tokens: .close)
    }

    let mustBreak = node.body != nil || node.signature.output != nil
    arrangeParameterClause(node.signature.input, forcesBreakBeforeRightParen: mustBreak)

    // Prioritize keeping "<modifiers> func <name>(" together. Also include the ")" if the parameter
    // list is empty.
    let firstTokenAfterAttributes = node.modifiers?.firstToken ?? node.funcKeyword
    before(firstTokenAfterAttributes, tokens: .open)
    after(node.funcKeyword, tokens: .break)
    if hasArguments || node.genericParameterClause != nil {
      after(node.signature.input.leftParen, tokens: .close)
    } else {
      after(node.signature.input.rightParen, tokens: .close)
    }

    // Add a non-breaking space after the identifier if it's an operator, to separate it visually
    // from the following parenthesis or generic argument list. Note that even if the function is
    // defining a prefix or postfix operator, or even if the operator isn't originally followed by a
    // space, the token kind always comes through as `spacedBinaryOperator`.
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
    let hasArguments = !node.parameters.parameterList.isEmpty

    arrangeParameterClause(node.parameters, forcesBreakBeforeRightParen: node.body != nil)

    // Prioritize keeping "<modifiers> init<punctuation>" together.
    let firstTokenAfterAttributes = node.modifiers?.firstToken ?? node.initKeyword
    before(firstTokenAfterAttributes, tokens: .open)

    if hasArguments || node.genericParameterClause != nil {
      after(node.parameters.leftParen, tokens: .close)
    } else {
      after(node.parameters.rightParen, tokens: .close)
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
    let hasArguments = !node.indices.parameterList.isEmpty

    before(node.firstToken, tokens: .open)

    // Prioritize keeping "<modifiers> subscript" together.
    if let firstModifierToken = node.modifiers?.firstToken {
      before(firstModifierToken, tokens: .open)

      if hasArguments || node.genericParameterClause != nil {
        after(node.indices.leftParen, tokens: .close)
      } else {
        after(node.indices.rightParen, tokens: .close)
      }
    }

    // Prioritize keeping ") -> <return_type>" together. We can only do this if the subscript has
    // arguments.
    if hasArguments && config.prioritizeKeepingFunctionOutputTogether {
      // Due to visitation order, the matching .open break is added in ParameterClauseSyntax.
      after(node.result.lastToken, tokens: .close)
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

    arrangeParameterClause(node.indices, forcesBreakBeforeRightParen: true)

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

    // Add break groups, using open continuation breaks, around any conditions after the first so
    // that continuations inside of the conditions can stack in addition to continuations between
    // the conditions. There are no breaks around the first condition because if-statements look
    // better without a break between the "if" and the first condition.
    for condition in node.conditions.dropFirst() {
      before(condition.firstToken, tokens: .break(.open(kind: .continuation), size: 0))
      after(condition.lastToken, tokens: .break(.close(mustBreak: false), size: 0))
    }

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
    after(node.guardKeyword, tokens: .space)

    // Add break groups, using open continuation breaks, around all conditions so that continuations
    // inside of the conditions can stack in addition to continuations between the conditions.
    for condition in node.conditions {
      before(condition.firstToken, tokens: .break(.open(kind: .continuation), size: 0))
      after(condition.lastToken, tokens: .break(.close(mustBreak: false), size: 0))
    }

    before(node.elseKeyword, tokens: .break(.reset), .open)
    after(node.elseKeyword, tokens: .space)
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

    // If an item with a `where` clause follows an item without a `where` clause, the compiler emits
    // a warning telling the user that they should insert a newline between them to disambiguate
    // their appearance. We enforce that "requirement" here to avoid spurious warnings, especially
    // following a `NoCasesWithOnlyFallthrough` transformation that might merge cases.
    var lastItemWithoutWhereClause: CaseItemSyntax? = nil
    for item in node.caseItems {
      if let lastItem = lastItemWithoutWhereClause, item.whereClause != nil {
        after(lastItem.trailingComma, tokens: .newline)
      }
      lastItemWithoutWhereClause = item.whereClause == nil ? item : nil
    }

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

  func visit(_ node: YieldStmtSyntax) -> SyntaxVisitorContinueKind {
    after(node.yieldKeyword, tokens: .break)
    return .visitChildren
  }

  // TODO: - Other nodes (yet to be organized)

  func visit(_ node: DeclNameArgumentsSyntax) -> SyntaxVisitorContinueKind {
    return .visitChildren
  }

  func visit(_ node: TupleExprSyntax) -> SyntaxVisitorContinueKind {
    // We'll do nothing if it's a zero-element tuple, because we just want to keep the empty `()`
    // together.
    let elementCount = node.elementList.count

    if elementCount == 1 {
      // A tuple with one element is a parenthesized expression; add a group around it to keep it
      // together when possible, but breaks are handled elsewhere (see calls to
      // `stackedIndentationBehavior`).
      after(node.leftParen, tokens: .open)
      before(node.rightParen, tokens: .close)
    } else if elementCount > 1 {
      // Tuples with more than one element are "true" tuples, and should indent as block structures.
      after(node.leftParen, tokens: .break(.open, size: 0), .open)
      before(node.rightParen, tokens: .close, .break(.close, size: 0))

      insertTokens(.break(.same), betweenElementsOf: node.elementList)

      for element in node.elementList {
        arrangeAsTupleExprElement(element)
      }
    }

    return .visitChildren
  }

  func visit(_ node: TupleExprElementListSyntax) -> SyntaxVisitorContinueKind {
    // Intentionally do nothing here. Since `TupleExprElement`s are used both in tuple expressions
    // and function argument lists, which need to be formatted, differently, those nodes manually
    // loop over the nodes and arrange them in those contexts.
    return .visitChildren
  }

  func visit(_ node: TupleExprElementSyntax) -> SyntaxVisitorContinueKind {
    // Intentionally do nothing here. Since `TupleExprElement`s are used both in tuple expressions
    // and function argument lists, which need to be formatted, differently, those nodes manually
    // loop over the nodes and arrange them in those contexts.
    return .visitChildren
  }

  /// Arranges the given tuple expression element as a tuple element (rather than a function call
  /// argument).
  ///
  /// - Parameter node: The tuple expression element to be arranged.
  private func arrangeAsTupleExprElement(_ node: TupleExprElementSyntax) {
    before(node.firstToken, tokens: .open)
    after(node.colon, tokens: .break)
    after(node.lastToken, tokens: .close)
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
    if let calledMemberAccessExpr = node.calledExpression as? MemberAccessExprSyntax {
      if let base = calledMemberAccessExpr.base, base is IdentifierExprSyntax {
        before(base.firstToken, tokens: .open)
        after(calledMemberAccessExpr.name.lastToken, tokens: .close)
      }
    }

    let arguments = node.argumentList

    // If there is a trailing closure, force the right parenthesis down to the next line so it
    // stays with the open curly brace.
    let breakBeforeRightParen = node.trailingClosure != nil
      && !isCompactSingleFunctionCallArgument(arguments)

    before(node.trailingClosure?.leftBrace, tokens: .break(.same))

    arrangeFunctionCallArgumentList(
      arguments,
      leftDelimiter: node.leftParen,
      rightDelimiter: node.rightParen,
      forcesBreakBeforeRightDelimiter: breakBeforeRightParen)

    return .visitChildren
  }

  /// Arrange the given argument list (or equivalently, tuple expression list) as a list of function
  /// arguments.
  ///
  /// - Parameters:
  ///   - arguments: The argument list/tuple expression list to arrange.
  ///   - leftDelimiter: The left parenthesis or bracket surrounding the arguments, if any.
  ///   - rightDelimiter: The right parenthesis or bracket surrounding the arguments, if any.
  ///   - forcesBreakBeforeRightDelimiter: True if a line break should be forced before the right
  ///     right delimiter if a line break occurred after the left delimiter, or false if the right
  ///     delimiter is allowed to hang on the same line as the final argument.
  private func arrangeFunctionCallArgumentList(
    _ arguments: FunctionCallArgumentListSyntax,
    leftDelimiter: TokenSyntax?,
    rightDelimiter: TokenSyntax?,
    forcesBreakBeforeRightDelimiter: Bool
  ) {
    if !arguments.isEmpty {
      var afterLeftDelimiter: [Token] = [.break(.open, size: 0)]
      var beforeRightDelimiter: [Token] = [
        .break(.close(mustBreak: forcesBreakBeforeRightDelimiter), size: 0),
      ]

      if shouldGroupAroundArgumentList(arguments) {
        afterLeftDelimiter.append(.open(argumentListConsistency()))
        beforeRightDelimiter.append(.close)
      }

      after(leftDelimiter, tokens: afterLeftDelimiter)
      before(rightDelimiter, tokens: beforeRightDelimiter)
    }

    let shouldGroupAroundArgument = !isCompactSingleFunctionCallArgument(arguments)
    for argument in arguments {
      arrangeAsFunctionCallArgument(argument, shouldGroup: shouldGroupAroundArgument)
    }
  }

  /// Arranges the given tuple expression element as a function call argument.
  ///
  /// - Parameters:
  ///   - node: The tuple expression element.
  ///   - shouldGroup: If true, group around the argument to prefer keeping it together if possible.
  private func arrangeAsFunctionCallArgument(
    _ node: FunctionCallArgumentSyntax,
    shouldGroup: Bool
  ) {
    if shouldGroup {
      before(node.firstToken, tokens: .open)
    }

    // If we have an open delimiter following the colon, use a space instead of a continuation
    // break so that we don't awkwardly shift the delimiter down and indent it further if it
    // wraps.
    let tokenAfterColon: Token = startsWithOpenDelimiter(node.expression) ? .space : .break
    after(node.colon, tokens: tokenAfterColon)

    if let trailingComma = node.trailingComma {
      var afterTrailingComma: [Token] = [.break(.same)]
      if shouldGroup {
        afterTrailingComma.insert(.close, at: 0)
      }
      after(trailingComma, tokens: afterTrailingComma)
    } else if shouldGroup {
      after(node.lastToken, tokens: .close)
    }
  }

  func visit(_ node: ClosureExprSyntax) -> SyntaxVisitorContinueKind {
    if let signature = node.signature {
      after(node.leftBrace, tokens: .break(.open))
      if node.statements.count > 0 {
        after(signature.inTok, tokens: .break(.same))
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
    let arguments = node.argumentList

    // If there is a trailing closure, force the right bracket down to the next line so it stays
    // with the open curly brace.
    let breakBeforeRightBracket = node.trailingClosure != nil

    before(node.trailingClosure?.leftBrace, tokens: .space)

    arrangeFunctionCallArgumentList(
      arguments,
      leftDelimiter: node.leftBracket,
      rightDelimiter: node.rightBracket,
      forcesBreakBeforeRightDelimiter: breakBeforeRightBracket)

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

  func visit(_ node: ObjectLiteralExprSyntax) -> SyntaxVisitorContinueKind {
    arrangeFunctionCallArgumentList(
      node.arguments,
      leftDelimiter: node.leftParen,
      rightDelimiter: node.rightParen,
      forcesBreakBeforeRightDelimiter: false)
    return .visitChildren
  }

  func visit(_ node: ParameterClauseSyntax) -> SyntaxVisitorContinueKind {
    // Prioritize keeping ") throws -> <return_type>" together. We can only do this if the function
    // has arguments.
    if !node.parameterList.isEmpty && config.prioritizeKeepingFunctionOutputTogether {
      // Due to visitation order, this .open corresponds to a .close added in FunctionDeclSyntax
      // or SubscriptDeclSyntax.
      before(node.rightParen, tokens: .open)
    }

    return .visitChildren
  }

  func visit(_ node: FunctionParameterSyntax) -> SyntaxVisitorContinueKind {
    before(node.firstToken, tokens: .open)
    arrangeAttributeList(node.attributes)
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

    let breakKindOpen: BreakKind
    let breakKindClose: BreakKind
    if config.indentConditionalCompilationBlocks {
      breakKindOpen = .open
      breakKindClose = .close
    } else {
      breakKindOpen = .same
      breakKindClose = .same
    }

    let tokenToOpenWith = node.condition?.lastToken ?? node.poundKeyword
    after(tokenToOpenWith, tokens: .break(breakKindOpen), .open)

    // Unlike other code blocks, where we may want a single statement to be laid out on the same
    // line as a parent construct, the content of an `#if` block must always be on its own line;
    // the newline token inserted at the end enforces this.
    if let lastElemTok = node.elements.lastToken {
      after(lastElemTok, tokens: .break(breakKindClose), .newline, .close)
    } else {
      before(tokenToOpenWith.nextToken, tokens: .break(breakKindClose), .newline, .close)
    }

    if let condition = node.condition {
      before(condition.firstToken, tokens: .printerControl(kind: .disableBreaking))
      after(
        condition.lastToken,
        tokens: .printerControl(kind: .enableBreaking), .break(.reset, size: 0))
    }

    return .visitChildren
  }

  func visit(_ node: MemberDeclBlockSyntax) -> SyntaxVisitorContinueKind {
    return .visitChildren
  }

  func visit(_ node: MemberDeclListSyntax) -> SyntaxVisitorContinueKind {
    // This is the same as `insertTokens(_:betweenElementsOf:)`, but testing for an extra condition
    // on the left-hand element.
    for item in node.dropLast() where shouldInsertNewline(basedOn: item.semicolon) {
      after(item.lastToken, tokens: .newline)
    }
    return .visitChildren
  }

  func visit(_ node: MemberDeclListItemSyntax) -> SyntaxVisitorContinueKind {
    before(node.firstToken, tokens: .open)
    let resetSize = node.semicolon != nil ? 1 : 0
    after(node.lastToken, tokens: .close, .break(.reset, size: resetSize))
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
    after(node.operatorKeyword, tokens: .break)
    return .visitChildren
  }

  func visit(_ node: OperatorPrecedenceAndTypesSyntax) -> SyntaxVisitorContinueKind {
    // Despite being an `IdentifierListSyntax`, the language grammar currently only allows a single
    // precedence group here, so we don't worry about breaks at any interior commas.
    after(node.colon, tokens: .break(.open))
    after(node.lastToken, tokens: .break(.close, size: 0))
    return .visitChildren
  }

  func visit(_ node: EnumCaseElementSyntax) -> SyntaxVisitorContinueKind {
    after(node.trailingComma, tokens: .break)

    if let associatedValue = node.associatedValue {
      arrangeParameterClause(associatedValue, forcesBreakBeforeRightParen: true)
    }

    return .visitChildren
  }

  func visit(_ node: ObjcSelectorExprSyntax) -> SyntaxVisitorContinueKind {
    return .visitChildren
  }

  func visit(_ node: ObjCSelectorSyntax) -> SyntaxVisitorContinueKind {
    insertTokens(.break(.same, size: 0), betweenElementsOf: node)
    return .visitChildren
  }

  func visit(_ node: PrecedenceGroupDeclSyntax) -> SyntaxVisitorContinueKind {
    after(node.precedencegroupKeyword, tokens: .break)
    after(node.identifier, tokens: .break(.reset))
    after(node.leftBrace, tokens: .break(.open), .newline)
    before(node.rightBrace, tokens: .break(.close))
    return .visitChildren
  }

  func visit(_ node: PrecedenceGroupRelationSyntax) -> SyntaxVisitorContinueKind {
    after(node.colon, tokens: .break(.open))
    after(node.lastToken, tokens: .break(.close), .newline)
    return .visitChildren
  }

  func visit(_ node: PrecedenceGroupAssignmentSyntax) -> SyntaxVisitorContinueKind {
    after(node.colon, tokens: .break(.open))
    after(node.lastToken, tokens: .break(.close), .newline)
    return .visitChildren
  }

  func visit(_ node: PrecedenceGroupNameElementSyntax) -> SyntaxVisitorContinueKind {
    after(node.trailingComma, tokens: .break(.same))
    return .visitChildren
  }

  func visit(_ node: PrecedenceGroupAssociativitySyntax) -> SyntaxVisitorContinueKind {
    after(node.colon, tokens: .break(.open))
    after(node.lastToken, tokens: .break(.close), .newline)
    return .visitChildren
  }

  func visit(_ node: AccessLevelModifierSyntax) -> SyntaxVisitorContinueKind {
    return .visitChildren
  }

  func visit(_ node: CodeBlockSyntax) -> SyntaxVisitorContinueKind {
    return .visitChildren
  }

  func visit(_ node: CodeBlockItemListSyntax) -> SyntaxVisitorContinueKind {
    // This is the same as `insertTokens(_:betweenElementsOf:)`, but testing for an extra condition
    // on the left-hand element.
    for item in node.dropLast() where shouldInsertNewline(basedOn: item.semicolon) {
      after(item.lastToken, tokens: .newline)
    }
    return .visitChildren
  }

  func visit(_ node: CodeBlockItemSyntax) -> SyntaxVisitorContinueKind {
    before(node.firstToken, tokens: .open)
    let resetSize = node.semicolon != nil ? 1 : 0
    after(node.lastToken, tokens: .close, .break(.reset, size: resetSize))
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
    after(node.inOut, tokens: .break)
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

  func visit(_ node: TryExprSyntax) -> SyntaxVisitorContinueKind {
    before(node.expression.firstToken, tokens: .break)
    return .visitChildren
  }

  func visit(_ node: TypeExprSyntax) -> SyntaxVisitorContinueKind {
    return .visitChildren
  }

  func visit(_ node: AttributeSyntax) -> SyntaxVisitorContinueKind {
    before(node.firstToken, tokens: .open)
    if node.argument != nil {
      // Wrap the attribute's arguments in their own group, so arguments stay together with a higher
      // affinity than the overall attribute (e.g. allows a break after the opening "(" and then
      // having the entire argument list on 1 line). Necessary spaces and breaks are added inside of
      // the argument, using type specific visitor methods.
      after(node.leftParen, tokens: .break(.open, size: 0), .open(argumentListConsistency()))
      before(node.rightParen, tokens: .break(.close, size: 0), .close)
    }
    after(node.lastToken, tokens: .close)
    return .visitChildren
  }

  func visit(_ node: AvailabilitySpecListSyntax) -> SyntaxVisitorContinueKind {
    insertTokens(.break(.same, size: 1), betweenElementsOf: node)
    return .visitChildren
  }

  func visit(_ node: AvailabilityLabeledArgumentSyntax) -> SyntaxVisitorContinueKind {
    before(node.label, tokens: .open)
    after(node.colon, tokens: .break(.continue, size: 1))
    after(node.value.lastToken, tokens: .close)
    return .visitChildren
  }

  func visit(_ node: AvailabilityVersionRestrictionSyntax) -> SyntaxVisitorContinueKind {
    before(node.firstToken, tokens: .open)
    after(node.platform, tokens: .break(.continue, size: 1))
    after(node.lastToken, tokens: .close)
    return .visitChildren
  }

  func visit(_ node: ElseBlockSyntax) -> SyntaxVisitorContinueKind {
    return .visitChildren
  }

  func visit(_ node: ConditionElementSyntax) -> SyntaxVisitorContinueKind {
    before(node.firstToken, tokens: .open)
    if let comma = node.trailingComma {
      after(comma, tokens: .close, .break(.same))
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
    before(node.colonMark, tokens: .break, .open)
    after(node.colonMark, tokens: .space)
    after(node.secondChoice.lastToken, tokens: .close, .close)
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
    let elementCount = node.elements.count
    assert(elementCount > 0 && elementCount <= 3, "SequenceExpr should have already been folded.")

    var iterator = node.elements.makeIterator()
    let lhs = iterator.next()!
    maybeGroupAroundSubexpression(lhs)

    if elementCount == 2 {
      // Cast expressions are 2-element sequence expressions, containing the left-hand side followed
      // by a single `AsExpr` or `IsExpr` node that holds both the keyword and the right-hand type
      // expression.
      let castOp = iterator.next()!

      before(castOp.firstToken, tokens: .break(.continue), .open)
      after(castOp.lastToken, tokens: .close)
    } else if elementCount == 3 {
      // Binary operators (and other syntax that isn't considered strictly a "binary" operator, like
      // assignment expressions) are covered by 3-element sequence expressions.
      let binOp = iterator.next()!
      let rhs = iterator.next()!
      maybeGroupAroundSubexpression(rhs, combiningOperator: binOp)

      let wrapsBeforeOperator = !isAssigningOperator(binOp)

      if shouldRequireWhitespace(around: binOp) {
        if isAssigningOperator(binOp) {
          var beforeTokens: [Token]

          // If the rhs starts with a parenthesized expression, stack indentation around it.
          // Otherwise, use regular continuation breaks.
          if let (unindentingNode, _) = stackedIndentationBehavior(after: binOp, rhs: rhs) {
            beforeTokens = [.break(.open(kind: .continuation))]
            after(unindentingNode.lastToken, tokens: [.break(.close(mustBreak: false), size: 0)])
          } else {
            beforeTokens = [.break(.continue)]
          }

          // When the RHS is a simple expression, even if is requires multiple lines, we don't add a
          // group so that as much of the expression as possible can stay on the same line as the
          // operator token.
          if isCompoundExpression(rhs) {
            beforeTokens.append(.open)
            after(rhs.lastToken, tokens: .close)
          }

          after(binOp.lastToken, tokens: beforeTokens)
        } else if let (unindentingNode, shouldReset) =
          stackedIndentationBehavior(after: binOp, rhs: rhs)
        {
          // For parenthesized expressions and for unparenthesized usages of `&&` and `||`, we don't
          // want to treat all continue breaks the same. If we did, then all operators would line up
          // at the same alignment regardless of whether they were, for example, `&&` or something
          // between a pair of `&&`. To make long expressions/conditionals format more cleanly, we
          // use open-continuation/close pairs around such operators and their right-hand sides so
          // that the continuation breaks inside those scopes "stack", instead of receiving the
          // usual single-level "continuation line or not" behavior.
          let openBreakTokens: [Token] = [.break(.open(kind: .continuation)), .open]
          if wrapsBeforeOperator {
            before(binOp.firstToken, tokens: openBreakTokens)
          } else {
            after(binOp.lastToken, tokens: openBreakTokens)
          }

          let closeBreakTokens: [Token] =
            (shouldReset ? [.break(.reset, size: 0)] : [])
            + [.break(.close(mustBreak: false), size: 0), .close]
          after(unindentingNode.lastToken, tokens: closeBreakTokens)
        } else {
          if wrapsBeforeOperator {
            before(binOp.firstToken, tokens: .break(.continue))
          } else {
            after(binOp.lastToken, tokens: .break(.continue))
          }
        }

        if wrapsBeforeOperator {
          after(binOp.lastToken, tokens: .space)
        } else {
          before(binOp.firstToken, tokens: .space)
        }
      }
    }

    return .visitChildren
  }

  func visit(_ node: AssignmentExprSyntax) -> SyntaxVisitorContinueKind {
    // Breaks and spaces are inserted at the `SequenceExpr` level.
    return .visitChildren
  }

  func visit(_ node: BinaryOperatorExprSyntax) -> SyntaxVisitorContinueKind {
    // Breaks and spaces are inserted at the `SequenceExpr` level.
    return .visitChildren
  }

  func visit(_ node: AsExprSyntax) -> SyntaxVisitorContinueKind {
    // The break before the `as` keyword is inserted at the `SequenceExpr` level so that it is
    // placed in the correct relative position to the group surrounding the cast operator and type
    // expression.
    before(node.typeName.firstToken, tokens: .space)
    return .visitChildren
  }

  func visit(_ node: IsExprSyntax) -> SyntaxVisitorContinueKind {
    // The break before the `is` keyword is inserted at the `SequenceExpr` level so that it is
    // placed in the correct relative position to the group surrounding the cast operator and type
    // expression.
    before(node.typeName.firstToken, tokens: .space)
    return .visitChildren
  }

  func visit(_ node: ArrowExprSyntax) -> SyntaxVisitorContinueKind {
    // The break before the `throws` keyword is inserted at the `SequenceExpr` level so that it is
    // placed in the correct relative position to the group surrounding the "operator".
    after(node.throwsToken, tokens: .break)
    return .visitChildren
  }

  func visit(_ node: SuperRefExprSyntax) -> SyntaxVisitorContinueKind {
    return .visitChildren
  }

  func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
    arrangeAttributeList(node.attributes)

    if node.bindings.count == 1 {
      // If there is only a single binding, don't allow a break between the `let/var` keyword and
      // the identifier; there are better places to break later on.
      after(node.letOrVarKeyword, tokens: .space)
    } else {
      // If there is more than one binding, we permit an open-break after `let/var` so that each of
      // the comma-delimited items will potentially receive indentation. We also add a group around
      // the individual bindings to bind them together better. (This is done here, not in
      // `visit(_: PatternBindingSyntax)`, because we only want that behavior when there are
      // multiple bindings.)
      after(node.letOrVarKeyword, tokens: .break(.open))

      for binding in node.bindings {
        before(binding.firstToken, tokens: .open)
        after(binding.trailingComma, tokens: .break(.same))
        after(binding.lastToken, tokens: .close)
      }

      after(node.lastToken, tokens: .break(.close, size: 0))
    }

    return .visitChildren
  }

  func visit(_ node: PatternBindingSyntax) -> SyntaxVisitorContinueKind {
    // If the type annotation and/or the initializer clause need to wrap, we want those
    // continuations to stack to improve readability. So, we need to keep track of how many open
    // breaks we create (so we can close them at the end of the binding) and also keep track of the
    // right-most token that will anchor the close breaks.
    var closesNeeded: Int = 0
    var closeAfterToken: TokenSyntax? = nil

    if let typeAnnotation = node.typeAnnotation {
      after(typeAnnotation.colon, tokens: .break(.open(kind: .continuation)))
      closesNeeded += 1
      closeAfterToken = typeAnnotation.lastToken
    }
    if let initializer = node.initializer {
      let expr = initializer.value

      if let (unindentingNode, _) = stackedIndentationBehavior(rhs: expr) {
        after(initializer.equal, tokens: .break(.open(kind: .continuation)))
        after(unindentingNode.lastToken, tokens: .break(.close(mustBreak: false), size: 0))
      } else {
        after(initializer.equal, tokens: .break(.continue))
      }
      closeAfterToken = initializer.lastToken

      // When the RHS is a simple expression, even if is requires multiple lines, we don't add a
      // group so that as much of the expression as possible can stay on the same line as the
      // operator token.
      if isCompoundExpression(expr) {
        before(expr.firstToken, tokens: .open)
        after(expr.lastToken, tokens: .close)
      }
    }

    if let accessorOrCodeBlock = node.accessor {
      arrangeAccessorOrCodeBlock(accessorOrCodeBlock)
    } else if let trailingComma = node.trailingComma {
      // If this is one of multiple comma-delimited bindings, move any pending close breaks to
      // follow the comma so that it doesn't get separated from the tokens before it.
      closeAfterToken = trailingComma
    }

    if closeAfterToken != nil && closesNeeded > 0 {
      let closeTokens = [Token](repeatElement(.break(.close, size: 0), count: closesNeeded))
      after(closeAfterToken, tokens: closeTokens)
    }

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
    before(node.equal, tokens: .space)
    after(node.equal, tokens: .break)
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

  func visit(_ node: PoundErrorDeclSyntax) -> SyntaxVisitorContinueKind {
    return .visitChildren
  }

  func visit(_ node: SpecializeExprSyntax) -> SyntaxVisitorContinueKind {
    return .visitChildren
  }

  func visit(_ node: TypeAnnotationSyntax) -> SyntaxVisitorContinueKind {
    before(node.type.firstToken, tokens: .open)
    after(node.type.lastToken, tokens: .close)
    return .visitChildren
  }

  func visit(_ node: UnknownPatternSyntax) -> SyntaxVisitorContinueKind {
    return .visitChildren
  }

  func visit(_ node: SomeTypeSyntax) -> SyntaxVisitorContinueKind {
    after(node.someSpecifier, tokens: .space)
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
    before(node.equal, tokens: .space)

    // InitializerClauses that are children of a PatternBindingSyntax are already handled in the
    // latter node, to ensure that continuations stack appropriately.
    if !(node.parent is PatternBindingSyntax) {
      after(node.equal, tokens: .break)
    }
    return .visitChildren
  }

  func visit(_ node: PoundFunctionExprSyntax) -> SyntaxVisitorContinueKind {
    return .visitChildren
  }

  func visit(_ node: StringLiteralExprSyntax) -> SyntaxVisitorContinueKind {
    if node.openQuote.tokenKind == .multilineStringQuote {
      // If it's a multiline string, the last segment of the literal will end with a newline and
      // zero or more whitespace that indicates the amount of whitespace stripped from each line of
      // the string literal.
      if let lastSegment = node.segments.last as? StringSegmentSyntax,
        let lastLine
          = lastSegment.content.text.split(separator: "\n", omittingEmptySubsequences: false).last
      {
        let prefixCount = lastLine.count

        // Segments may be `StringSegmentSyntax` or `ExpressionSegmentSyntax`; for the purposes of
        // newline handling and whitespace stripping, we only need to handle the former.
        for case let segment as StringSegmentSyntax in node.segments {
          // Register the content tokens of the segments and the amount of leading whitespace to
          // strip; this will be retrieved when we visit the token.
          pendingMultilineStringSegmentPrefixLengths[segment.content] = prefixCount
        }
      }
    }
    return .visitChildren
  }

  func visit(_ node: StringSegmentSyntax) -> SyntaxVisitorContinueKind {
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

    before(node.requirementList.firstToken, tokens: .open(genericRequirementListConsistency()))
    after(node.requirementList.lastToken, tokens: .close)

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

  // FIXME: Remove once the changes around `GenericRequirementSyntax` and its children have settled.
  #if !HAS_UNCONSOLIDATED_GENERIC_REQUIREMENTS
  func visit(_ node: GenericRequirementSyntax) -> SyntaxVisitorContinueKind {
    before(node.firstToken, tokens: .open)
    if let trailingComma = node.trailingComma {
      after(trailingComma, tokens: .close, .break(.same))
    } else {
      after(node.lastToken, tokens: .close)
    }
    return .visitChildren
  }
  #endif

  func visit(_ node: SameTypeRequirementSyntax) -> SyntaxVisitorContinueKind {
    before(node.equalityToken, tokens: .break)
    after(node.equalityToken, tokens: .space)

    #if HAS_UNCONSOLIDATED_GENERIC_REQUIREMENTS
    before(node.firstToken, tokens: .open)
    if let trailingComma = node.trailingComma {
      after(trailingComma, tokens: .close, .break(.same))
    } else {
      after(node.lastToken, tokens: .close)
    }
    #endif
    return .visitChildren
  }

  func visit(_ node: ConformanceRequirementSyntax) -> SyntaxVisitorContinueKind {
    after(node.colon, tokens: .break)

    #if HAS_UNCONSOLIDATED_GENERIC_REQUIREMENTS
    before(node.firstToken, tokens: .open)
    if let trailingComma = node.trailingComma {
      after(trailingComma, tokens: .close, .break(.same))
    } else {
      after(node.lastToken, tokens: .close)
    }
    #endif
    return .visitChildren
  }

  func visit(_ node: TuplePatternElementSyntax) -> SyntaxVisitorContinueKind {
    after(node.trailingComma, tokens: .break(.same))
    return .visitChildren
  }

  func visit(_ node: MemberTypeIdentifierSyntax) -> SyntaxVisitorContinueKind {
    before(node.period, tokens: .break(.continue, size: 0))
    return .visitChildren
  }

  func visit(_ node: OptionalChainingExprSyntax) -> SyntaxVisitorContinueKind {
    return .visitChildren
  }

  func visit(_ node: SimpleTypeIdentifierSyntax) -> SyntaxVisitorContinueKind {
    return .visitChildren
  }

  func visit(_ node: AvailabilityConditionSyntax) -> SyntaxVisitorContinueKind {
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

  func visit(_ node: MatchingPatternConditionSyntax) -> SyntaxVisitorContinueKind {
    before(node.firstToken, tokens: .open)
    after(node.caseKeyword, tokens: .break)
    after(node.lastToken, tokens: .close)
    return .visitChildren
  }

  func visit(_ node: OptionalBindingConditionSyntax) -> SyntaxVisitorContinueKind {
    after(node.letOrVarKeyword, tokens: .break)

    if let typeAnnotation = node.typeAnnotation {
      after(typeAnnotation.colon, tokens: .break(.open(kind: .continuation)))
      after(typeAnnotation.lastToken, tokens: .break(.close(mustBreak: false), size: 0))
    }

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

    if let pendingSegmentIndex = pendingMultilineStringSegmentPrefixLengths.index(forKey: token) {
      appendMultilineStringSegments(at: pendingSegmentIndex)
    } else {
      // Otherwise, it's just a regular token, so add the text as-is.
      appendToken(.syntax(token.text))
    }

    appendAfterTokensAndTrailingComments(token)

    // It doesn't matter what we return here, tokens do not have children.
    return .skipChildren
  }

  /// Appends the contents of the pending multiline string segment at the given index in the
  /// registration dictionary (removing it from that dictionary) to the token stream, splitting it
  /// into lines along with `.newline` tokens and stripping the leading whitespace.
  private func appendMultilineStringSegments(at index: Dictionary<TokenSyntax, Int>.Index) {
    let (token, prefixCount) = pendingMultilineStringSegmentPrefixLengths[index]
    pendingMultilineStringSegmentPrefixLengths.remove(at: index)

    let lines = token.text.split(separator: "\n", omittingEmptySubsequences: false)

    // The first "line" is a special case. If it is non-empty, then it is a piece of text that
    // immediately followed an interpolation segment on the same line of the string, like the
    // " baz" in "foo bar \(x + y) baz". If that is the case, we need to insert that text before
    // anything else.
    let firstLine = lines.first!
    if !firstLine.isEmpty {
      appendToken(.syntax(String(firstLine)))
    }

    // Add the remaining lines of the segment, preceding each with a newline and stripping the
    // leading whitespace so that the pretty-printer can re-indent the string according to the
    // standard rules that it would apply.
    for line in lines.dropFirst() as ArraySlice {
      appendToken(.newline(kind: .mandatory))

      // Verify that the characters to be stripped are all spaces. If they are not, the string
      // is not valid (no line should contain less leading whitespace than the line with the
      // closing quotes), but the parser still allows this and it's flagged as an error later during
      // compilation, so we don't want to destroy the user's text in that case.
      let stringToAppend: Substring
      if (line.prefix(prefixCount).allSatisfy { $0 == " " }) {
        stringToAppend = line.dropFirst(prefixCount)
      } else {
        // Only strip as many spaces as we have. This will force the misaligned line to line up with
        // the others; let's assume that's what the user wanted anyway.
        stringToAppend = line.drop { $0 == " " }
      }
      if !stringToAppend.isEmpty {
        appendToken(.syntax(String(stringToAppend)))
      }
    }
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

  /// Applies formatting to a collection of parameters for a decl.
  ///
  /// - Parameters:
  ///    - parameters: A node that contains the parameters that can be passed to a decl when its
  ///      called.
  ///    - forcesBreakBeforeRightParen: Whether a break should be required before the right paren
  ///      when the right paren is on a different line than the corresponding left paren.
  private func arrangeParameterClause(
    _ parameters: ParameterClauseSyntax, forcesBreakBeforeRightParen: Bool
  ) {
    guard !parameters.parameterList.isEmpty else { return }

    after(parameters.leftParen, tokens: .break(.open, size: 0), .open(argumentListConsistency()))
    before(
      parameters.rightParen,
      tokens: .break(.close(mustBreak: forcesBreakBeforeRightParen), size: 0), .close)
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
      after(node.leftBrace, tokens: .break(.open, size: 0))
      before(node.rightBrace, tokens: .break(.close, size: 0))
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
      after(node.leftBrace, tokens: .break(.open, size: 0))
      before(node.rightBrace, tokens: .break(.close, size: 0))
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
      after(node.leftBrace, tokens: .break(.open, size: 0))
      before(node.rightBrace, tokens: .break(.close, size: 0))
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
      after(node.leftBrace, tokens: .break(.open, size: 0))
      before(node.rightBrace, tokens: .break(.close, size: 0))
    }
  }

  /// Returns the group consistency that should be used for argument lists based on the user's
  /// current configuration.
  private func argumentListConsistency() -> GroupBreakStyle {
    return config.lineBreakBeforeEachArgument ? .consistent : .inconsistent
  }

  /// Returns the group consistency that should be used for generic requirement lists based on
  /// the user's current configuration.
  private func genericRequirementListConsistency() -> GroupBreakStyle {
    return config.lineBreakBeforeEachGenericRequirement ? .consistent : .inconsistent
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
          appendToken(.newlines(count, kind: .discretionary))
        } else {
          // Even if discretionary line breaks are not being respected, we still respect multiple
          // line breaks in order to keep blank separator lines that the user might want.
          // TODO: It would be nice to restrict this to only allow multiple lines between statements
          // and declarations; as currently implemented, multiple newlines will locally the
          // configuration setting.
          if count > 1 {
            appendToken(.newlines(count, kind: .discretionary))
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
      case (.newlines(_, kind: .flexible), .newlines(let count, let requiredKind))
      where requiredKind == .discretionary || requiredKind == .mandatory,
        (.newlines(let count, let requiredKind), .newlines(_, kind: .flexible))
      where requiredKind == .discretionary || requiredKind == .mandatory:
        tokens[tokens.count - 1] = .newlines(count, kind: requiredKind)
        return

      // If we see a pair of required newlines, combine them into a new token with the sum of
      // their counts.
      case (.newlines(let first, let firstKind), .newlines(let second, let secondKind))
      where firstKind == secondKind && (firstKind == .discretionary || firstKind == .mandatory):
        tokens[tokens.count - 1] = .newlines(first + second, kind: firstKind)
        return

      // If we see a pair of flexible newlines, keep only the larger one.
      case (.newlines(let first, kind: .flexible), .newlines(let second, kind: .flexible)):
        tokens[tokens.count - 1] = .newlines(max(first, second), kind: .flexible)
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

  /// Returns true if open/close breaks should be inserted around the entire function call argument
  /// list.
  private func shouldGroupAroundArgumentList(_ arguments: FunctionCallArgumentListSyntax) -> Bool {
    let argumentCount = arguments.count

    // If there are no arguments, there's no reason to break.
    if argumentCount == 0 { return false }

    // If there is more than one argument, we must open/close break around the whole list.
    if argumentCount > 1 { return true }

    return !isCompactSingleFunctionCallArgument(arguments)
  }

  /// Returns true if the argument list can be compacted, even if it spans multiple lines (where
  /// compact means that it can start immediately after the open parenthesis).
  ///
  /// This is true for any argument list that contains a single argument (labeled or unlabeled) that
  /// is an array, dictionary, or closure literal.
  func isCompactSingleFunctionCallArgument(_ argumentList: FunctionCallArgumentListSyntax) -> Bool {
    guard argumentList.count == 1 else { return false }

    let expression = argumentList.first!.expression
    return expression is ArrayExprSyntax || expression is DictionaryExprSyntax
      || expression is ClosureExprSyntax
  }

  /// Returns a value indicating whether a statement or member declaration should have a newline
  /// inserted after it, based on the presence of a semicolon and whether or not the formatter is
  /// respecting existing newlines.
  private func shouldInsertNewline(basedOn semicolon: TokenSyntax?) -> Bool {
    if config.respectsExistingLineBreaks {
      // If we are respecting existing newlines, then we only want to force a newline at the end of
      // statements and declarations that don't have a semicolon (i.e., where they are required).
      return semicolon == nil
    } else {
      // If we are not respecting existing newlines, then we always force a newline (this forces
      // even semicolon-delimited statements onto separate lines).
      return true
    }
  }

  /// Adds a grouping around certain subexpressions during `SequenceExpr` visitation.
  ///
  /// Adding groups around these expressions allows them to prefer breaking onto a newline before
  /// the expression, keeping the entire expression together when possible, before breaking inside
  /// the expression. This is a hand-crafted list of expressions that generally look better when the
  /// break(s) before the expression fire before breaks inside of the expression.
  private func maybeGroupAroundSubexpression(
    _ expr: ExprSyntax, combiningOperator operatorExpr: ExprSyntax? = nil
  ) {
    switch expr {
    case is MemberAccessExprSyntax, is SubscriptExprSyntax:
      before(expr.firstToken, tokens: .open)
      after(expr.lastToken, tokens: .close)
    default:
      break
    }

    // When a function call expression is assigned to an lvalue, we omit the group around the
    // function call so that the callee and open parenthesis can remain on the same line, if they
    // fit. This is a frequent enough case that the outcome looks better with the exception in
    // place.
    if expr is FunctionCallExprSyntax,
      let operatorExpr = operatorExpr, !isAssigningOperator(operatorExpr)
    {
      before(expr.firstToken, tokens: .open)
      after(expr.lastToken, tokens: .close)
    }
  }

  /// Returns whether the given expression consists of multiple subexpressions. Certain expressions
  /// that are known to wrap an expressions, e.g. try expressions, are handled by checking the
  /// expression that they contain.
  private func isCompoundExpression(_ expr: ExprSyntax) -> Bool {
    switch expr {
    case let sequenceExpr as SequenceExprSyntax:
      return sequenceExpr.elements.count > 1
    case let tryExpr as TryExprSyntax:
      return isCompoundExpression(tryExpr.expression)
    case let tupleExpr as TupleExprSyntax where tupleExpr.elementList.count == 1:
      return isCompoundExpression(tupleExpr.elementList.first!.expression)
    default:
      return false
    }
  }

  /// Returns whether the given operator behaves as an assignment, to assign a right-hand-side to a
  /// left-hand-side in a SequenceExpr.
  ///
  /// Assignment is defined as either being an assignment operator (i.e. `=`) or any operator that
  /// uses "assignment" precedence.
  private func isAssigningOperator(_ operatorExpr: ExprSyntax) -> Bool {
    if operatorExpr is AssignmentExprSyntax {
      return true
    }
    if let binaryOperator = operatorExpr as? BinaryOperatorExprSyntax {
      let operatorText = binaryOperator.operatorToken.text
      if let precedence = operatorContext.infixOperator(named: operatorText)?.precedenceGroup,
        precedence === operatorContext.precedenceGroup(named: .assignment)
      {
        return true
      }
    }
    return false
  }

  /// Walks the expression and returns the leftmost subexpression if it is parenthesized (which
  /// might be the expression itself).
  ///
  /// - Parameter expr: The expression whose parenthesized leftmost subexpression should be
  ///   returned.
  /// - Returns: The parenthesized leftmost subexpression, or nil if the leftmost subexpression was
  ///   not parenthesized.
  private func parenthesizedLeftmostExpr(of expr: ExprSyntax) -> TupleExprSyntax? {
    switch expr {
    case let tupleExpr as TupleExprSyntax where tupleExpr.elementList.count == 1:
      return tupleExpr
    case let sequenceExpr as SequenceExprSyntax:
      return parenthesizedLeftmostExpr(of: sequenceExpr.elements.first!)
    case let ternaryExpr as TernaryExprSyntax:
      return parenthesizedLeftmostExpr(of: ternaryExpr.conditionExpression)
    default:
      return nil
    }
  }

  /// Determines if indentation should be stacked around a subexpression to the right of the given
  /// operator, and, if so, returns the node after which indentation stacking should be closed and
  /// whether or not the continuation state should be reset as well.
  ///
  /// Stacking is applied around parenthesized expressions, but also for low-precedence operators
  /// that frequently occur in long chains, such as logical AND (`&&`) and OR (`||`) in conditional
  /// statements. In this case, the extra level of indentation helps to improve readability with the
  /// operators inside those conditions even when parentheses are not used.
  private func stackedIndentationBehavior(
    after operatorExpr: ExprSyntax? = nil,
    rhs: ExprSyntax
  ) -> (unindentingNode: ExprSyntax, shouldReset: Bool)? {
    // Check for logical operators first, and if it's that kind of operator, stack indentation
    // around the entire right-hand-side. We have to do this check before checking the RHS for
    // parentheses because if the user writes something like `... && (foo) > bar || ...`, we don't
    // want the indentation stacking that starts before the `&&` to stop after the closing
    // parenthesis in `(foo)`.
    //
    // We also want to reset after undoing the stacked indentation so that we have a visual
    // indication that the subexpression has ended.
    if let binaryOperator = operatorExpr as? BinaryOperatorExprSyntax {
      let operatorText = binaryOperator.operatorToken.text
      if let precedence = operatorContext.infixOperator(named: operatorText)?.precedenceGroup,
        precedence === operatorContext.precedenceGroup(named: .logicalConjunction)
          || precedence === operatorContext.precedenceGroup(named: .logicalDisjunction)
      {
        return (unindentingNode: rhs, shouldReset: true)
      }
    }

    // If the right-hand-side of the operator is or starts with a parenthesized expression, stack
    // indentation around the operator and those parentheses. We don't need to reset here because
    // the parentheses are sufficient to provide a visual indication of the nesting relationship.
    if let parenthesizedExpr = parenthesizedLeftmostExpr(of: rhs) {
      return (unindentingNode: parenthesizedExpr, shouldReset: false)
    }

    // Otherwise, don't stack--use regular continuation breaks instead.
    return nil
  }

  /// Returns a value indicating whether whitespace should be required around the given operator.
  ///
  /// If spaces are not required (for example, range operators), then the formatter will also forbid
  /// breaks around the operator. This is to prevent situations where a break could occur before an
  /// unspaced operator (e.g., turning `0...10` into `0<newline>...10`), which would be a breaking
  /// change because it would treat it as a prefix operator `...10` instead of an infix operator.
  private func shouldRequireWhitespace(around operatorExpr: ExprSyntax) -> Bool {
    // Note that we look at the operator itself to make this determination, not the token kind.
    // The token kind (spaced or unspaced operator) represents how the *user* wrote it, and we want
    // to ignore that and apply our own rules.
    if let binaryOperator = operatorExpr as? BinaryOperatorExprSyntax {
      let token = binaryOperator.operatorToken
      if let precedence = operatorContext.infixOperator(named: token.text)?.precedenceGroup,
        precedence === operatorContext.precedenceGroup(named: .rangeFormation)
      {
        // We want to omit whitespace around range formation operators if possible. We can't do this
        // if the token is either preceded by a postfix operator, followed by a prefix operator, or
        // followed by a dot (for example, in an implicit member reference)---removing the spaces in
        // those situations would cause the parser to greedily treat the combined sequence of
        // operator characters as a single operator.
        if case .postfixOperator? = token.previousToken?.tokenKind { return true }

        switch token.nextToken?.tokenKind {
        case .prefixOperator?, .prefixPeriod?: return true
        default: return false
        }
      }
    }

    // For all other operators, we want to require whitespace on each side. That's always safe, so
    // we don't need to be concerned about neighboring operator tokens. For example, we don't need
    // to be concerned about the user writing "4+-5" when they meant "4 + -5", because Swift would
    // always parse the former as "4 +- 5".
    return true
  }
}

extension Syntax {
  /// Creates a pretty-printable token stream for the provided Syntax node.
  func makeTokenStream(configuration: Configuration, operatorContext: OperatorContext) -> [Token] {
    // First, fold the sequence expressions in the tree before passing it along to the token stream,
    // because we don't want to modify the tree during token stream creation.
    let folded = SequenceExprFoldingRewriter(operatorContext: operatorContext).visit(self)
    return TokenStreamCreator(
      configuration: configuration, operatorContext: operatorContext).makeStream(from: folded)
  }
}

/// Rewrites a syntax tree by folding any sequence expressions contained in it.
class SequenceExprFoldingRewriter: SyntaxRewriter {
  private let operatorContext: OperatorContext

  init(operatorContext: OperatorContext) {
    self.operatorContext = operatorContext
  }

  override func visit(_ node: SequenceExprSyntax) -> ExprSyntax {
    let rewrittenBySuper = super.visit(node)
    if let sequence = rewrittenBySuper as? SequenceExprSyntax {
      return sequence.folded(context: operatorContext)
    } else {
      return rewrittenBySuper
    }
  }
}

extension Collection {
  subscript(safe index: Index) -> Element? {
    return index < endIndex ? self[index] : nil
  }
}
