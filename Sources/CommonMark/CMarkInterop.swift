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

import CCommonMark
import Foundation

/// Creates a new Swift value corresponding to the given node.
///
/// This function walks the tree, creating the equivalent Swift tree for the given node and all of
/// its children recursively.
///
/// - Parameter cNode: The C pointer of a node.
/// - Returns: A Swift value corresponding to the tree rooted at the given node.
fileprivate func makeNode(from cNode: OpaquePointer) -> MarkdownNode {
  let sourceRange = makeSourceRange(for: cNode)
  let type = cmark_node_get_type(cNode)

  let node: MarkdownNode
  switch type {
  case CMARK_NODE_BLOCK_QUOTE:
    node = BlockQuoteNode(
      children: makeNodes(fromChildrenOf: cNode) as! [BlockContent],
      sourceRange: sourceRange)
  case CMARK_NODE_CODE:
    node = InlineCodeNode(
      literalContent: String(cString: cmark_node_get_literal(cNode)),
      sourceRange: sourceRange)
  case CMARK_NODE_CODE_BLOCK:
    node = CodeBlockNode(
      literalContent: String(cString: cmark_node_get_literal(cNode)),
      fenceText: String(cString: cmark_node_get_fence_info(cNode)),
      sourceRange: sourceRange)
  case CMARK_NODE_EMPH:
    node = EmphasisNode(
      children: makeNodes(fromChildrenOf: cNode) as! [InlineContent],
      sourceRange: sourceRange)
  case CMARK_NODE_HEADING:
    node = HeadingNode(
      level: HeadingNode.Level(rawValue: numericCast(cmark_node_get_heading_level(cNode)))!,
      children: makeNodes(fromChildrenOf: cNode) as! [InlineContent],
      sourceRange: sourceRange)
  case CMARK_NODE_HTML_BLOCK:
    node = HTMLBlockNode(
      literalContent: String(cString: cmark_node_get_literal(cNode)),
      sourceRange: sourceRange)
  case CMARK_NODE_IMAGE:
    node = ImageNode(
      url: URL(string: String(cString: cmark_node_get_url(cNode))),
      title: String(cString: cmark_node_get_title(cNode)),
      children: makeNodes(fromChildrenOf: cNode) as! [InlineContent],
      sourceRange: sourceRange)
  case CMARK_NODE_HTML_INLINE:
    node = InlineHTMLNode(
      literalContent: String(cString: cmark_node_get_literal(cNode)),
      sourceRange: sourceRange)
  case CMARK_NODE_ITEM:
    node = ListItemNode(
      children: makeNodes(fromChildrenOf: cNode) as! [BlockContent],
      sourceRange: sourceRange)
  case CMARK_NODE_LINEBREAK:
    node = LineBreakNode(sourceRange: sourceRange)
  case CMARK_NODE_LINK:
    node = LinkNode(
      url: URL(string: String(cString: cmark_node_get_url(cNode))),
      title: String(cString: cmark_node_get_title(cNode)),
      children: makeNodes(fromChildrenOf: cNode) as! [InlineContent],
      sourceRange: sourceRange)
  case CMARK_NODE_LIST:
    let cListType = cmark_node_get_list_type(cNode)
    let listType: ListNode.ListType
    if cListType == CMARK_BULLET_LIST {
      listType = .bulleted
    } else {
      let cDelimiter = cmark_node_get_list_delim(cNode)
      listType = .ordered(
        delimiter: ListNode.Delimiter(cDelimiter),
        startingNumber: numericCast(cmark_node_get_list_start(cNode)))
    }
    node = ListNode(
      listType: listType,
      items: makeNodes(fromChildrenOf: cNode) as! [ListItemNode],
      isTight: cmark_node_get_list_tight(cNode) != 0,
      sourceRange: sourceRange)
  case CMARK_NODE_PARAGRAPH:
    node = ParagraphNode(
      children: makeNodes(fromChildrenOf: cNode) as! [InlineContent],
      sourceRange: sourceRange)
  case CMARK_NODE_SOFTBREAK:
    node = SoftBreakNode(sourceRange: sourceRange)
  case CMARK_NODE_STRONG:
    node = StrongNode(
      children: makeNodes(fromChildrenOf: cNode) as! [InlineContent],
      sourceRange: sourceRange)
  case CMARK_NODE_TEXT:
    node = TextNode(
      literalContent: String(cString: cmark_node_get_literal(cNode)),
      sourceRange: sourceRange)
  case CMARK_NODE_THEMATIC_BREAK:
    node = ThematicBreakNode(sourceRange: sourceRange)
  default:
    fatalError("Unexpected node type \(type) encountered")
  }

  return node
}

