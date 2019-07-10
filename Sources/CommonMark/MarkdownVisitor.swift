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

/// Encapsulates logic to recursively visit the nodes in a Markdown AST.
///
/// Users should subclass `MarkdownVisitor` and override its methods to implement their desired
/// behavior when nodes of various types are visited.
open class MarkdownVisitor {

  /// Creates a new Markdown node visitor.
  public init() {}

  /// Visits the given node.
  ///
  /// This is the main entry point of the visitor. When called it will invoke `beforeVisit(_:)`,
  /// then dispatch to the appropriate specialized `visit(_:)` method (or `visit(extension:)` for
  /// extension nodes), and then call `afterVisit(_:)` before returning.
  ///
  /// - Parameter node: A node in the Markdown AST.
  public func visit(_ node: MarkdownNode) {
    beforeVisit(node)
    switch node {
    case let castNode as BlockQuoteNode: visit(castNode)
    case let castNode as CodeBlockNode: visit(castNode)
    case let castNode as EmphasisNode: visit(castNode)
    case let castNode as HTMLBlockNode: visit(castNode)
    case let castNode as HeadingNode: visit(castNode)
    case let castNode as ImageNode: visit(castNode)
    case let castNode as InlineCodeNode: visit(castNode)
    case let castNode as InlineHTMLNode: visit(castNode)
    case let castNode as LineBreakNode: visit(castNode)
    case let castNode as LinkNode: visit(castNode)
    case let castNode as ListItemNode: visit(castNode)
    case let castNode as ListNode: visit(castNode)
    case let castNode as MarkdownDocument: visit(castNode)
    case let castNode as ParagraphNode: visit(castNode)
    case let castNode as SoftBreakNode: visit(castNode)
    case let castNode as StrongNode: visit(castNode)
    case let castNode as TextNode: visit(castNode)
    case let castNode as ThematicBreakNode: visit(castNode)
    default: visit(extension: node)
    }
    afterVisit(node)
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

  /// Called when a `BlockQuoteNode` is visited.
  ///
  /// The base class implementation of this method automatically visits the children of the node. If
  /// you override it, you must call `super.visit(node)` if you wish to visit the children as well.
  ///
  /// - Parameter node: The node being visited.
  open func visit(_ node: BlockQuoteNode) {
    visitAll(node.children)
  }

  /// Called when a `CodeBlockNode` is visited.
  ///
  /// The base class implementation of this method does nothing.
  ///
  /// - Parameter node: The node being visited.
  open func visit(_ node: CodeBlockNode) {}

  /// Called when a `EmphasisNode` is visited.
  ///
  /// The base class implementation of this method automatically visits the children of the node. If
  /// you override it, you must call `super.visit(node)` if you wish to visit the children as well.
  ///
  /// - Parameter node: The node being visited.
  open func visit(_ node: EmphasisNode) {
    visitAll(node.children)
  }

  /// Called when a `HTMLBlockNode` is visited.
  ///
  /// The base class implementation of this method does nothing.
  ///
  /// - Parameter node: The node being visited.
  open func visit(_ node: HTMLBlockNode) {}

  /// Called when a `HeadingNode` is visited.
  ///
  /// The base class implementation of this method automatically visits the children of the node. If
  /// you override it, you must call `super.visit(node)` if you wish to visit the children as well.
  ///
  /// - Parameter node: The node being visited.
  open func visit(_ node: HeadingNode) {
    visitAll(node.children)
  }

  /// Called when a `ImageNode` is visited.
  ///
  /// The base class implementation of this method automatically visits the children of the node. If
  /// you override it, you must call `super.visit(node)` if you wish to visit the children as well.
  ///
  /// - Parameter node: The node being visited.
  open func visit(_ node: ImageNode) {
    visitAll(node.children)
  }

  /// Called when a `InlineCodeNode` is visited.
  ///
  /// The base class implementation of this method does nothing.
  ///
  /// - Parameter node: The node being visited.
  open func visit(_ node: InlineCodeNode) {}

  /// Called when a `InlineHTMLNode` is visited.
  ///
  /// The base class implementation of this method does nothing.
  ///
  /// - Parameter node: The node being visited.
  open func visit(_ node: InlineHTMLNode) {}

  /// Called when a `LineBreakNode` is visited.
  ///
  /// The base class implementation of this method does nothing.
  ///
  /// - Parameter node: The node being visited.
  open func visit(_ node: LineBreakNode) {}

  /// Called when a `LinkNode` is visited.
  ///
  /// The base class implementation of this method automatically visits the children of the node. If
  /// you override it, you must call `super.visit(node)` if you wish to visit the children as well.
  ///
  /// - Parameter node: The node being visited.
  open func visit(_ node: LinkNode) {
    visitAll(node.children)
  }

  /// Called when a `ListItemNode` is visited.
  ///
  /// The base class implementation of this method automatically visits the children of the node. If
  /// you override it, you must call `super.visit(node)` if you wish to visit the children as well.
  ///
  /// - Parameter node: The node being visited.
  open func visit(_ node: ListItemNode) {
    visitAll(node.children)
  }

  /// Called when a `ListNode` is visited.
  ///
  /// The base class implementation of this method automatically visits the items in the list. If
  /// you override it, you must call `super.visit(node)` if you wish to visit the items as well.
  ///
  /// - Parameter node: The node being visited.
  open func visit(_ node: ListNode) {
    visitAll(node.items)
  }

  /// Called when a `MarkdownDocument` is visited.
  ///
  /// The base class implementation of this method automatically visits the children of the node. If
  /// you override it, you must call `super.visit(node)` if you wish to visit the children as well.
  ///
  /// - Parameter node: The node being visited.
  open func visit(_ node: MarkdownDocument) {
    visitAll(node.children)
  }

  /// Called when a `ParagraphNode` is visited.
  ///
  /// The base class implementation of this method automatically visits the children of the node. If
  /// you override it, you must call `super.visit(node)` if you wish to visit the children as well.
  ///
  /// - Parameter node: The node being visited.
  open func visit(_ node: ParagraphNode) {
    visitAll(node.children)
  }

  /// Called when a `SoftBreakNode` is visited.
  ///
  /// The base class implementation of this method does nothing.
  ///
  /// - Parameter node: The node being visited.
  open func visit(_ node: SoftBreakNode) {}

  /// Called when a `StrongNode` is visited.
  ///
  /// The base class implementation of this method automatically visits the children of the node. If
  /// you override it, you must call `super.visit(node)` if you wish to visit the children as well.
  ///
  /// - Parameter node: The node being visited.
  open func visit(_ node: StrongNode) {
    visitAll(node.children)
  }

  /// Called when a `TextNode` is visited.
  ///
  /// The base class implementation of this method does nothing.
  ///
  /// - Parameter node: The node being visited.
  open func visit(_ node: TextNode) {}

  /// Called when a `ThematicBreakNode` is visited.
  ///
  /// The base class implementation of this method does nothing.
  ///
  /// - Parameter node: The node being visited.
  open func visit(_ node: ThematicBreakNode) {}

  /// Visits a custom extension node.
  ///
  /// If you have defined custom extension nodes and use them in your AST, then this method will be
  /// called for those nodes. A typical implementation would check the type of the node and dispatch
  /// accordingly.
  ///
  /// The base implementation does nothing. Specifically, it cannot visit any children that the node
  /// may have because it does not know anything about the API that the node provides to access
  /// them. Therefore, users who override this method must manually visit the children of those
  /// nodes if they have any (by calling `visitAll(_:)`).
  ///
  /// - Parameter node: The custom extension node being visited.
  open func visit(extension node: MarkdownNode) {}

  /// Visits all of the given nodes in the order that they occur in the array.
  ///
  /// - Parameter nodes: An array of nodes to visit.
  public func visitAll(_ nodes: [MarkdownNode]) {
    for node in nodes {
      visit(node)
    }
  }
}
