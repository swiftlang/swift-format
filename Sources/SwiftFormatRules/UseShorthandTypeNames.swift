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

// FIXME: Remove this once we've completely moved up to a version of SwiftSyntax that has
// switched over to TupleExprElement nodes.
#if !HAS_CONSOLIDATED_TUPLE_AND_FUNCTION_CALL_SYNTAX
fileprivate typealias TupleExprElementListSyntax = TupleElementListSyntax
fileprivate typealias TupleExprElementSyntax = TupleElementSyntax

extension SyntaxFactory {
  fileprivate static func makeTupleExprElementList(_ elements: [TupleExprElementSyntax])
    -> TupleExprElementListSyntax
  {
    return makeTupleElementList(elements)
  }

  fileprivate static func makeTupleExprElement(
    label: TokenSyntax?, colon: TokenSyntax?, expression: ExprSyntax, trailingComma: TokenSyntax?
  ) -> TupleExprElementSyntax {
    return makeTupleElement(
      label: label, colon: colon, expression: expression, trailingComma: trailingComma)
  }
}
#endif

/// Shorthand type forms must be used wherever possible.
///
/// Lint: Using a non-shorthand form (e.g. `Array<Element>`) yields a lint error unless the long
///       form is necessary (e.g. `Array<Element>.Index` cannot be shortened today.)
///
/// Format: Where possible, shorthand types replace long form types; e.g. `Array<Element>` is
///         converted to `[Element]`.
///
/// - SeeAlso: https://google.github.io/swift#types-with-shorthand-names
public final class UseShorthandTypeNames: SyntaxFormatRule {