/// Returns an array of Swift values that are children of the given C node pointer.
///
/// - Parameter cNode: The C pointer of a node.
/// - Returns: An array of Swift values representing the children of the given node.
func makeNodes(fromChildrenOf cNode: OpaquePointer) -> [MarkdownNode] {
  var children = [MarkdownNode]()
  var cChildOrNil = cmark_node_first_child(cNode)
  while let cChild = cChildOrNil {
    children.append(makeNode(from: cChild))
    cChildOrNil = cmark_node_next(cChild)
  }
  return children
}

/// Returns a new source range equal to the start and end locations of the given node pointer.
///
/// - Parameter cNode: The C pointer of a node.
/// - Returns: The source range of the given node.
func makeSourceRange(for cNode: OpaquePointer) -> Range<SourceLocation> {
  return SourceLocation(
    line: numericCast(cmark_node_get_start_line(cNode)),
    column: numericCast(cmark_node_get_start_column(cNode))
  )..<SourceLocation(
    line: numericCast(cmark_node_get_end_line(cNode)),
    column: numericCast(cmark_node_get_end_column(cNode))
  )
}

extension ListNode.Delimiter {

  /// The underlying C value that is equivalent to the receiver delimiter.
  fileprivate var cValue: cmark_delim_type {
    switch self {
    case .period: return CMARK_PERIOD_DELIM
    case .parenthesis: return CMARK_PAREN_DELIM
    }
  }

  /// Creates a delimiter equivalent to the given underlying C value.
  ///
  /// - Parameter cDelim: The underlying C value from which the delimiter should be created.
  fileprivate init(_ cDelim: cmark_delim_type) {
    switch cDelim {
    case CMARK_PERIOD_DELIM: self = .period
    case CMARK_PAREN_DELIM: self = .parenthesis
    default: fatalError("Unexpected list delimiter \(cDelim)")
    }
  }
}

/// A value that can be converted to a pointer to a CMark node.
protocol CMarkNodeConvertible {

  /// Returns a new CMark node (by calling `cmark_node_new`) that is equivalent to the receiver.
  ///
  /// - Returns: A new CMark node.
  func makeCNode() -> OpaquePointer
}

extension PrimitiveNode: CMarkNodeConvertible {

  func makeCNode() -> OpaquePointer {
    switch self {
    case .blockQuote(let node): return node.makeCNode()
    case .codeBlock(let node): return node.makeCNode()
    case .document(let node): return node.makeCNode()
    case .emphasis(let node): return node.makeCNode()
    case .heading(let node): return node.makeCNode()
    case .htmlBlock(let node): return node.makeCNode()
    case .image(let node): return node.makeCNode()
    case .inlineCode(let node): return node.makeCNode()
    case .inlineHTML(let node): return node.makeCNode()
    case .lineBreak(let node): return node.makeCNode()
    case .link(let node): return node.makeCNode()
    case .list(let node): return node.makeCNode()
    case .listItem(let node): return node.makeCNode()
    case .paragraph(let node): return node.makeCNode()
    case .softBreak(let node): return node.makeCNode()
    case .strong(let node): return node.makeCNode()
    case .text(let node): return node.makeCNode()
    case .thematicBreak(let node): return node.makeCNode()
    }
  }
}

extension BlockQuoteNode: CMarkNodeConvertible {

  func makeCNode() -> OpaquePointer {
    let cNode = cmark_node_new(CMARK_NODE_BLOCK_QUOTE)!
    for child in children {
      cmark_node_append_child(cNode, child.primitiveRepresentation.makeCNode())
    }
    return cNode
  }
}

extension CodeBlockNode: CMarkNodeConvertible {

  func makeCNode() -> OpaquePointer {
    let cNode = cmark_node_new(CMARK_NODE_CODE_BLOCK)!
    cmark_node_set_literal(cNode, literalContent)
    cmark_node_set_fence_info(cNode, fenceText)
    return cNode
  }
}

extension EmphasisNode: CMarkNodeConvertible {

  func makeCNode() -> OpaquePointer {
    let cNode = cmark_node_new(CMARK_NODE_EMPH)!
    for child in children {
      cmark_node_append_child(cNode, child.primitiveRepresentation.makeCNode())
    }
    return cNode
  }
}

extension HTMLBlockNode: CMarkNodeConvertible {

  func makeCNode() -> OpaquePointer {
    let cNode = cmark_node_new(CMARK_NODE_HTML_BLOCK)!
    cmark_node_set_literal(cNode, literalContent)
    return cNode
  }
}

extension HeadingNode: CMarkNodeConvertible {

