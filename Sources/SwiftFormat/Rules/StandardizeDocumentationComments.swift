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
import Markdown
import SwiftSyntax

/// Reformats documentation comments to a standard structure.
///
/// Format: Documentation is reflowed in a standard format:
/// - All documentation comments are rendered as `///`-prefixed.
/// - Documentation comments are re-wrapped to the preferred line length.
/// - The order of elements in a documentation comment is standard:
///   - Abstract
///   - Discussion w/ paragraphs, code samples, lists, etc.
///   - Param docs (outlined if > 1)
///   - Return docs
///   - Throw docs
@_spi(Rules)
public final class StandardizeDocumentationComments: SyntaxFormatRule {
  public override class var isOptIn: Bool { return true }

  // For each kind of `DeclSyntax` node that we visit, if we modify the node we
  // need to continue into that node's children, if any exist. These are
  // different for different node types (e.g. an accessor has a `body`, while an
  // actor has a `memberBlock`).

  public override func visit(_ node: AccessorDeclSyntax) -> DeclSyntax {
    if var decl = reformatDocumentation(node) {
      decl.body = decl.body.map(visit)
      return DeclSyntax(decl)
    }
    return super.visit(node)
  }

  public override func visit(_ node: ActorDeclSyntax) -> DeclSyntax {
    if var decl = reformatDocumentation(node) {
      decl.memberBlock = visit(decl.memberBlock)
      return DeclSyntax(decl)
    }
    return super.visit(node)
  }

  public override func visit(_ node: AssociatedTypeDeclSyntax) -> DeclSyntax {
    reformatDocumentation(DeclSyntax(node)) ?? super.visit(node)
  }

  public override func visit(_ node: ClassDeclSyntax) -> DeclSyntax {
    if var decl = reformatDocumentation(node) {
      decl.memberBlock = visit(decl.memberBlock)
      return DeclSyntax(decl)
    }
    return super.visit(node)
  }

  public override func visit(_ node: DeinitializerDeclSyntax) -> DeclSyntax {
    reformatDocumentation(DeclSyntax(node)) ?? super.visit(node)
  }

  public override func visit(_ node: EditorPlaceholderDeclSyntax) -> DeclSyntax {
    reformatDocumentation(DeclSyntax(node)) ?? super.visit(node)
  }

  public override func visit(_ node: EnumCaseDeclSyntax) -> DeclSyntax {
    reformatDocumentation(DeclSyntax(node)) ?? super.visit(node)
  }

  public override func visit(_ node: EnumDeclSyntax) -> DeclSyntax {
    if var decl = reformatDocumentation(node) {
      decl.memberBlock = visit(decl.memberBlock)
      return DeclSyntax(decl)
    }
    return super.visit(node)
  }

  public override func visit(_ node: ExtensionDeclSyntax) -> DeclSyntax {
    if var decl = reformatDocumentation(node) {
      decl.memberBlock = visit(decl.memberBlock)
      return DeclSyntax(decl)
    }
    return super.visit(node)
  }

  public override func visit(_ node: FunctionDeclSyntax) -> DeclSyntax {
    if var decl = reformatDocumentation(node) {
      decl.body = decl.body.map(visit)
      return DeclSyntax(decl)
    }
    return super.visit(node)
  }

  public override func visit(_ node: IfConfigDeclSyntax) -> DeclSyntax {
    if var decl = reformatDocumentation(node) {
      decl.clauses = visit(decl.clauses)
      return DeclSyntax(decl)
    }
    return super.visit(node)
  }

  public override func visit(_ node: ImportDeclSyntax) -> DeclSyntax {
    reformatDocumentation(DeclSyntax(node)) ?? super.visit(node)
  }

  public override func visit(_ node: InitializerDeclSyntax) -> DeclSyntax {
    if var decl = reformatDocumentation(node) {
      decl.body = decl.body.map(visit)
      return DeclSyntax(decl)
    }
    return super.visit(node)
  }

  public override func visit(_ node: MacroDeclSyntax) -> DeclSyntax {
    reformatDocumentation(DeclSyntax(node)) ?? super.visit(node)
  }