  public override func visit(_ node: SimpleTypeIdentifierSyntax) -> TypeSyntax {
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
    guard let parent = node.parent, !(parent is MemberTypeIdentifierSyntax) else {
      return super.visit(node)
    }

    // Ensure that all arguments in the clause are shortened and in the expected format by visiting
    // the argument list, first.
    let genericArgumentList = visit(genericArgumentClause.arguments) as! GenericArgumentListSyntax

    let (leadingTrivia, trailingTrivia) = boundaryTrivia(around: node)
    let newNode: TypeSyntax?

    switch node.name.text {
    case "Array":
      guard let typeArgument = genericArgumentList.firstAndOnly else {
        newNode = nil
        break
      }
      newNode = shorthandArrayType(
        element: typeArgument.argumentType,
        leadingTrivia: leadingTrivia,
        trailingTrivia: trailingTrivia)

    case "Dictionary":
      guard let typeArguments = exactlyTwoChildren(of: genericArgumentList) else {
        newNode = nil
        break
      }
      newNode = shorthandDictionaryType(
        key: typeArguments.0.argumentType,
        value: typeArguments.1.argumentType,
        leadingTrivia: leadingTrivia,
        trailingTrivia: trailingTrivia)

    case "Optional":
      guard let typeArgument = genericArgumentList.firstAndOnly else {
        newNode = nil
        break
      }
      newNode = shorthandOptionalType(
        wrapping: typeArgument.argumentType,
        leadingTrivia: leadingTrivia,
        trailingTrivia: trailingTrivia)

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
    return node.withGenericArgumentClause(
      genericArgumentClause.withArguments(genericArgumentList))
  }

  public override func visit(_ node: SpecializeExprSyntax) -> ExprSyntax {
    // `SpecializeExpr`s are found in the syntax tree when a generic type is encountered in an
    // expression context, such as `Array<Int>()`. In these situations, the corresponding array and
    // dictionary shorthand nodes will be expression nodes, not type nodes, so we may need to
    // translate the arguments inside the generic argument list---which are types---to the
    // appropriate equivalent.

    // Ignore nodes where the expression being specialized isn't a simple identifier.
    guard let expression = node.expression as? IdentifierExprSyntax else {
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
    guard let parent = node.parent, !(parent is MemberAccessExprSyntax) else {
      return super.visit(node)
    }

    // Ensure that all arguments in the clause are shortened and in the expected format by visiting
    // the argument list, first.
    let genericArgumentList =
      visit(node.genericArgumentClause.arguments) as! GenericArgumentListSyntax

    let (leadingTrivia, trailingTrivia) = boundaryTrivia(around: node)
    let newNode: ExprSyntax?

    switch expression.identifier.text {
    case "Array":
      guard let typeArgument = genericArgumentList.firstAndOnly else {
        newNode = nil
        break
      }
      newNode = makeArrayTypeExpression(
        elementType: typeArgument.argumentType,
        leftSquareBracket: SyntaxFactory.makeLeftSquareBracketToken(leadingTrivia: leadingTrivia),
        rightSquareBracket:
          SyntaxFactory.makeRightSquareBracketToken(trailingTrivia: trailingTrivia))

    case "Dictionary":
      guard let typeArguments = exactlyTwoChildren(of: genericArgumentList) else {
        newNode = nil
        break
      }
      newNode = makeDictionaryTypeExpression(
        keyType: typeArguments.0.argumentType,
        valueType: typeArguments.1.argumentType,
        leftSquareBracket: SyntaxFactory.makeLeftSquareBracketToken(leadingTrivia: leadingTrivia),
        colon: SyntaxFactory.makeColonToken(trailingTrivia: .spaces(1)),
        rightSquareBracket:
          SyntaxFactory.makeRightSquareBracketToken(trailingTrivia: trailingTrivia))

    case "Optional":
      guard let typeArgument = genericArgumentList.firstAndOnly else {
        newNode = nil
        break
      }
      newNode = makeOptionalTypeExpression(
        wrapping: typeArgument.argumentType,
        leadingTrivia: leadingTrivia,
        questionMark: SyntaxFactory.makePostfixQuestionMarkToken(trailingTrivia: trailingTrivia))

    default:
      newNode = nil
    }

    if let newNode = newNode {
      diagnose(.useTypeShorthand(type: expression.identifier.text), on: expression)
      return newNode
    }

    // Even if we don't shorten this specific expression that we're visiting, we may have
    // rewritten something in the generic argument list that we recursively visited, so return the
    // original node with that swapped out.
    return node.withGenericArgumentClause(
      node.genericArgumentClause.withArguments(genericArgumentList))
  }

  /// Returns the two arguments in the given argument list, if there are exactly two elements;
  /// otherwise, it returns nil.
  private func exactlyTwoChildren(of argumentList: GenericArgumentListSyntax)
    -> (GenericArgumentSyntax, GenericArgumentSyntax)?
  {
    var iterator = argumentList.makeIterator()
    guard let first = iterator.next() else { return nil }
    guard let second = iterator.next() else { return nil }
    guard iterator.next() == nil else { return nil }
    return (first, second)
  }

  /// Retuns a `TypeSyntax` representing a shorthand array type (e.g., `[Foo]`) with the given
  /// element type and trivia.
  private func shorthandArrayType(
    element: TypeSyntax,
    leadingTrivia: Trivia,
    trailingTrivia: Trivia
  ) -> TypeSyntax {
    return SyntaxFactory.makeArrayType(
      leftSquareBracket: SyntaxFactory.makeLeftSquareBracketToken(leadingTrivia: leadingTrivia),
      elementType: element,
      rightSquareBracket: SyntaxFactory.makeRightSquareBracketToken(trailingTrivia: trailingTrivia))
  }

  /// Returns a `TypeSyntax` representing a shorthand dictionary type (e.g., `[Foo: Bar]`) with the
  /// given key/value types and trivia.
  private func shorthandDictionaryType(
    key: TypeSyntax,
    value: TypeSyntax,
    leadingTrivia: Trivia,
    trailingTrivia: Trivia
  ) -> TypeSyntax {
    return SyntaxFactory.makeDictionaryType(
      leftSquareBracket: SyntaxFactory.makeLeftSquareBracketToken(leadingTrivia: leadingTrivia),
      keyType: key,
      colon: SyntaxFactory.makeColonToken(trailingTrivia: .spaces(1)),
      valueType: value,
      rightSquareBracket: SyntaxFactory.makeRightSquareBracketToken(trailingTrivia: trailingTrivia))
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

    if let functionType = wrappedType as? FunctionTypeSyntax {
      // Function types must be wrapped as a tuple before using shorthand optional syntax,
      // otherwise the "?" applies to the return type instead of the function type. Attach the
      // leading trivia to the left-paren that we're adding in this case.
      let tupleTypeElement =
        SyntaxFactory.makeTupleTypeElement(type: functionType, trailingComma: nil)
      let tupleTypeElementList = SyntaxFactory.makeTupleTypeElementList([tupleTypeElement])
      wrappedType = SyntaxFactory.makeTupleType(
        leftParen: SyntaxFactory.makeLeftParenToken(leadingTrivia: leadingTrivia),
        elements: tupleTypeElementList,
        rightParen: SyntaxFactory.makeRightParenToken())
    } else {
      // Otherwise, the argument type can safely become an optional by simply appending a "?", but
      // we need to transfer the leading trivia from the original `Optional` token over to it.
      // By doing so, something like `/* comment */ Optional<Foo>` will become `/* comment */ Foo?`
      // instead of discarding the comment.
      wrappedType =
        replaceTrivia(
          on: wrappedType, token: wrappedType.firstToken, leadingTrivia: leadingTrivia)
        as! TypeSyntax
    }

    return SyntaxFactory.makeOptionalType(
      wrappedType: wrappedType,
      questionMark: SyntaxFactory.makePostfixQuestionMarkToken(trailingTrivia: trailingTrivia))
  }

  /// Returns an `ArrayExprSyntax` whose single element is the expression representation of the
  /// given type, or nil if the conversion is not possible because the element type does not
  /// have a valid expression representation.
  private func makeArrayTypeExpression(
    elementType: TypeSyntax,
    leftSquareBracket: TokenSyntax,
    rightSquareBracket: TokenSyntax
  ) -> ArrayExprSyntax? {
    guard let elementTypeExpr = expressionRepresentation(of: elementType) else {
      return nil
    }
    return SyntaxFactory.makeArrayExpr(
      leftSquare: leftSquareBracket,
      elements: SyntaxFactory.makeArrayElementList([
        SyntaxFactory.makeArrayElement(expression: elementTypeExpr, trailingComma: nil),
      ]),
      rightSquare: rightSquareBracket)
  }

  /// Returns a `DictionaryExprSyntax` whose single key/value pair is the expression representations
  /// of the given key and value types, or nil if the conversion is not possible because either the
  /// key type or value type does not have a valid expression representation.
  private func makeDictionaryTypeExpression(
    keyType: TypeSyntax,
    valueType: TypeSyntax,
    leftSquareBracket: TokenSyntax,
    colon: TokenSyntax,
    rightSquareBracket: TokenSyntax
  ) -> DictionaryExprSyntax? {
    guard
      let keyTypeExpr = expressionRepresentation(of: keyType),
      let valueTypeExpr = expressionRepresentation(of: valueType)
    else {
      return nil
    }
    return SyntaxFactory.makeDictionaryExpr(
      leftSquare: leftSquareBracket,
      content: SyntaxFactory.makeDictionaryElementList([
        SyntaxFactory.makeDictionaryElement(
          keyExpression: keyTypeExpr,
          colon: colon,
          valueExpression: valueTypeExpr,
          trailingComma: nil),
      ]),
      rightSquare: rightSquareBracket)
  }

  /// Returns an `OptionalChainingExprSyntax` whose wrapped expression is the expression
  /// representation of the given type, or nil if the conversion is not possible because either the
  /// key type or value type does not have a valid expression representation.
  private func makeOptionalTypeExpression(
    wrapping wrappedType: TypeSyntax,
    leadingTrivia: Trivia? = nil,
    questionMark: TokenSyntax
  ) -> OptionalChainingExprSyntax? {
    guard var wrappedTypeExpr = expressionRepresentation(of: wrappedType) else { return nil }

    if wrappedType is FunctionTypeSyntax {
      // Function types must be wrapped as a tuple before using shorthand optional syntax,
      // otherwise the "?" applies to the return type instead of the function type. Attach the
      // leading trivia to the left-paren that we're adding in this case.
      let tupleExprElement =
        SyntaxFactory.makeTupleExprElement(
          label: nil, colon: nil, expression: wrappedTypeExpr, trailingComma: nil)
      let tupleExprElementList = SyntaxFactory.makeTupleExprElementList([tupleExprElement])
      wrappedTypeExpr = SyntaxFactory.makeTupleExpr(
        leftParen: SyntaxFactory.makeLeftParenToken(leadingTrivia: leadingTrivia ?? []),
        elementList: tupleExprElementList,
        rightParen: SyntaxFactory.makeRightParenToken())
    } else if let leadingTrivia = leadingTrivia {
      // Otherwise, the argument type can safely become an optional by simply appending a "?". If
      // we were given leading trivia from another node (for example, from `Optional` when
      // converting a long-form to short-form), we need to transfer it over. By doing so, something
      // like `/* comment */ Optional<Foo>` will become `/* comment */ Foo?` instead of discarding
      // the comment.
      wrappedTypeExpr =
        replaceTrivia(
          on: wrappedTypeExpr, token: wrappedTypeExpr.firstToken, leadingTrivia: leadingTrivia)
        as! ExprSyntax
    }

    return SyntaxFactory.makeOptionalChainingExpr(
      expression: wrappedTypeExpr,
      questionMark: questionMark)
  }

  /// Returns an `ExprSyntax` that is syntactically equivalent to the given `TypeSyntax`, or nil if
  /// it wouldn't be valid.
  ///
  /// An example of an invalid expression representation for a type would be `[Int].Index`, which
  /// can be represented in the syntax tree but is not permitted by the compiler today; it must be
  /// written `Array<Int>.Index` to compile correctly.
  private func expressionRepresentation(of type: TypeSyntax) -> ExprSyntax? {
    switch type {
    case let simpleTypeIdentifier as SimpleTypeIdentifierSyntax:
      let identifierExpr = SyntaxFactory.makeIdentifierExpr(
        identifier: simpleTypeIdentifier.name,
        declNameArguments: nil)

      // If the type has a generic argument clause, we need to construct a `SpecializeExpr` to wrap
      // the identifier and the generic arguments. Otherwise, we can return just the
      // `IdentifierExpr` itself.
      if let genericArgumentClause = simpleTypeIdentifier.genericArgumentClause {
        let newGenericArgumentClause = visit(genericArgumentClause) as! GenericArgumentClauseSyntax
        return SyntaxFactory.makeSpecializeExpr(
          expression: identifierExpr,
          genericArgumentClause: newGenericArgumentClause)
      } else {
        return identifierExpr
      }

    case let memberTypeIdentifier as MemberTypeIdentifierSyntax:
      guard let baseType = expressionRepresentation(of: memberTypeIdentifier.baseType) else {
        return nil
      }
      return SyntaxFactory.makeMemberAccessExpr(
        base: baseType,
        dot: memberTypeIdentifier.period,
        name: memberTypeIdentifier.name,
        declNameArguments: nil)

    case let arrayType as ArrayTypeSyntax:
      return makeArrayTypeExpression(
        elementType: arrayType.elementType,
        leftSquareBracket: arrayType.leftSquareBracket,
        rightSquareBracket: arrayType.rightSquareBracket)

    case let dictionaryType as DictionaryTypeSyntax:
      return makeDictionaryTypeExpression(
        keyType: dictionaryType.keyType,
        valueType: dictionaryType.valueType,
        leftSquareBracket: dictionaryType.leftSquareBracket,
        colon: dictionaryType.colon,
        rightSquareBracket: dictionaryType.rightSquareBracket)

    case let optionalType as OptionalTypeSyntax:
      return makeOptionalTypeExpression(
        wrapping: optionalType.wrappedType,
        leadingTrivia: optionalType.firstToken?.leadingTrivia,
        questionMark: optionalType.questionMark)

    case let functionType as FunctionTypeSyntax:
      return makeFunctionTypeExpression(
        leftParen: functionType.leftParen,
        argumentTypes: functionType.arguments,
        rightParen: functionType.rightParen,
        throwsOrRethrowsKeyword: functionType.throwsOrRethrowsKeyword,
        arrow: functionType.arrow,
        returnType: functionType.returnType
      )

    case let tupleType as TupleTypeSyntax:
      guard let elementExprs = expressionRepresentation(of: tupleType.elements) else { return nil }
      return SyntaxFactory.makeTupleExpr(
        leftParen: tupleType.leftParen,
        elementList: elementExprs,
        rightParen: tupleType.rightParen)

    default:
      return nil
    }
  }

  private func expressionRepresentation(of tupleTypeElements: TupleTypeElementListSyntax)
    -> TupleExprElementListSyntax?
  {
    guard !tupleTypeElements.isEmpty else { return nil }

    var exprElements = [TupleExprElementSyntax]()
    for typeElement in tupleTypeElements {
      guard let elementExpr = expressionRepresentation(of: typeElement.type) else { return nil }
      exprElements.append(
        SyntaxFactory.makeTupleExprElement(
          label: typeElement.name,
          colon: typeElement.colon,
          expression: elementExpr,
          trailingComma: typeElement.trailingComma))
    }
    return SyntaxFactory.makeTupleExprElementList(exprElements)
  }

  private func makeFunctionTypeExpression(
    leftParen: TokenSyntax,
    argumentTypes: TupleTypeElementListSyntax,
    rightParen: TokenSyntax,
    throwsOrRethrowsKeyword: TokenSyntax?,
    arrow: TokenSyntax,
    returnType: TypeSyntax
  ) -> SequenceExprSyntax? {
    guard
      let argumentTypeExprs = expressionRepresentation(of: argumentTypes),
      let returnTypeExpr = expressionRepresentation(of: returnType)
    else {
      return nil
    }

    return SyntaxFactory.makeSequenceExpr(
      elements: SyntaxFactory.makeExprList([
        SyntaxFactory.makeTupleExpr(
          leftParen: leftParen,
          elementList: argumentTypeExprs,
          rightParen: rightParen),
        SyntaxFactory.makeArrowExpr(
          throwsToken: throwsOrRethrowsKeyword,
          arrowToken: arrow),
        returnTypeExpr,
      ]))
  }

  /// Returns the leading and trailing trivia from the front and end of the entire given node.
  ///
  /// In other words, this is the leading trivia from the first token of the node and the trailing
  /// trivia from the last token.
  private func boundaryTrivia(around node: Syntax)
    -> (leadingTrivia: Trivia, trailingTrivia: Trivia)
  {
    return (
      leadingTrivia: node.firstToken?.leadingTrivia ?? [],
      trailingTrivia: node.lastToken?.trailingTrivia ?? []
    )
  }
}

extension Diagnostic.Message {
  static func useTypeShorthand(type: String) -> Diagnostic.Message {
    return .init(.warning, "use \(type) type shorthand form")
  }
}
