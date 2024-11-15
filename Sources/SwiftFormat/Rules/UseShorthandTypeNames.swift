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

/// Shorthand type forms must be used wherever possible.
///
/// Lint: Using a non-shorthand form (e.g. `Array<Element>`) yields a lint error unless the long
///       form is necessary (e.g. `Array<Element>.Index` cannot be shortened today.)
///
/// Format: Where possible, shorthand types replace long form types; e.g. `Array<Element>` is
///         converted to `[Element]`.
@_spi(Rules)
public final class UseShorthandTypeNames: SyntaxFormatRule {

  public override func visit(_ node: IdentifierTypeSyntax) -> TypeSyntax {
    // Ignore types that don't have generic arguments.
    guard let genericArgumentClause = node.genericArgumentClause else {
      return super.visit(node)
    }

    // If the node is a direct child of a member type identifier (e.g., `Array<Int>.Index`), the
    // type must be left in long form for the compiler. Fall back to the default visitation logic,
    // so that we don't skip children that may need to be rewritten. For example,
    // `Foo<Array<Int>>.Bar` can still be transformed to `Foo<[Int]>.Bar` because the member
    // reference is not directly attached to the type that will be transformed, but we need to visit
    // the children so that we don't skip this).
    guard let parent = node.parent, !parent.is(MemberTypeSyntax.self) else {
      return super.visit(node)
    }

    // Ensure that all arguments in the clause are shortened and in the expected format by visiting
    // the argument list, first.
    let genericArgumentList = visit(genericArgumentClause.arguments)

    let (leadingTrivia, trailingTrivia) = boundaryTrivia(around: Syntax(node))
    let newNode: TypeSyntax?

    switch node.name.text {
    case "Array":
      guard case .type(let typeArgument) = genericArgumentList.firstAndOnly?.argument else {
        newNode = nil
        break
      }
      newNode = shorthandArrayType(
        element: typeArgument,
        leadingTrivia: leadingTrivia,
        trailingTrivia: trailingTrivia
      )

    case "Dictionary":
      guard let arguments = exactlyTwoChildren(of: genericArgumentList),
        case (.type(let type0Argument), .type(let type1Argument)) = (arguments.0.argument, arguments.1.argument)
      else {
        newNode = nil
        break
      }
      newNode = shorthandDictionaryType(
        key: type0Argument,
        value: type1Argument,
        leadingTrivia: leadingTrivia,
        trailingTrivia: trailingTrivia
      )

    case "Optional":
      guard !isTypeOfUninitializedStoredVar(node) else {
        newNode = nil
        break
      }
      guard case .type(let typeArgument) = genericArgumentList.firstAndOnly?.argument else {
        newNode = nil
        break
      }
      newNode = shorthandOptionalType(
        wrapping: typeArgument,
        leadingTrivia: leadingTrivia,
        trailingTrivia: trailingTrivia
      )

    default:
      newNode = nil
    }

    if let newNode = newNode {
      diagnose(.useTypeShorthand(type: node.name.text), on: node)
      return newNode
    }

    // Even if we don't shorten this specific type that we're visiting, we may have rewritten
    // something in the generic argument list that we recursively visited, so return the original
    // node with that swapped out.
    var newGenericArgumentClause = genericArgumentClause
    newGenericArgumentClause.arguments = genericArgumentList

    var result = node
    result.genericArgumentClause = newGenericArgumentClause
    return TypeSyntax(result)
  }

