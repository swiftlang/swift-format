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

/// Encapsulates logic to recursively visit and rewrite the nodes in a Markdown AST.
///
/// Users should subclass `MarkdownRewriter` and override its methods to implement their desired
/// behavior when nodes of various types are visited.
open class MarkdownRewriter {

  /// Creates a new Markdown node rewriter.
  public init() {}

  /// Visits the given node.
  ///
  /// This is the main entry point of the rewriter. When called it will invoke `beforeVisit(_:)`,
  /// then dispatch to the appropriate specialized `visit(_:)` method (or `visit(extension:)` for
  /// extension nodes), and then call `afterVisit(_:)` before returning.
  ///
  /// - Parameter node: A node in the Markdown AST.
  /// - Returns: The node that should be used in place of `node`.
  public func visit(_ node: MarkdownNode) -> MarkdownNode {
    beforeVisit(node)
    defer { afterVisit(node) }

    switch node {
    case let castNode as BlockQuoteNode: return visit(castNode)
    case let castNode as CodeBlockNode: return visit(castNode)
    case let castNode as EmphasisNode: return visit(castNode)
    case let castNode as HTMLBlockNode: return visit(castNode)
    case let castNode as HeadingNode: return visit(castNode)
    case let castNode as ImageNode: return visit(castNode)
    case let castNode as InlineCodeNode: return visit(castNode)
    case let castNode as InlineHTMLNode: return visit(castNode)
    case let castNode as LineBreakNode: return visit(castNode)
    case let castNode as LinkNode: return visit(castNode)
    case let castNode as ListItemNode: return visit(castNode)
    case let castNode as ListNode: return visit(castNode)
    case let castNode as MarkdownDocument: return visit(castNode)
    case let castNode as ParagraphNode: return visit(castNode)
    case let castNode as SoftBreakNode: return visit(castNode)
    case let castNode as StrongNode: return visit(castNode)
    case let castNode as TextNode: return visit(castNode)
    case let castNode as ThematicBreakNode: return visit(castNode)
    case let castNode as BlockContent: return visit(extension: castNode)
    case let castNode as InlineContent: return visit(extension: castNode)
    default:
      fatalError(
        """
        Internal error: found a node of type '\(type(of: node))', which wasn't a built-in or a \
        custom BlockContent or InlineContent extension
        """
      )
    }
  }

  /// This method is called before the `visit(_:)` or `visit(extension:)` method for every node that
  /// is visited.
  ///
  /// Users can override this method to perform some processing on every node in the tree _before_
  /// its children are visited.
  ///
  /// - Parameter node: The node that is about to be visited.
  open func beforeVisit(_ node: MarkdownNode) {}

  /// This method is called after the `visit(_:)` or `visit(extension:)` method for every node that
  /// is visited.
  ///
  /// Users can override this method to perform some processing on every node in the tree _after_
  /// its children have been visited.
  ///
  /// - Parameter node: The node that was just visited.
  open func afterVisit(_ node: MarkdownNode) {}

  /// Called when a `BlockQuoteNode` is visited, replacing it in the AST with the returned node.
  ///
  /// The base class implementation of this method automatically visits the children of the node and
  /// returns a node whose children have been replaced by the results of that visitation. If you
  /// override it, you must call `super.visit(node)` if you wish to visit the children as well.
  ///
  /// - Parameter node: The node being visited.
  /// - Returns: The node that should replace the given node in the AST.
  open func visit(_ node: BlockQuoteNode) -> BlockContent {
    return node.replacingChildren(visitAll(node.children))
  }

  /// Called when a `CodeBlockNode` is visited, replacing it in the AST with the returned node.
  ///
  /// The base class implementation of this method simply returns the same node.
  ///
  /// - Parameter node: The node being visited.
  /// - Returns: The node that should replace the given node in the AST.
  open func visit(_ node: CodeBlockNode) -> BlockContent {
    return node
  }

  /// Called when a `EmphasisNode` is visited, replacing it in the AST with the returned node.
  ///
  /// The base class implementation of this method automatically visits the children of the node and
  /// returns a node whose children have been replaced by the results of that visitation. If you
  /// override it, you must call `super.visit(node)` if you wish to visit the children as well.
  ///
  /// - Parameter node: The node being visited.
  open func visit(_ node: EmphasisNode) -> InlineContent {
    return node.replacingChildren(visitAll(node.children))
  }

  /// Called when a `HTMLBlockNode` is visited, replacing it in the AST with the returned node.
  ///
  /// The base class implementation of this method simply returns the same node.
  ///
  /// - Parameter node: The node being visited.
  /// - Returns: The node that should replace the given node in the AST.
  open func visit(_ node: HTMLBlockNode) -> BlockContent {
    return node
  }