  func makeCNode() -> OpaquePointer {
    let cNode = cmark_node_new(CMARK_NODE_HEADING)!
    cmark_node_set_heading_level(cNode, numericCast(level.rawValue))
    for child in children {
      cmark_node_append_child(cNode, child.primitiveRepresentation.makeCNode())
    }
    return cNode
  }
}

extension ImageNode: CMarkNodeConvertible {

  func makeCNode() -> OpaquePointer {
    let cNode = cmark_node_new(CMARK_NODE_IMAGE)!
    cmark_node_set_title(cNode, title)
    cmark_node_set_url(cNode, url?.absoluteString)
    for child in children {
      cmark_node_append_child(cNode, child.primitiveRepresentation.makeCNode())
    }
    return cNode
  }
}

extension InlineCodeNode: CMarkNodeConvertible {

  func makeCNode() -> OpaquePointer {
    let cNode = cmark_node_new(CMARK_NODE_CODE)!
    cmark_node_set_literal(cNode, literalContent)
    return cNode
  }
}

extension InlineHTMLNode: CMarkNodeConvertible {

  func makeCNode() -> OpaquePointer {
    let cNode = cmark_node_new(CMARK_NODE_HTML_INLINE)!
    cmark_node_set_literal(cNode, literalContent)
    return cNode
  }
}

extension LineBreakNode: CMarkNodeConvertible {

  func makeCNode() -> OpaquePointer {
    return cmark_node_new(CMARK_NODE_LINEBREAK)!
  }
}

extension LinkNode: CMarkNodeConvertible {

  func makeCNode() -> OpaquePointer {
    let cNode = cmark_node_new(CMARK_NODE_LINK)!
    cmark_node_set_title(cNode, title)
    cmark_node_set_url(cNode, url?.absoluteString)
    for child in children {
      cmark_node_append_child(cNode, child.primitiveRepresentation.makeCNode())
    }
    return cNode
  }
}

extension ListItemNode: CMarkNodeConvertible {

  func makeCNode() -> OpaquePointer {
    let cNode = cmark_node_new(CMARK_NODE_ITEM)!
    for child in children {
      cmark_node_append_child(cNode, child.primitiveRepresentation.makeCNode())
    }
    return cNode
  }
}

extension ListNode: CMarkNodeConvertible {

  func makeCNode() -> OpaquePointer {
    let cNode = cmark_node_new(CMARK_NODE_LIST)!
    switch listType {
    case .bulleted:
      cmark_node_set_list_type(cNode, CMARK_BULLET_LIST)
    case .ordered(let delimiter, let startingNumber):
      cmark_node_set_list_type(cNode, CMARK_ORDERED_LIST)
      cmark_node_set_list_delim(cNode, delimiter.cValue)
      cmark_node_set_list_start(cNode, numericCast(startingNumber))
    }
    cmark_node_set_list_tight(cNode, isTight ? 1 : 0)
    for item in items {
      cmark_node_append_child(cNode, item.primitiveRepresentation.makeCNode())
    }
    return cNode
  }
}

extension MarkdownDocument: CMarkNodeConvertible {

  func makeCNode() -> OpaquePointer {
    let cNode = cmark_node_new(CMARK_NODE_DOCUMENT)!
    for child in children {
      cmark_node_append_child(cNode, child.primitiveRepresentation.makeCNode())
    }
    return cNode
  }
}

extension ParagraphNode: CMarkNodeConvertible {

  func makeCNode() -> OpaquePointer {
    let cNode = cmark_node_new(CMARK_NODE_PARAGRAPH)!
    for child in children {
      cmark_node_append_child(cNode, child.primitiveRepresentation.makeCNode())
    }
    return cNode
  }
}

extension SoftBreakNode: CMarkNodeConvertible {

  func makeCNode() -> OpaquePointer {
    return cmark_node_new(CMARK_NODE_SOFTBREAK)!
  }
}

extension StrongNode: CMarkNodeConvertible {

  func makeCNode() -> OpaquePointer {
    let cNode = cmark_node_new(CMARK_NODE_STRONG)!
    for child in children {
      cmark_node_append_child(cNode, child.primitiveRepresentation.makeCNode())
    }
    return cNode
  }
}

extension TextNode: CMarkNodeConvertible {

  func makeCNode() -> OpaquePointer {
    let cNode = cmark_node_new(CMARK_NODE_TEXT)!
    cmark_node_set_literal(cNode, literalContent)
    return cNode
  }
}

extension ThematicBreakNode: CMarkNodeConvertible {

  func makeCNode() -> OpaquePointer {
    return cmark_node_new(CMARK_NODE_THEMATIC_BREAK)!
  }
}
