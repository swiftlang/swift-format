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

/// A node in the AST representing a parsed Markdown document.
///
/// This protocol is refined by the more specific `BlockContent` and `InlineContent` protocols,
/// which help to enforce the containment relationship between the types of nodes in the AST.
public protocol MarkdownNode {

  /// The range that the node occupies in the original source text, if known.
  ///
  /// The value of this property is provided by the parser when it parses Markdown source text. It
  /// can be nil for nodes created dynamically unless the caller provides a valid range at that
  /// time.
  var sourceRange: Range<SourceLocation>? { get }

  /// The primitive representation of the node, if different from a built-in node.
  ///
  /// This CommonMark module supports user extensions to the model, such that the parser can be
  /// hooked to replace nodes in the AST with custom types that conform to `BlockContent` or
  /// `InlineContent`. When those custom nodes are rendered back out to HTML, Markdown, or some
  /// other format, the library needs to be able to map those custom nodes back to a representation
  /// that is expressed in terms of the built-in node types.
  var primitiveRepresentation: PrimitiveNode { get }
}
