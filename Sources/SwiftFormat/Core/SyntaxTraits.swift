//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2025 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import SwiftSyntax

/// Common protocol implemented by expression syntax types that support calling another expression.
protocol CallingExprSyntaxProtocol: ExprSyntaxProtocol {
  var calledExpression: ExprSyntax { get }
}

extension FunctionCallExprSyntax: CallingExprSyntaxProtocol {}
extension SubscriptCallExprSyntax: CallingExprSyntaxProtocol {}

extension Syntax {
  func asProtocol(_: CallingExprSyntaxProtocol.Protocol) -> CallingExprSyntaxProtocol? {
    return self.asProtocol(SyntaxProtocol.self) as? CallingExprSyntaxProtocol
  }
  func isProtocol(_: CallingExprSyntaxProtocol.Protocol) -> Bool {
    return self.asProtocol(CallingExprSyntaxProtocol.self) != nil
  }
}

extension ExprSyntax {
  func asProtocol(_: CallingExprSyntaxProtocol.Protocol) -> CallingExprSyntaxProtocol? {
    return Syntax(self).asProtocol(SyntaxProtocol.self) as? CallingExprSyntaxProtocol
  }
  func isProtocol(_: CallingExprSyntaxProtocol.Protocol) -> Bool {
    return self.asProtocol(CallingExprSyntaxProtocol.self) != nil
  }
}

/// Common protocol implemented by expression syntax types that are expressed as a modified
/// subexpression of the form `<keyword> <subexpr>`.
protocol KeywordModifiedExprSyntaxProtocol: ExprSyntaxProtocol {
  var expression: ExprSyntax { get }
}

extension AwaitExprSyntax: KeywordModifiedExprSyntaxProtocol {}
extension TryExprSyntax: KeywordModifiedExprSyntaxProtocol {}
extension UnsafeExprSyntax: KeywordModifiedExprSyntaxProtocol {}

extension Syntax {
  func asProtocol(_: KeywordModifiedExprSyntaxProtocol.Protocol) -> KeywordModifiedExprSyntaxProtocol? {
    return self.asProtocol(SyntaxProtocol.self) as? KeywordModifiedExprSyntaxProtocol
  }
  func isProtocol(_: KeywordModifiedExprSyntaxProtocol.Protocol) -> Bool {
    return self.asProtocol(KeywordModifiedExprSyntaxProtocol.self) != nil
  }
}

extension ExprSyntax {
  func asProtocol(_: KeywordModifiedExprSyntaxProtocol.Protocol) -> KeywordModifiedExprSyntaxProtocol? {
    return Syntax(self).asProtocol(SyntaxProtocol.self) as? KeywordModifiedExprSyntaxProtocol
  }
  func isProtocol(_: KeywordModifiedExprSyntaxProtocol.Protocol) -> Bool {
    return self.asProtocol(KeywordModifiedExprSyntaxProtocol.self) != nil
  }
}

/// Common protocol implemented by comma-separated lists whose elements
/// support a `trailingComma`.
protocol CommaSeparatedListSyntaxProtocol: SyntaxCollection where Element: WithTrailingCommaSyntax & Equatable {
  /// The node used for trailing comma handling; inserted immediately after this node.
  var lastNodeForTrailingComma: SyntaxProtocol? { get }
}

extension ArrayElementListSyntax: CommaSeparatedListSyntaxProtocol {
  var lastNodeForTrailingComma: SyntaxProtocol? { last?.expression }
}
extension DictionaryElementListSyntax: CommaSeparatedListSyntaxProtocol {
  var lastNodeForTrailingComma: SyntaxProtocol? { last }
}
extension LabeledExprListSyntax: CommaSeparatedListSyntaxProtocol {
  var lastNodeForTrailingComma: SyntaxProtocol? { last?.expression }
}
extension ClosureCaptureListSyntax: CommaSeparatedListSyntaxProtocol {
  var lastNodeForTrailingComma: SyntaxProtocol? {
    if let initializer = last?.initializer {
      return initializer
    } else {
      return last?.name
    }
  }
}
extension EnumCaseParameterListSyntax: CommaSeparatedListSyntaxProtocol {
  var lastNodeForTrailingComma: SyntaxProtocol? {
    if let defaultValue = last?.defaultValue {
      return defaultValue
    } else {
      return last?.type
    }
  }
}
extension FunctionParameterListSyntax: CommaSeparatedListSyntaxProtocol {
  var lastNodeForTrailingComma: SyntaxProtocol? {
    if let defaultValue = last?.defaultValue {
      return defaultValue
    } else if let ellipsis = last?.ellipsis {
      return ellipsis
    } else {
      return last?.type
    }
  }
}
extension GenericParameterListSyntax: CommaSeparatedListSyntaxProtocol {
  var lastNodeForTrailingComma: SyntaxProtocol? {
    if let inheritedType = last?.inheritedType {
      return inheritedType
    } else {
      return last?.name
    }
  }
}
extension TuplePatternElementListSyntax: CommaSeparatedListSyntaxProtocol {
  var lastNodeForTrailingComma: SyntaxProtocol? { last?.pattern }
}

extension SyntaxProtocol {
  func asProtocol(_: (any CommaSeparatedListSyntaxProtocol).Protocol) -> (any CommaSeparatedListSyntaxProtocol)? {
    return Syntax(self).asProtocol(SyntaxProtocol.self) as? (any CommaSeparatedListSyntaxProtocol)
  }
  func isProtocol(_: (any CommaSeparatedListSyntaxProtocol).Protocol) -> Bool {
    return self.asProtocol((any CommaSeparatedListSyntaxProtocol).self) != nil
  }
}