  /// Called when a `HeadingNode` is visited, replacing it in the AST with the returned node.
  ///
  /// The base class implementation of this method automatically visits the children of the node and
  /// returns a node whose children have been replaced by the results of that visitation. If you
  /// override it, you must call `super.visit(node)` if you wish to visit the children as well.
  ///
  /// - Parameter node: The node being visited.
  /// - Returns: The node that should replace the given node in the AST.
  open func visit(_ node: HeadingNode) -> BlockContent {
    return node.replacingChildren(visitAll(node.children))
  }

  /// Called when a `ImageNode` is visited, replacing it in the AST with the returned node.
  ///
  /// The base class implementation of this method automatically visits the children of the node and
  /// returns a node whose children have been replaced by the results of that visitation. If you
  /// override it, you must call `super.visit(node)` if you wish to visit the children as well.
  ///
  /// - Parameter node: The node being visited.
  /// - Returns: The node that should replace the given node in the AST.
  open func visit(_ node: ImageNode) -> InlineContent {
    return node.replacingChildren(visitAll(node.children))
  }

  /// Called when a `InlineCodeNode` is visited, replacing it in the AST with the returned node.
  ///
  /// The base class implementation of this method simply returns the same node.
  ///
  /// - Parameter node: The node being visited.
  /// - Returns: The node that should replace the given node in the AST.
  open func visit(_ node: InlineCodeNode) -> InlineContent {
    return node
  }

  /// Called when a `InlineHTMLNode` is visited, replacing it in the AST with the returned node.
  ///
  /// The base class implementation of this method simply returns the same node.
  ///
  /// - Parameter node: The node being visited.
  /// - Returns: The node that should replace the given node in the AST.
  open func visit(_ node: InlineHTMLNode) -> InlineContent {
    return node
  }

  /// Called when a `LineBreakNode` is visited, replacing it in the AST with the returned node.
  ///
  /// The base class implementation of this method simply returns the same node.
  ///
  /// - Parameter node: The node being visited.
  /// - Returns: The node that should replace the given node in the AST.
  open func visit(_ node: LineBreakNode) -> InlineContent {
    return node
  }

  /// Called when a `LinkNode` is visited, replacing it in the AST with the returned node.
  ///
  /// The base class implementation of this method automatically visits the children of the node and
  /// returns a node whose children have been replaced by the results of that visitation. If you
  /// override it, you must call `super.visit(node)` if you wish to visit the children as well.
  ///
  /// - Parameter node: The node being visited.
  /// - Returns: The node that should replace the given node in the AST.
  open func visit(_ node: LinkNode) -> InlineContent {
    return node.replacingChildren(visitAll(node.children))
  }

  /// Called when a `ListItemNode` is visited, replacing it in the AST with the returned node.
  ///
  /// The base class implementation of this method automatically visits the children of the node and
  /// returns a node whose children have been replaced by the results of that visitation. If you
  /// override it, you must call `super.visit(node)` if you wish to visit the children as well.
  ///
  /// - Parameter node: The node being visited.
  /// - Returns: The node that should replace the given node in the AST.
  open func visit(_ node: ListItemNode) -> ListItemNode {
    return node.replacingChildren(visitAll(node.children))
  }

  /// Called when a `ListNode` is visited, replacing it in the AST with the returned node.
  ///
  /// The base class implementation of this method automatically visits the children of the node and
  /// returns a node whose children have been replaced by the results of that visitation. If you
  /// override it, you must call `super.visit(node)` if you wish to visit the children as well.
  ///
  /// - Parameter node: The node being visited.
  /// - Returns: The node that should replace the given node in the AST.
  open func visit(_ node: ListNode) -> BlockContent {
    return node.replacingItems(visitAll(node.items))
  }

  /// Called when a `MarkdownDocument` is visited, replacing it in the AST with the returned node.
  ///
  /// The base class implementation of this method automatically visits the children of the node and
  /// returns a node whose children have been replaced by the results of that visitation. If you
  /// override it, you must call `super.visit(node)` if you wish to visit the children as well.
  ///
  /// - Parameter node: The node being visited.
  /// - Returns: The node that should replace the given node in the AST.
  open func visit(_ node: MarkdownDocument) -> MarkdownDocument {
    return node.replacingChildren(visitAll(node.children))
  }

