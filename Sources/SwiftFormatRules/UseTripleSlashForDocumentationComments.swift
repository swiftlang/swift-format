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
/// Format: If a doc block comment appears on its own on a line, or if a doc block comment spans multiple
///         lines without appearing on the same line as code, it will be replaced with multiple
///         doc line comments.
///
/// - SeeAlso: https://google.github.io/swift#general-format
public final class UseTripleSlashForDocumentationComments: SyntaxFormatRule {
  public override func visit(_ node: FunctionDeclSyntax) -> DeclSyntax {
    return convertDocBlockCommentToDocLineComment(node)
  }

  public override func visit(_ node: EnumDeclSyntax) -> DeclSyntax {
    return convertDocBlockCommentToDocLineComment(node)
  }

  public override func visit(_ node: InitializerDeclSyntax) -> DeclSyntax {
    return convertDocBlockCommentToDocLineComment(node)
  }

  public override func visit(_ node: DeinitializerDeclSyntax) -> DeclSyntax {
    return convertDocBlockCommentToDocLineComment(node)
  }

  public override func visit(_ node: SubscriptDeclSyntax) -> DeclSyntax {
    return convertDocBlockCommentToDocLineComment(node)
  }

  public override func visit(_ node: ClassDeclSyntax) -> DeclSyntax {
    return convertDocBlockCommentToDocLineComment(node)
  }

  public override func visit(_ node: VariableDeclSyntax) -> DeclSyntax {
    return convertDocBlockCommentToDocLineComment(node)
  }

  public override func visit(_ node: StructDeclSyntax) -> DeclSyntax {
    return convertDocBlockCommentToDocLineComment(node)
  }

  public override func visit(_ node: ProtocolDeclSyntax) -> DeclSyntax {
    return convertDocBlockCommentToDocLineComment(node)
  }

  public override func visit(_ node: TypealiasDeclSyntax) -> DeclSyntax {
    return convertDocBlockCommentToDocLineComment(node)
  }

  public override func visit(_ node: ExtensionDeclSyntax) -> DeclSyntax {
    return convertDocBlockCommentToDocLineComment(node)
  }

  /// In the case the given declaration has a docBlockComment as it's documentation
  /// comment. Returns the declaration with the docBlockComment converted to
  /// a docLineComment.
  func convertDocBlockCommentToDocLineComment(_ decl: DeclSyntax) -> DeclSyntax {
    guard let commentText = decl.docComment else { return decl }
    guard let declLeadinTrivia = decl.leadingTrivia else { return decl }
    let docComments = commentText.components(separatedBy: "\n")
    var pieces = [TriviaPiece]()

    // Ensures the documentation comment is a docLineComment.
    var hasFoundDocComment = false
    for piece in declLeadinTrivia.reversed() {
      if case .docBlockComment(_) = piece, !hasFoundDocComment {
        hasFoundDocComment = true
        diagnose(.avoidDocBlockComment, on: decl)
        pieces.append(contentsOf: separateDocBlockIntoPieces(docComments).reversed())
      } else {
        pieces.append(piece)
      }
    }

    return !hasFoundDocComment
      ? decl : replaceTrivia(
        on: decl,
        token: decl.firstToken,
        leadingTrivia: Trivia(pieces: pieces.reversed())
      ) as! DeclSyntax
  }

  /// Breaks down the docBlock comment into the correct trivia pieces
  /// for a docLineComment.
  func separateDocBlockIntoPieces(_ docComments: [String]) -> [TriviaPiece] {
    var pieces = [TriviaPiece]()
    for lineText in docComments.dropLast() {
      // Adds an space as indentation for the lines that needed it.
      let docLineMark = lineText.first == " " || lineText.trimmingCharacters(in: .whitespaces) == ""
        ? "///" : "/// "
      pieces.append(.docLineComment(docLineMark + lineText))
      pieces.append(.newlines(1))
    }

    // The last piece doesn't need a newline after it.
    if docComments.last!.trimmingCharacters(in: .whitespaces) != "" {
      let docLineMark = docComments.last!.first == " " || docComments.last!.trimmingCharacters(
        in: .whitespaces) == "" ? "///" : "/// "
      pieces.append(.docLineComment(docLineMark + docComments.last!))
    }
    return pieces
  }
}

extension Diagnostic.Message {
  static let avoidDocBlockComment = Diagnostic.Message(
    .warning, "Documentation block comments are not allowed")
}
