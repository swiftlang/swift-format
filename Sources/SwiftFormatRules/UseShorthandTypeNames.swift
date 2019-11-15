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

/// Shorthand type forms must be used wherever possible.
///
/// Lint: Using a non-shorthand form (e.g. `Array<Element>`) yields a lint error unless the long
///       form is necessary (e.g. `Array<Element>.Index` cannot be shortened.)
///
/// Format: Where possible, shorthand types replace long form types; e.g. `Array<Element>` is
///         converted to `[Element]`.
///
/// - SeeAlso: https://google.github.io/swift#types-with-shorthand-names
public final class UseShorthandTypeNames: SyntaxFormatRule {

  // Visits all potential long forms interpreted as types
  public override func visit(_ node: SimpleTypeIdentifierSyntax) -> TypeSyntax {
    // If nested in a member type identifier, type must be left in long form for the compiler
    guard let parent = node.parent, !(parent is MemberTypeIdentifierSyntax) else { return node }
    // Type is in long form if it has a non-nil generic argument clause
    guard let genArg = node.genericArgumentClause else { return node }

    // Ensure that all arguments in the clause are shortened and in expected-format by visiting
    // the argument list, first
    let argList = visit(genArg.arguments) as! GenericArgumentListSyntax
    // Store trivia of the long form type to pass to the new shorthand type later
    let trivia = retrieveTrivia(from: node)

    let newNode: TypeSyntax
    switch node.name.text {
    case "Array":
      guard let arg = argList.firstAndOnly else { return node }
      newNode = shortenArrayType(argument: arg, trivia: trivia)
    case "Dictionary":
      guard let args = exactlyTwoChildren(of: argList) else { return node }
      newNode = shortenDictionaryType(arguments: args, trivia: trivia)
    case "Optional":
      guard let arg = argList.firstAndOnly else { return node }
      newNode = shortenOptionalType(argument: arg, trivia: trivia)
    default:
      return node
    }

    diagnose(.useTypeShorthand(type: node.name.text), on: node)
    return newNode
  }

  // Visits all potential long forms interpreted as expressions
  public override func visit(_ node: SpecializeExprSyntax) -> ExprSyntax {
    let argList = visit(node.genericArgumentClause.arguments) as! GenericArgumentListSyntax
    guard let exp = node.expression as? IdentifierExprSyntax else { return node }
    let trivia = retrieveTrivia(from: node)
    switch exp.identifier.text {
    case "Array":
      guard let arg = argList.firstAndOnly else { return node }
      let newArray = shortenArrayExp(argument: arg, trivia: trivia)
      return newArray ?? node
    case "Dictionary":
      guard let args = exactlyTwoChildren(of: argList) else { return node }
      let newDictionary = shortenDictExp(arguments: args, trivia: trivia)
      return newDictionary ?? node
    default:
      break
    }
    return node
  }

  /// Returns the two arguments in the given argument list, if there are exactly two elements;
  /// otherwise, it returns nil.
  func exactlyTwoChildren(of argumentList: GenericArgumentListSyntax) -> [GenericArgumentSyntax]? {
    var iterator = argumentList.makeIterator()
    guard let first = iterator.next() else { return nil }
    guard let second = iterator.next() else { return nil }
    guard iterator.next() == nil else { return nil }
    return [first, second]
  }

  // Get type identifier from generic argument, construct shorthand array form, as a type
  func shortenArrayType(argument: GenericArgumentSyntax, trivia: (Trivia, Trivia)) -> TypeSyntax {
    let (leading, trailing) = trivia
    let leftBracket = SyntaxFactory.makeLeftSquareBracketToken(leadingTrivia: leading)
    let rightBracket = SyntaxFactory.makeRightSquareBracketToken(trailingTrivia: trailing)
    let newArray = SyntaxFactory.makeArrayType(
      leftSquareBracket: leftBracket,
      elementType: argument.argumentType,
      rightSquareBracket: rightBracket)
    return newArray
  }

  // Get type identifiers from generic arguments, construct shorthand dictionary form, as a type
  func shortenDictionaryType(arguments: [GenericArgumentSyntax], trivia: (Trivia, Trivia))
    -> TypeSyntax
  {
    let (leading, trailing) = trivia
    let leftBracket = SyntaxFactory.makeLeftSquareBracketToken(leadingTrivia: leading)
    let rightBracket = SyntaxFactory.makeRightSquareBracketToken(trailingTrivia: trailing)
    let colon = SyntaxFactory.makeColonToken(trailingTrivia: .spaces(1))
    let newDictionary = SyntaxFactory.makeDictionaryType(
      leftSquareBracket: leftBracket,
      keyType: arguments[0].argumentType,
      colon: colon,
      valueType: arguments[1].argumentType,
      rightSquareBracket: rightBracket)
    return newDictionary
  }

