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

/// The primitive representation of a Markdown node in terms of a built-in node.
///
/// This CommonMark module supports user extensions to the model, such that the parser can be hooked
/// to replace nodes in the AST with custom types that conform to `BlockContent` or `InlineContent`.
/// When those custom nodes are rendered back out to HTML, Markdown, or some other format, the
/// library needs to be able to map those custom nodes back to a representation that is expressed in
/// terms of the built-in node types.
///
/// In order to achieve this mapping, custom node types (which indirectly conform to `MarkdownNode`)
/// must implement the `primitiveRepresentation` property and return a value from this `enum`, where
/// the associated value is an equivalent built-in node (potentially with children).
public enum PrimitiveNode {

  case blockQuote(BlockQuoteNode)

  case codeBlock(CodeBlockNode)

  case document(MarkdownDocument)

  case emphasis(EmphasisNode)

  case heading(HeadingNode)

  case htmlBlock(HTMLBlockNode)

  case image(ImageNode)

  case inlineCode(InlineCodeNode)

  case inlineHTML(InlineHTMLNode)

  case lineBreak(LineBreakNode)

  case link(LinkNode)

  case list(ListNode)

  case listItem(ListItemNode)

  case paragraph(ParagraphNode)

  case softBreak(SoftBreakNode)

  case strong(StrongNode)

  case text(TextNode)

  case thematicBreak(ThematicBreakNode)
}