  public override func visit(_ node: GenericSpecializationExprSyntax) -> ExprSyntax {
    // `GenericSpecializationExprSyntax`s are found in the syntax tree when a generic type is
    // encountered in an expression context, such as `Array<Int>()`. In these situations, the
    // corresponding array and dictionary shorthand nodes will be expression nodes, not type nodes,
    // so we may need to translate the arguments inside the generic argument list---which are
    // types---to the appropriate equivalent.

    // Ignore nodes where the expression being specialized isn't a simple identifier.
    guard let expression = node.expression.as(DeclReferenceExprSyntax.self) else {
      return super.visit(node)
    }

    // Member access after a shorthand type in an expression context appears to be fine in Swift.
    // For example, `let x: [Int].Index` is not permitted but `let x = [Int].Index()` is allowed.
    // To avoid introducing inconsistencies in users' code, we choose not to apply a shorthand
    // transform to these member accesses in expression contexts, even when they would be valid.
    // However, we still fall back to the default visitation logic, so that we don't skip children
    // that may need to be rewritten. For example, `Foo<Array<Int>>.Bar()` can still be transformed
    // to `Foo<[Int]>.Bar()` because the member reference is not directly attached to the type that
    // will be transformed, but we need to visit the children so that we don't skip this).
    guard let parent = node.parent, !parent.is(MemberAccessExprSyntax.self) else {
      return super.visit(node)
    }

    // Ensure that all arguments in the clause are shortened and in the expected format by visiting
    // the argument list, first.
    let genericArgumentList = visit(node.genericArgumentClause.arguments)

    let (leadingTrivia, trailingTrivia) = boundaryTrivia(around: Syntax(node))
    let newNode: ExprSyntax?

    switch expression.baseName.text {
    case "Array":
      guard case .type(let typeArgument) = genericArgumentList.firstAndOnly?.argument else {
        newNode = nil
        break
      }
      let arrayTypeExpr = makeArrayTypeExpression(
        elementType: typeArgument,
        leftSquare: TokenSyntax.leftSquareToken(leadingTrivia: leadingTrivia),
        rightSquare: TokenSyntax.rightSquareToken(trailingTrivia: trailingTrivia)
      )
      newNode = ExprSyntax(arrayTypeExpr)

    case "Dictionary":
      guard let arguments = exactlyTwoChildren(of: genericArgumentList),
        case (.type(let type0Argument), .type(let type1Argument)) = (arguments.0.argument, arguments.1.argument)
      else {
        newNode = nil
        break
      }
      let dictTypeExpr = makeDictionaryTypeExpression(
        keyType: type0Argument,
        valueType: type1Argument,
        leftSquare: TokenSyntax.leftSquareToken(leadingTrivia: leadingTrivia),
        colon: TokenSyntax.colonToken(trailingTrivia: .spaces(1)),
        rightSquare: TokenSyntax.rightSquareToken(trailingTrivia: trailingTrivia)
      )
      newNode = ExprSyntax(dictTypeExpr)

    case "Optional":
      guard case .type(let typeArgument) = genericArgumentList.firstAndOnly?.argument else {
        newNode = nil
        break
      }
      let optionalTypeExpr = makeOptionalTypeExpression(
        wrapping: typeArgument,
        leadingTrivia: leadingTrivia,
        questionMark: TokenSyntax.postfixQuestionMarkToken(trailingTrivia: trailingTrivia)
      )
      newNode = ExprSyntax(optionalTypeExpr)

    default:
      newNode = nil
    }

    if let newNode = newNode {
      diagnose(.useTypeShorthand(type: expression.baseName.text), on: expression)
      return newNode
    }

    // Even if we don't shorten this specific expression that we're visiting, we may have
    // rewritten something in the generic argument list that we recursively visited, so return the
    // original node with that swapped out.
    var result = node
    result.genericArgumentClause.arguments = genericArgumentList
    return ExprSyntax(result)
  }

  /// Returns the two arguments in the given argument list, if there are exactly two elements;
  /// otherwise, it returns nil.
  private func exactlyTwoChildren(
    of argumentList: GenericArgumentListSyntax
  ) -> (GenericArgumentSyntax, GenericArgumentSyntax)? {
    var iterator = argumentList.makeIterator()
    guard let first = iterator.next() else { return nil }
    guard let second = iterator.next() else { return nil }
    guard iterator.next() == nil else { return nil }
    return (first, second)
  }