  // Get type identifier from generic argument, construct shorthand optional form, as a type
  func shortenOptionalType(argument: GenericArgumentSyntax, trivia: (Trivia, Trivia))
    -> TypeSyntax
  {
    let argumentType: TypeSyntax
    if let functionType = argument.argumentType as? FunctionTypeSyntax {
      // Function types must be wrapped as a tuple before using shorthand optional syntax,
      // otherwise the "?" applies to the return type instead of the function type.
      let tupleTypeElement =
        SyntaxFactory.makeTupleTypeElement(type: functionType, trailingComma: nil)
      let tupleElementList = SyntaxFactory.makeTupleTypeElementList([tupleTypeElement])
      argumentType = SyntaxFactory.makeTupleType(
        leftParen: SyntaxFactory.makeLeftParenToken(),
        elements: tupleElementList,
        rightParen: SyntaxFactory.makeRightParenToken())
    } else {
      // Otherwise, the argument type can safely become an optional by simply appending a "?".
      argumentType = argument.argumentType
    }
    let (_, trailing) = trivia
    let questionMark = SyntaxFactory.makePostfixQuestionMarkToken(trailingTrivia: trailing)
    let newOptional =
      SyntaxFactory.makeOptionalType(wrappedType: argumentType, questionMark: questionMark)
    return newOptional
  }

  // Construct an array expression from type information in the generic argument
  func shortenArrayExp(argument arg: GenericArgumentSyntax, trivia: (Trivia, Trivia))
    -> ArrayExprSyntax?
  {
    var element = SyntaxFactory.makeBlankArrayElement()

    // Type id can be in a simple type identifier (ex: Int)
    if let simpleId = arg.argumentType as? SimpleTypeIdentifierSyntax {
      let idExp = SyntaxFactory.makeIdentifierExpr(
        identifier: simpleId.name,
        declNameArguments: nil)
      element = SyntaxFactory.makeArrayElement(expression: idExp, trailingComma: nil)
      // Type id can be in a long form array (ex: Array<Int>.Index)
    } else if let memberTypeId = arg.argumentType as? MemberTypeIdentifierSyntax {
      guard let memberAccessExp = restructureLongForm(member: memberTypeId) else { return nil }
      element = SyntaxFactory.makeArrayElement(expression: memberAccessExp, trailingComma: nil)
      // Type id can be in an array, dictionary, or optional type (ex: [Int], [String: Int], Int?)
    } else if arg.argumentType is ArrayTypeSyntax || arg.argumentType is DictionaryTypeSyntax || arg
      .argumentType is OptionalTypeSyntax
    {
      if let newExp = restructureTypeSyntax(type: arg.argumentType) {
        element = SyntaxFactory.makeArrayElement(expression: newExp, trailingComma: nil)
      }
    } else { return nil }

    let elementList = SyntaxFactory.makeArrayElementList([element])
    let (leading, trailing) = trivia
    let leftBracket = SyntaxFactory.makeLeftSquareBracketToken(leadingTrivia: leading)
    let rightBracket = SyntaxFactory.makeRightSquareBracketToken(trailingTrivia: trailing)
    let arrayExp = SyntaxFactory.makeArrayExpr(
      leftSquare: leftBracket,
      elements: elementList,
      rightSquare: rightBracket)
    return arrayExp
  }

  // Construct a dictionary expression from type information in the generic arguments
  func shortenDictExp(arguments: [GenericArgumentSyntax], trivia: (Trivia, Trivia))
    -> DictionaryExprSyntax?
  {
    let blank = SyntaxFactory.makeBlankIdentifierExpr()
    let colon = SyntaxFactory.makeColonToken(trailingTrivia: .spaces(1))
    var element = SyntaxFactory.makeDictionaryElement(
      keyExpression: blank,
      colon: colon,
      valueExpression: blank,
      trailingComma: nil)
    // Get type id, create an expression, add to the dictionary element
    for (idx, arg) in arguments.enumerated() {
      if let simpleId = arg.argumentType as? SimpleTypeIdentifierSyntax {
        let idExp = SyntaxFactory.makeIdentifierExpr(
          identifier: simpleId.name,
          declNameArguments: nil)
        element = idx == 0 ? element.withKeyExpression(idExp) : element.withValueExpression(idExp)
      } else if let memberTypeId = arg.argumentType as? MemberTypeIdentifierSyntax {
        guard let memberAccessExp = restructureLongForm(member: memberTypeId) else { return nil }
        element = idx == 0
          ? element.withKeyExpression(memberAccessExp) : element.withValueExpression(
            memberAccessExp)
      } else if arg.argumentType is ArrayTypeSyntax || arg.argumentType is DictionaryTypeSyntax
        || arg.argumentType is OptionalTypeSyntax
      {
        let newExp = restructureTypeSyntax(type: arg.argumentType)
        element = idx == 0 ? element.withKeyExpression(newExp) : element.withValueExpression(newExp)
      } else { return nil }
    }

    let elementList = SyntaxFactory.makeDictionaryElementList([element])
    let (leading, trailing) = trivia
    let leftBracket = SyntaxFactory.makeLeftSquareBracketToken(leadingTrivia: leading)
    let rightBracket = SyntaxFactory.makeRightSquareBracketToken(trailingTrivia: trailing)
    let dictExp = SyntaxFactory.makeDictionaryExpr(
      leftSquare: leftBracket,
      content: elementList,
      rightSquare: rightBracket)
    return dictExp
  }

