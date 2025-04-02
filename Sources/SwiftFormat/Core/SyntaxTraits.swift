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