  /// Called when a `ParagraphNode` is visited, replacing it in the AST with the returned node.
  ///
  /// The base class implementation of this method automatically visits the children of the node and
  /// returns a node whose children have been replaced by the results of that visitation. If you
  /// override it, you must call `super.visit(node)` if you wish to visit the children as well.
  ///
  /// - Parameter node: The node being visited.
  /// - Returns: The node that should replace the given node in the AST.
  open func visit(_ node: ParagraphNode) -> BlockContent {
    return node.replacingChildren(visitAll(node.children))
  }

  /// Called when a `SoftBreakNode` is visited, replacing it in the AST with the returned node.
  ///
  /// The base class implementation of this method simply returns the same node.
  ///
  /// - Parameter node: The node being visited.
  /// - Returns: The node that should replace the given node in the AST.
  open func visit(_ node: SoftBreakNode) -> InlineContent {
    return node
  }

  /// Called when a `StrongNode` is visited, replacing it in the AST with the returned node.
  ///
  /// The base class implementation of this method automatically visits the children of the node and
  /// returns a node whose children have been replaced by the results of that visitation. If you
  /// override it, you must call `super.visit(node)` if you wish to visit the children as well.
  ///
  /// - Parameter node: The node being visited.
  /// - Returns: The node that should replace the given node in the AST.
  open func visit(_ node: StrongNode) -> InlineContent {
    return node.replacingChildren(visitAll(node.children))
  }

  /// Called when a `TextNode` is visited, replacing it in the AST with the returned node.
  ///
  /// The base class implementation of this method simply returns the same node.
  ///
  /// - Parameter node: The node being visited.
  /// - Returns: The node that should replace the given node in the AST.
  open func visit(_ node: TextNode) -> InlineContent {
    return node
  }

  /// Called when a `ThematicBreakNode` is visited, replacing it in the AST with the returned node.
  ///
  /// The base class implementation of this method simply returns the same node.
  ///
  /// - Parameter node: The node being visited.
  /// - Returns: The node that should replace the given node in the AST.
  open func visit(_ node: ThematicBreakNode) -> BlockContent {
    return node
  }

  /// Visits a custom block extension node, replacing it in the AST with the returned node.
  ///
  /// If you have defined custom extension nodes and use them in your AST, then this method will be
  /// called for the ones that are block content. A typical implementation would check the type of
  /// the node and dispatch accordingly.
  ///
  /// The base implementation simply returns the same node. Specifically, it cannot visit any
  /// children that the node may have because it does not know anything about the API that the node
  /// provides to access them. Therefore, users who override this method must manually visit the
  /// children of those nodes if they have any (by calling `visitAll(_:)`) and replace them
  /// accordingly.
  ///
  /// - Parameter node: The custom extension block node being visited.
  /// - Returns: The node that should replace the given node in the AST.
  open func visit(extension node: BlockContent) -> BlockContent {
    return node
  }

  /// Visits a custom inline extension node, replacing it in the AST with the returned node.
  ///
  /// If you have defined custom extension nodes and use them in your AST, then this method will be
  /// called for the ones that are inline content. A typical implementation would check the type of
  /// the node and dispatch accordingly.
  ///
  /// The base implementation simply returns the same node. Specifically, it cannot visit any
  /// children that the node may have because it does not know anything about the API that the node
  /// provides to access them. Therefore, users who override this method must manually visit the
  /// children of those nodes if they have any (by calling `visitAll(_:)`) and replace them
  /// accordingly.
  ///
  /// - Parameter node: The custom extension inline node being visited.
  /// - Returns: The node that should replace the given node in the AST.
  open func visit(extension node: InlineContent) -> InlineContent {
    return node
  }

  /// Visits all of the given nodes in the order that they occur in the array, returning an array of
  /// nodes that should replace them.
  ///
  /// - Parameter nodes: An array of nodes to visit.
  /// - Returns: The array of nodes that should replace the given nodes in the AST.
  private func visitAll(_ nodes: [BlockContent]) -> [BlockContent] {
    return nodes.map { visit($0) as! BlockContent }
  }

  /// Visits all of the given nodes in the order that they occur in the array, returning an array of
  /// nodes that should replace them.
  ///
  /// - Parameter nodes: An array of nodes to visit.
  /// - Returns: The array of nodes that should replace the given nodes in the AST.
  private func visitAll(_ nodes: [InlineContent]) -> [InlineContent] {
    return nodes.map { visit($0) as! InlineContent }
  }

  /// Visits all of the given nodes in the order that they occur in the array, returning an array of
  /// nodes that should replace them.
  ///
  /// - Parameter nodes: An array of nodes to visit.
  /// - Returns: The array of nodes that should replace the given nodes in the AST.
  private func visitAll(_ nodes: [ListItemNode]) -> [ListItemNode] {
    return nodes.map { visit($0 as MarkdownNode) as! ListItemNode }
  }
}
