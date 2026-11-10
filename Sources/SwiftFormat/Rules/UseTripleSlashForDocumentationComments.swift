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
import SwiftSyntax

/// Documentation comments must use the `///` form.
///
/// This is similar to `NoBlockComments` but is meant to prevent documentation block comments.
///
/// Lint: If a doc block comment appears, a lint error is raised.
///
/// Format: If a doc block comment appears on its own on a line, or if a doc block comment spans
///         multiple lines without appearing on the same line as code, it will be replaced with
///         multiple doc line comments.
@_spi(Rules)
public final class UseTripleSlashForDocumentationComments: SyntaxFormatRule {
  public override func visit(_ node: FunctionDeclSyntax) -> DeclSyntax {
    return convertDocBlockCommentToDocLineComment(node, visitChildren: super.visit)
  }

  public override func visit(_ node: EnumDeclSyntax) -> DeclSyntax {
    return convertDocBlockCommentToDocLineComment(node, visitChildren: super.visit)
  }

  public override func visit(_ node: InitializerDeclSyntax) -> DeclSyntax {
    return convertDocBlockCommentToDocLineComment(node, visitChildren: super.visit)
  }

  public override func visit(_ node: DeinitializerDeclSyntax) -> DeclSyntax {
    return convertDocBlockCommentToDocLineComment(node, visitChildren: super.visit)
  }

  public override func visit(_ node: SubscriptDeclSyntax) -> DeclSyntax {
    return convertDocBlockCommentToDocLineComment(node, visitChildren: super.visit)
  }

  public override func visit(_ node: ClassDeclSyntax) -> DeclSyntax {
    return convertDocBlockCommentToDocLineComment(node, visitChildren: super.visit)
  }

  public override func visit(_ node: VariableDeclSyntax) -> DeclSyntax {
    return convertDocBlockCommentToDocLineComment(node, visitChildren: super.visit)
  }

  public override func visit(_ node: StructDeclSyntax) -> DeclSyntax {
    return convertDocBlockCommentToDocLineComment(node, visitChildren: super.visit)
  }

  public override func visit(_ node: ProtocolDeclSyntax) -> DeclSyntax {
    return convertDocBlockCommentToDocLineComment(node, visitChildren: super.visit)
  }

  public override func visit(_ node: TypeAliasDeclSyntax) -> DeclSyntax {
    return convertDocBlockCommentToDocLineComment(node, visitChildren: super.visit)
  }

  public override func visit(_ node: ExtensionDeclSyntax) -> DeclSyntax {
    return convertDocBlockCommentToDocLineComment(node, visitChildren: super.visit)
  }

  /// If the declaration has a doc block comment, return the declaration with the comment rewritten
  /// as a line comment.
  ///
  /// If the declaration had no comment or had only line comments, it is returned unchanged (apart
  /// from any rewritten child declarations).
  private func convertDocBlockCommentToDocLineComment<Node: DeclSyntaxProtocol>(
    _ node: Node,
    visitChildren: (Node) -> DeclSyntax
  ) -> DeclSyntax {
    let rewrittenTrivia = rewrittenDocCommentLeadingTrivia(for: DeclSyntax(node))
    var result = visitChildren(node)
    if let rewrittenTrivia {
      result.leadingTrivia = rewrittenTrivia
    }
    return result
  }

  private func rewrittenDocCommentLeadingTrivia(for decl: DeclSyntax) -> Trivia? {
    guard
      let commentInfo = DocumentationCommentText(extractedFrom: decl.leadingTrivia),
      commentInfo.introducer != .line
    else {
      return nil
    }

    let commentStart = decl.position(ofLeadingTriviaAt: commentInfo.startIndex)
    let commentEnd = commentStart + decl.leadingTrivia[commentInfo.startIndex].sourceLength
    guard shouldFormat(decl, triviaRange: commentStart..<commentEnd) else {
      return nil
    }

    diagnose(.avoidDocBlockComment, on: decl, anchor: .leadingTrivia(commentInfo.startIndex))

    // Keep any trivia leading up to the doc comment.
    var pieces = Array(decl.leadingTrivia[..<commentInfo.startIndex])
    let commentIndentation: TriviaPiece?
    if let lastBeforeComment = pieces.last, lastBeforeComment.isSpaceOrTab {
      commentIndentation = lastBeforeComment
    } else {
      commentIndentation = nil
    }
    let declIndentation: TriviaPiece?
    if let lastPiece = decl.leadingTrivia.pieces.last, lastPiece.isSpaceOrTab {
      declIndentation = lastPiece
    } else {
      declIndentation = nil
    }

    // If the comment text ends with a newline, remove it so that we don't end up with an extra
    // blank line after splitting.
    var text = commentInfo.text[...]
    if text.hasSuffix("\n") {
      text = text.dropLast(1)
    }

    // Append each line of the doc comment with `///` prefixes.
    let lines = text.split(separator: "\n", omittingEmptySubsequences: false)
    for (index, line) in lines.enumerated() {
      if index > 0, let commentIndentation {
        pieces.append(commentIndentation)
      }
      var newLine = "///"
      if !line.isEmpty {
        newLine.append(" \(line)")
      }
      pieces.append(.docLineComment(newLine))
      pieces.append(.newlines(1))
    }
    if let declIndentation {
      pieces.append(declIndentation)
    }

    return Trivia(pieces: pieces)
  }
}

extension Finding.Message {
  fileprivate static let avoidDocBlockComment: Finding.Message =
    "replace documentation block comments with documentation line comments"
}