  // Convert member type identifier to an equivalent member access expression
  // The node will appear the same, but the structure of the tree is different
  func restructureLongForm(member: MemberTypeIdentifierSyntax) -> MemberAccessExprSyntax? {
    guard let simpleTypeId = member.baseType as? SimpleTypeIdentifierSyntax else { return nil }
    guard let genArgClause = simpleTypeId.genericArgumentClause else { return nil }
    // Node will only change if an argument in the generic argument clause is shortened
    let argClause = visit(genArgClause) as! GenericArgumentClauseSyntax
    let idExp = SyntaxFactory.makeIdentifierExpr(
      identifier: simpleTypeId.name,
      declNameArguments: nil)
    let specialExp = SyntaxFactory.makeSpecializeExpr(
      expression: idExp,
      genericArgumentClause: argClause)
    let memberAccessExp = SyntaxFactory.makeMemberAccessExpr(
      base: specialExp,
      dot: member.period,
      name: member.name,
      declNameArguments: nil)
    return memberAccessExp
  }

  // Convert array, dictionary, or optional type to an equivalent expression
  // The node will appear the same, but the structure of the tree is different
  func restructureTypeSyntax(type: TypeSyntax) -> ExprSyntax? {
    if let arrayType = type as? ArrayTypeSyntax {
      let type = arrayType.elementType.description.trimmingCharacters(in: .whitespacesAndNewlines)
      let typeId = SyntaxFactory.makeIdentifier(type)
      let id = SyntaxFactory.makeIdentifierExpr(
        identifier: typeId,
        declNameArguments: nil)
      let element = SyntaxFactory.makeArrayElement(expression: id, trailingComma: nil)
      let elementList = SyntaxFactory.makeArrayElementList([element])
      let arrayExp = SyntaxFactory.makeArrayExpr(
        leftSquare: arrayType.leftSquareBracket,
        elements: elementList,
        rightSquare: arrayType.rightSquareBracket)
      return arrayExp
    } else if let dictType = type as? DictionaryTypeSyntax {
      let keyType = dictType.keyType.description.trimmingCharacters(in: .whitespacesAndNewlines)
      let keyTypeId = SyntaxFactory.makeIdentifier(keyType)
      let keyIdExp = SyntaxFactory.makeIdentifierExpr(identifier: keyTypeId, declNameArguments: nil)
      let valueType = dictType.valueType.description.trimmingCharacters(in: .whitespacesAndNewlines)
      let valueTypeId = SyntaxFactory.makeIdentifier(valueType)
      let valueIdExp = SyntaxFactory.makeIdentifierExpr(
        identifier: valueTypeId,
        declNameArguments: nil)
      let element = SyntaxFactory.makeDictionaryElement(
        keyExpression: keyIdExp,
        colon: dictType.colon,
        valueExpression: valueIdExp,
        trailingComma: nil)
      let elementList = SyntaxFactory.makeDictionaryElementList([element])
      let dictExp = SyntaxFactory.makeDictionaryExpr(
        leftSquare: dictType.leftSquareBracket,
        content: elementList,
        rightSquare: dictType.rightSquareBracket)
      return dictExp
    } else if let optionalType = type as? OptionalTypeSyntax {
      let type = optionalType.wrappedType.description.trimmingCharacters(
        in: .whitespacesAndNewlines)
      let typeId = SyntaxFactory.makeIdentifier(type)
      let idExp = SyntaxFactory.makeIdentifierExpr(identifier: typeId, declNameArguments: nil)
      let optionalExp = SyntaxFactory.makeOptionalChainingExpr(
        expression: idExp,
        questionMark: optionalType.questionMark)
      return optionalExp
    }
    return nil
  }

  // Returns trivia from the front and end of the entire given node
  func retrieveTrivia(from node: Syntax) -> (Trivia, Trivia) {
    guard let firstTok = node.firstToken, let lastTok = node.lastToken else { return ([], []) }
    return (firstTok.leadingTrivia, lastTok.trailingTrivia)
  }
}

extension Diagnostic.Message {
  static func useTypeShorthand(type: String) -> Diagnostic.Message {
    return .init(.warning, "use \(type) type shorthand form")
  }
}
