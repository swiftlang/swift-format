//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2024 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import SwiftSyntax

/// Empty lines are forbidden after opening braces and before closing braces.
///
/// Lint: Empty lines after opening braces and before closing braces yield a lint error.
///
/// Format: Empty lines after opening braces and before closing braces will be removed.
@_spi(Rules)
public final class NoEmptyLinesOpeningClosingBraces: SyntaxFormatRule {
  public override class var isOptIn: Bool { return true }
  
  public override func visit(_ node: AccessorBlockSyntax) -> AccessorBlockSyntax {
    var result = node
    switch node.accessors {
      case .accessors(let accessors):
        result.accessors = .init(rewritten(accessors))
      case .getter(let getter):
        result.accessors = .init(rewritten(getter))
    }
    result.rightBrace = rewritten(node.rightBrace)
    return result
  }
  
  public override func visit(_ node: CodeBlockSyntax) -> CodeBlockSyntax {
    var result = node
    result.statements = rewritten(node.statements)
    result.rightBrace = rewritten(node.rightBrace)
    return result
  }
  
  public override func visit(_ node: MemberBlockSyntax) -> MemberBlockSyntax {
    var result = node
    result.members = rewritten(node.members)
    result.rightBrace = rewritten(node.rightBrace)
    return result
  }
  
  public override func visit(_ node: ClosureExprSyntax) -> ExprSyntax {
    var result = node
    result.statements = rewritten(node.statements)
    result.rightBrace = rewritten(node.rightBrace)
    return ExprSyntax(result)
  }
  
  public override func visit(_ node: SwitchExprSyntax) -> ExprSyntax {
    var result = node
    result.cases = rewritten(node.cases)
    result.rightBrace = rewritten(node.rightBrace)
    return ExprSyntax(result)
  }
  
  public override func visit(_ node: PrecedenceGroupDeclSyntax) -> DeclSyntax {
    var result = node
    result.attributes = rewritten(node.attributes)
    result.rightBrace = rewritten(node.rightBrace)
    return DeclSyntax(result)
  }
  
  func rewritten(_ token: TokenSyntax) -> TokenSyntax {
    let (trimmedLeadingTrivia, count) = token.leadingTrivia.trimmingSuperfluousNewlines()
    if trimmedLeadingTrivia.sourceLength != token.leadingTriviaLength {
      diagnose(.removeEmptyLinesBefore(count), on: token, anchor: .start)
      return token.with(\.leadingTrivia, trimmedLeadingTrivia)
    } else {
      return token
    }
  }
  
  func rewritten<C: SyntaxCollection>(_ collection: C) -> C {
    var result = collection
    if let first = collection.first, first.leadingTrivia.containsNewlines,
       let index = collection.index(of: first)
    {
      let (trimmedLeadingTrivia, count) = first.leadingTrivia.trimmingSuperfluousNewlines()
      if trimmedLeadingTrivia.sourceLength != first.leadingTriviaLength {
        diagnose(.removeEmptyLinesAfter(count), on: first, anchor: .leadingTrivia(0))
        result[index] = first.with(\.leadingTrivia, trimmedLeadingTrivia)
      }
    }
    return rewrite(result).as(C.self)!
  }
}

extension Trivia {
  func trimmingSuperfluousNewlines() -> (Trivia, Int) {
    var trimmmed = 0
    let pieces = self.indices.reduce([TriviaPiece]()) { (partialResult, index) in
      let piece = self[index]
      // Collapse consecutive newlines into a single one
      if case .newlines(let count) = piece {
        if let last = partialResult.last, last.isNewline {
          trimmmed += count
          return partialResult
        } else {
          trimmmed += count - 1
          return partialResult + [.newlines(1)]
        }
      }
      // Remove spaces/tabs surrounded by newlines
      if piece.isSpaceOrTab, index > 0, index < self.count - 1, self[index - 1].isNewline, self[index + 1].isNewline {
        return partialResult
      }
      // Retain other trivia pieces
      return partialResult + [piece]
    }
    
    return (Trivia(pieces: pieces), trimmmed)
  }
}

extension Finding.Message {
  fileprivate static func removeEmptyLinesAfter(_ count: Int) -> Finding.Message {
    "remove empty \(count > 1 ? "lines" : "line") after '{'"
  }
  
  fileprivate static func removeEmptyLinesBefore(_ count: Int) -> Finding.Message {
    "remove empty \(count > 1 ? "lines" : "line") before '}'"
  }
}
