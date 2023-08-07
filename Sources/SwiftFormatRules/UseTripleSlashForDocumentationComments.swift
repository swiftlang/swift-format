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

/// Documentation comments must use the `///` form.
///
/// This is similar to `NoBlockComments` but is meant to prevent documentation block comments.
///
/// Lint: If a doc block comment appears, a lint error is raised.
///
/// Format: If a doc block comment appears on its own on a line, or if a doc block comment spans
///         multiple lines without appearing on the same line as code, it will be replaced with
///         multiple doc line comments.
public final class UseTripleSlashForDocumentationComments: SyntaxFormatRule {
  public override func visit(_ node: FunctionDeclSyntax) -> DeclSyntax {
    return convertDocBlockCommentToDocLineComment(DeclSyntax(node))
  }

  public override func visit(_ node: EnumDeclSyntax) -> DeclSyntax {
    return convertDocBlockCommentToDocLineComment(DeclSyntax(node))
  }

  public override func visit(_ node: InitializerDeclSyntax) -> DeclSyntax {
    return convertDocBlockCommentToDocLineComment(DeclSyntax(node))
  }

  public override func visit(_ node: DeinitializerDeclSyntax) -> DeclSyntax {
    return convertDocBlockCommentToDocLineComment(DeclSyntax(node))
  }

  public override func visit(_ node: SubscriptDeclSyntax) -> DeclSyntax {
    return convertDocBlockCommentToDocLineComment(DeclSyntax(node))
  }

  public override func visit(_ node: ClassDeclSyntax) -> DeclSyntax {
    return convertDocBlockCommentToDocLineComment(DeclSyntax(node))
  }

  public override func visit(_ node: VariableDeclSyntax) -> DeclSyntax {
    return convertDocBlockCommentToDocLineComment(DeclSyntax(node))
  }

  public override func visit(_ node: StructDeclSyntax) -> DeclSyntax {
    return convertDocBlockCommentToDocLineComment(DeclSyntax(node))
  }

  public override func visit(_ node: ProtocolDeclSyntax) -> DeclSyntax {
    return convertDocBlockCommentToDocLineComment(DeclSyntax(node))
  }

  public override func visit(_ node: TypeAliasDeclSyntax) -> DeclSyntax {
    return convertDocBlockCommentToDocLineComment(DeclSyntax(node))
  }

  public override func visit(_ node: ExtensionDeclSyntax) -> DeclSyntax {
    return convertDocBlockCommentToDocLineComment(DeclSyntax(node))
  }

  /// If the declaration has a doc block comment, return the declaration with the comment rewritten
  /// as a line comment.
  ///
  /// If the declaration had no comment or had only line comments, it is returned unchanged.
  private func convertDocBlockCommentToDocLineComment(_ decl: DeclSyntax) -> DeclSyntax {
    guard
      let commentInfo = DocumentationCommentText(extractedFrom: decl.leadingTrivia),
      commentInfo.introducer != .line
    else {
      return decl
    }

    // Keep any trivia leading up to the doc comment.
    var pieces = Array(decl.leadingTrivia[..<commentInfo.startIndex])

    // If the comment text ends with a newline, remove it so that we don't end up with an extra
    // blank line after splitting.
    var text = commentInfo.text[...]
    if text.hasSuffix("\n") {
      text = text.dropLast(1)
    }

    // Append each line of the doc comment with `///` prefixes.
    for line in text.split(separator: "\n", omittingEmptySubsequences: false) {
      var newLine = "///"
      if !line.isEmpty {
        newLine.append(" \(line)")
      }
      pieces.append(.docLineComment(newLine))
      pieces.append(.newlines(1))
    }

    return replaceTrivia(
      on: decl,
      token: decl.firstToken(viewMode: .sourceAccurate),
      leadingTrivia: Trivia(pieces: pieces)
    )
  }
}

extension Finding.Message {
  public static let avoidDocBlockComment: Finding.Message =
    "replace documentation block comments with documentation line comments"
}