  /// Returns a `TypeSyntax` representing a shorthand array type (e.g., `[Foo]`) with the given
  /// element type and trivia.
  private func shorthandArrayType(
    element: TypeSyntax,
    leadingTrivia: Trivia,
    trailingTrivia: Trivia
  ) -> TypeSyntax {
    let result = ArrayTypeSyntax(
      leftSquare: TokenSyntax.leftSquareToken(leadingTrivia: leadingTrivia),
      element: element,
      rightSquare: TokenSyntax.rightSquareToken(trailingTrivia: trailingTrivia)
    )
    return TypeSyntax(result)
  }

  /// Returns a `TypeSyntax` representing a shorthand dictionary type (e.g., `[Foo: Bar]`) with the
  /// given key/value types and trivia.
  private func shorthandDictionaryType(
    key: TypeSyntax,
    value: TypeSyntax,
    leadingTrivia: Trivia,
    trailingTrivia: Trivia
  ) -> TypeSyntax {
    let result = DictionaryTypeSyntax(
      leftSquare: TokenSyntax.leftSquareToken(leadingTrivia: leadingTrivia),
      key: key,
      colon: TokenSyntax.colonToken(trailingTrivia: .spaces(1)),
      value: value,
      rightSquare: TokenSyntax.rightSquareToken(trailingTrivia: trailingTrivia)
    )
    return TypeSyntax(result)
  }

  /// Returns a `TypeSyntax` representing a shorthand optional type (e.g., `Foo?`) with the given
  /// wrapped type and trivia, taking care to parenthesize the type when the wrapped type is a
  /// function type.
  private func shorthandOptionalType(
    wrapping wrappedType: TypeSyntax,
    leadingTrivia: Trivia,
    trailingTrivia: Trivia
  ) -> TypeSyntax {
    var wrappedType = wrappedType

    // Certain types must be wrapped in parentheses before using shorthand optional syntax to avoid
    // the "?" from binding incorrectly when re-parsed. Attach the leading trivia to the left-paren
    // that we're adding in these cases.
    switch Syntax(wrappedType).as(SyntaxEnum.self) {
    case .attributedType(let attributedType):
      wrappedType = parenthesizedType(attributedType, leadingTrivia: leadingTrivia)
    case .functionType(let functionType):
      wrappedType = parenthesizedType(functionType, leadingTrivia: leadingTrivia)
    case .someOrAnyType(let someOrAnyType):
      wrappedType = parenthesizedType(someOrAnyType, leadingTrivia: leadingTrivia)
    default:
      // Otherwise, the argument type can safely become an optional by simply appending a "?", but
      // we need to transfer the leading trivia from the original `Optional` token over to it.
      // By doing so, something like `/* comment */ Optional<Foo>` will become `/* comment */ Foo?`
      // instead of discarding the comment.
      wrappedType.leadingTrivia = leadingTrivia
    }

    let optionalType = OptionalTypeSyntax(
      wrappedType: wrappedType,
      questionMark: TokenSyntax.postfixQuestionMarkToken(trailingTrivia: trailingTrivia)
    )
    return TypeSyntax(optionalType)
  }

  /// Returns an `ArrayExprSyntax` whose single element is the expression representation of the
  /// given type, or nil if the conversion is not possible because the element type does not
  /// have a valid expression representation.
  private func makeArrayTypeExpression(
    elementType: TypeSyntax,
    leftSquare: TokenSyntax,
    rightSquare: TokenSyntax
  ) -> ArrayExprSyntax? {
    guard let elementTypeExpr = expressionRepresentation(of: elementType) else {
      return nil
    }
    return ArrayExprSyntax(
      leftSquare: leftSquare,
      elements: ArrayElementListSyntax([
        ArrayElementSyntax(expression: elementTypeExpr, trailingComma: nil)
      ]),
      rightSquare: rightSquare
    )
  }