  public override func visit(_ node: MacroExpansionDeclSyntax) -> DeclSyntax {
    reformatDocumentation(DeclSyntax(node)) ?? super.visit(node)
  }

  public override func visit(_ node: MissingDeclSyntax) -> DeclSyntax {
    reformatDocumentation(DeclSyntax(node)) ?? super.visit(node)
  }

  public override func visit(_ node: OperatorDeclSyntax) -> DeclSyntax {
    reformatDocumentation(DeclSyntax(node)) ?? super.visit(node)
  }

  public override func visit(_ node: PoundSourceLocationSyntax) -> DeclSyntax {
    reformatDocumentation(DeclSyntax(node)) ?? super.visit(node)
  }

  public override func visit(_ node: PrecedenceGroupDeclSyntax) -> DeclSyntax {
    reformatDocumentation(DeclSyntax(node)) ?? super.visit(node)
  }

  public override func visit(_ node: ProtocolDeclSyntax) -> DeclSyntax {
    if var decl = reformatDocumentation(node) {
      decl.memberBlock = visit(decl.memberBlock)
      return DeclSyntax(decl)
    }
    return super.visit(node)
  }

  public override func visit(_ node: StructDeclSyntax) -> DeclSyntax {
    if var decl = reformatDocumentation(node) {
      decl.memberBlock = visit(decl.memberBlock)
      return DeclSyntax(decl)
    }
    return super.visit(node)
  }

  public override func visit(_ node: SubscriptDeclSyntax) -> DeclSyntax {
    if var decl = reformatDocumentation(node) {
      decl.accessorBlock = decl.accessorBlock.map(visit)
      return DeclSyntax(decl)
    }
    return super.visit(node)
  }

  public override func visit(_ node: TypeAliasDeclSyntax) -> DeclSyntax {
    reformatDocumentation(DeclSyntax(node)) ?? super.visit(node)
  }

  public override func visit(_ node: VariableDeclSyntax) -> DeclSyntax {
    reformatDocumentation(DeclSyntax(node)) ?? super.visit(node)
  }

  private func reformatDocumentation<T: DeclSyntaxProtocol>(
    _ node: T
  ) -> T? {
    guard let docComment = DocumentationComment(extractedFrom: node)
    else { return nil }

    // Find the start of the documentation that is attached to this
    // identifier, skipping over any trivia that doesn't actually
    // attach (like `//` comments or full blank lines).
    let docCommentTrivia = Array(node.leadingTrivia)
    guard let startOfActualDocumentation = findStartOfDocComments(in: docCommentTrivia)
    else { return node }

    // We need to preserve everything up to `startOfActualDocumentation`.
    let preDocumentationTrivia = Trivia(pieces: node.leadingTrivia[..<startOfActualDocumentation])

    // Next, find the trivia between the declaration and the last comment.
    // This is the trivia that we'll need to include between each line of
    // the documentation comments.
    guard let startOfLeadingWhitespace = docCommentTrivia.lastIndex(where: \.isDocComment)
    else { return node }
    let lineLeadingTrivia = docCommentTrivia[startOfLeadingWhitespace...].dropFirst()

    var result = node
    result.leadingTrivia =
      preDocumentationTrivia
      + docComment.renderForSource(
        lineWidth: context.configuration.lineLength,
        joiningTrivia: lineLeadingTrivia
      )
    return result
  }
}

fileprivate func findStartOfDocComments(in trivia: [TriviaPiece]) -> Int? {
  let startOfCommentSection =
    trivia.lastIndex(where: { !$0.continuesDocComment })
    ?? trivia.startIndex
  return trivia[startOfCommentSection...].firstIndex(where: \.isDocComment)
}

extension TriviaPiece {
  fileprivate var isDocComment: Bool {
    switch self {
    case .docBlockComment, .docLineComment: return true
    default: return false
    }
  }

  fileprivate var continuesDocComment: Bool {
    if isDocComment { return true }
    switch self {
    // Any amount of horizontal whitespace is okay
    case .spaces, .tabs:
      return true
    // One line break is okay
    case .newlines(1), .carriageReturns(1), .carriageReturnLineFeeds(1):
      return true
    default:
      return false
    }
  }
}