  /// Returns a `DictionaryExprSyntax` whose single key/value pair is the expression representations
  /// of the given key and value types, or nil if the conversion is not possible because either the
  /// key type or value type does not have a valid expression representation.
  private func makeDictionaryTypeExpression(
    keyType: TypeSyntax,
    valueType: TypeSyntax,
    leftSquare: TokenSyntax,
    colon: TokenSyntax,
    rightSquare: TokenSyntax
  ) -> DictionaryExprSyntax? {
    guard
      let keyTypeExpr = expressionRepresentation(of: keyType),
      let valueTypeExpr = expressionRepresentation(of: valueType)
    else {
      return nil
    }
    let dictElementList = DictionaryElementListSyntax([
      DictionaryElementSyntax(
        key: keyTypeExpr,
        colon: colon,
        value: valueTypeExpr,
        trailingComma: nil
      )
    ])
    return DictionaryExprSyntax(
      leftSquare: leftSquare,
      content: .elements(dictElementList),
      rightSquare: rightSquare
    )
  }

  /// Returns an `OptionalChainingExprSyntax` whose wrapped expression is the expression
  /// representation of the given type, or nil if the conversion is not possible because either the
  /// key type or value type does not have a valid expression representation.
  private func makeOptionalTypeExpression(
    wrapping wrappedType: TypeSyntax,
    leadingTrivia: Trivia = [],
    questionMark: TokenSyntax
  ) -> OptionalChainingExprSyntax? {
    guard var wrappedTypeExpr = expressionRepresentation(of: wrappedType) else { return nil }

    // Certain types must be wrapped in parentheses before using shorthand optional syntax to avoid
    // the "?" from binding incorrectly when re-parsed. Attach the leading trivia to the left-paren
    // that we're adding in these cases.
    switch Syntax(wrappedType).as(SyntaxEnum.self) {
    case .attributedType, .functionType, .someOrAnyType:
      wrappedTypeExpr = parenthesizedExpr(wrappedTypeExpr, leadingTrivia: leadingTrivia)
    default:
      // Otherwise, the argument type can safely become an optional by simply appending a "?". If
      // we were given leading trivia from another node (for example, from `Optional` when
      // converting a long-form to short-form), we need to transfer it over. By doing so, something
      // like `/* comment */ Optional<Foo>` will become `/* comment */ Foo?` instead of discarding
      // the comment.
      wrappedTypeExpr.leadingTrivia = leadingTrivia
    }

    return OptionalChainingExprSyntax(
      expression: wrappedTypeExpr,
      questionMark: questionMark
    )
  }

  /// Returns the given type wrapped in parentheses.
  private func parenthesizedType<TypeNode: TypeSyntaxProtocol>(
    _ typeToWrap: TypeNode,
    leadingTrivia: Trivia
  ) -> TypeSyntax {
    let tupleTypeElement = TupleTypeElementSyntax(type: TypeSyntax(typeToWrap))
    let tupleType = TupleTypeSyntax(
      leftParen: .leftParenToken(leadingTrivia: leadingTrivia),
      elements: TupleTypeElementListSyntax([tupleTypeElement]),
      rightParen: .rightParenToken()
    )
    return TypeSyntax(tupleType)
  }

  /// Returns the given expression wrapped in parentheses.
  private func parenthesizedExpr<ExprNode: ExprSyntaxProtocol>(
    _ exprToWrap: ExprNode,
    leadingTrivia: Trivia
  ) -> ExprSyntax {
    let tupleExprElement = LabeledExprSyntax(expression: exprToWrap)
    let tupleExpr = TupleExprSyntax(
      leftParen: .leftParenToken(leadingTrivia: leadingTrivia),
      elements: LabeledExprListSyntax([tupleExprElement]),
      rightParen: .rightParenToken()
    )
    return ExprSyntax(tupleExpr)
  }

  /// Returns an `ExprSyntax` that is syntactically equivalent to the given `TypeSyntax`, or nil if
  /// it wouldn't be valid.
  ///
  /// An example of an invalid expression representation for a type would be `[Int].Index`, which
  /// can be represented in the syntax tree but is not permitted by the compiler today; it must be
  /// written `Array<Int>.Index` to compile correctly.
  private func expressionRepresentation(of type: TypeSyntax) -> ExprSyntax? {
    switch Syntax(type).as(SyntaxEnum.self) {
    case .identifierType(let simpleTypeIdentifier):
      let identifierExpr = DeclReferenceExprSyntax(
        baseName: simpleTypeIdentifier.name,
        argumentNames: nil
      )

      // If the type has a generic argument clause, we need to construct a `SpecializeExpr` to wrap
      // the identifier and the generic arguments. Otherwise, we can return just the
      // `IdentifierExpr` itself.
      if let genericArgumentClause = simpleTypeIdentifier.genericArgumentClause {
        let newGenericArgumentClause = visit(genericArgumentClause)
        let result = GenericSpecializationExprSyntax(
          expression: ExprSyntax(identifierExpr),
          genericArgumentClause: newGenericArgumentClause
        )
        return ExprSyntax(result)
      } else {
        return ExprSyntax(identifierExpr)
      }

    case .memberType(let memberTypeIdentifier):
      guard let baseType = expressionRepresentation(of: memberTypeIdentifier.baseType) else {
        return nil
      }
      let result = MemberAccessExprSyntax(
        base: baseType,
        period: memberTypeIdentifier.period,
        name: memberTypeIdentifier.name
      )
      return ExprSyntax(result)

    case .arrayType(let arrayType):
      let result = makeArrayTypeExpression(
        elementType: arrayType.element,
        leftSquare: arrayType.leftSquare,
        rightSquare: arrayType.rightSquare
      )
      return ExprSyntax(result)

    case .dictionaryType(let dictionaryType):
      let result = makeDictionaryTypeExpression(
        keyType: dictionaryType.key,
        valueType: dictionaryType.value,
        leftSquare: dictionaryType.leftSquare,
        colon: dictionaryType.colon,
        rightSquare: dictionaryType.rightSquare
      )
      return ExprSyntax(result)

    case .optionalType(let optionalType):
      let result = makeOptionalTypeExpression(
        wrapping: optionalType.wrappedType,
        leadingTrivia: optionalType.firstToken(viewMode: .sourceAccurate)?.leadingTrivia ?? [],
        questionMark: optionalType.questionMark
      )
      return ExprSyntax(result)

    case .functionType(let functionType):
      let result = makeFunctionTypeExpression(
        leftParen: functionType.leftParen,
        parameters: functionType.parameters,
        rightParen: functionType.rightParen,
        effectSpecifiers: functionType.effectSpecifiers,
        arrow: functionType.returnClause.arrow,
        returnType: functionType.returnClause.type
      )
      return ExprSyntax(result)

    case .tupleType(let tupleType):
      guard let elementExprs = expressionRepresentation(of: tupleType.elements) else { return nil }
      let result = TupleExprSyntax(
        leftParen: tupleType.leftParen,
        elements: elementExprs,
        rightParen: tupleType.rightParen
      )
      return ExprSyntax(result)

    case .someOrAnyType(let someOrAnyType):
      return ExprSyntax(TypeExprSyntax(type: someOrAnyType))

    case .attributedType(let attributedType):
      return ExprSyntax(TypeExprSyntax(type: attributedType))

    default:
      return nil
    }
  }

  private func expressionRepresentation(
    of tupleTypeElements: TupleTypeElementListSyntax
  ) -> LabeledExprListSyntax? {
    guard !tupleTypeElements.isEmpty else { return nil }

    var exprElements = [LabeledExprSyntax]()
    for typeElement in tupleTypeElements {
      guard let elementExpr = expressionRepresentation(of: typeElement.type) else { return nil }
      exprElements.append(
        LabeledExprSyntax(
          label: typeElement.firstName,
          colon: typeElement.colon,
          expression: elementExpr,
          trailingComma: typeElement.trailingComma
        )
      )
    }
    return LabeledExprListSyntax(exprElements)
  }

  private func makeFunctionTypeExpression(
    leftParen: TokenSyntax,
    parameters: TupleTypeElementListSyntax,
    rightParen: TokenSyntax,
    effectSpecifiers: TypeEffectSpecifiersSyntax?,
    arrow: TokenSyntax,
    returnType: TypeSyntax
  ) -> InfixOperatorExprSyntax? {
    guard
      let parameterExprs = expressionRepresentation(of: parameters),
      let returnTypeExpr = expressionRepresentation(of: returnType)
    else {
      return nil
    }

    let tupleExpr = TupleExprSyntax(
      leftParen: leftParen,
      elements: parameterExprs,
      rightParen: rightParen
    )
    let arrowExpr = ArrowExprSyntax(
      effectSpecifiers: effectSpecifiers,
      arrow: arrow
    )
    return InfixOperatorExprSyntax(
      leftOperand: tupleExpr,
      operator: arrowExpr,
      rightOperand: returnTypeExpr
    )
  }

  /// Returns the leading and trailing trivia from the front and end of the entire given node.
  ///
  /// In other words, this is the leading trivia from the first token of the node and the trailing
  /// trivia from the last token.
  private func boundaryTrivia(
    around node: Syntax
  ) -> (leadingTrivia: Trivia, trailingTrivia: Trivia) {
    return (
      leadingTrivia: node.firstToken(viewMode: .sourceAccurate)?.leadingTrivia ?? [],
      trailingTrivia: node.lastToken(viewMode: .sourceAccurate)?.trailingTrivia ?? []
    )
  }

  /// Returns true if the given pattern binding represents a stored property/variable (as opposed to
  /// a computed property/variable).
  private func isStoredProperty(_ node: PatternBindingSyntax) -> Bool {
    guard let accessor = node.accessorBlock else {
      // If it has no accessors at all, it is definitely a stored property.
      return true
    }

    guard case .accessors(let accessors) = accessor.accessors else {
      // If the accessor isn't an `AccessorBlockSyntax`, then it is a `CodeBlockSyntax`; i.e., the
      // accessor an implicit `get`. So, it is definitely not a stored property.
      return false
    }

    for accessorDecl in accessors {
      // Look for accessors that indicate that this is a computed property. If none are found, then
      // it is a stored property (e.g., having only observers like `willSet/didSet`).
      switch accessorDecl.accessorSpecifier.tokenKind {
      case .keyword(.get),
        .keyword(.set),
        .keyword(.unsafeAddress),
        .keyword(.unsafeMutableAddress),
        .keyword(._read),
        .keyword(._modify):
        return false
      default:
        return true
      }
    }

    // This should be unreachable.
    assertionFailure("Should not have an AccessorBlock with no AccessorDecls")
    return false
  }

  /// Returns true if the given type identifier node represents the type of a mutable variable or
  /// stored property that does not have an initializer clause.
  private func isTypeOfUninitializedStoredVar(_ node: IdentifierTypeSyntax) -> Bool {
    if let typeAnnotation = node.parent?.as(TypeAnnotationSyntax.self),
      let patternBinding = nearestAncestor(of: typeAnnotation, type: PatternBindingSyntax.self),
      isStoredProperty(patternBinding),
      patternBinding.initializer == nil,
      let variableDecl = nearestAncestor(of: patternBinding, type: VariableDeclSyntax.self),
      variableDecl.bindingSpecifier.tokenKind == .keyword(.var)
    {
      return true
    }
    return false
  }

  /// Returns the node's nearest ancestor of the given type, if found; otherwise, returns nil.
  private func nearestAncestor<NodeType: SyntaxProtocol, AncestorType: SyntaxProtocol>(
    of node: NodeType,
    type: AncestorType.Type = AncestorType.self
  ) -> AncestorType? {
    var parent: Syntax? = Syntax(node)
    while let existingParent = parent {
      if existingParent.is(type) {
        return existingParent.as(type)
      }
      parent = existingParent.parent
    }
    return nil
  }
}

extension Finding.Message {
  fileprivate static func useTypeShorthand(type: String) -> Finding.Message {
    "use shorthand syntax for this '\(type)' type"
  }
}
