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

/// An inline element that represents a hyperlink.
public struct LinkNode: InlineContent {

  /// The URL to which the link should navigate.
  ///
  /// The value of this property will be nil if the link has no URL set, or if the URL string in a
  /// parsed document was a value that Foundation's `URL` could not parse.
  public let url: URL?

  /// The title text associated with the link, if any.
  ///
  /// When rendered to HTML, the title is used as the `title` attribute of the link, which browsers
  /// typically render as a tooltip when the user hovers over it.
  public let title: String

  /// The children of the receiver.
  ///
  /// The children of a link node are the content that is rendered inside it.
  public let children: [InlineContent]

  public let sourceRange: Range<SourceLocation>?

  public var primitiveRepresentation: PrimitiveNode { return .link(self) }

  /// Creates a new link node.
  ///
  /// - Parameters:
  ///   - url: The URL to which the link should navigate.
  ///   - title: The title text associated with the link, if any.
  ///   - children: Inline content nodes that are children of the new node.
  ///   - sourceRange: The source range from which the node was parsed, if known.
  public init(
    url: URL?,
    title: String = "",
    children: [InlineContent] = [],
    sourceRange: Range<SourceLocation>? = nil
  ) {
    self.url = url
    self.title = title
    self.children = children
    self.sourceRange = sourceRange
  }

  /// Returns a new node equivalent to the receiver, but whose URL has been replaced with the given
  /// value.
  ///
  /// - Parameter url: The new URL.
  /// - Returns: The new node.
  public func replacingURL(_ url: URL?) -> LinkNode {
    return LinkNode(url: url, title: title, children: children, sourceRange: sourceRange)
  }

  /// Returns a new node equivalent to the receiver, but whose title has been replaced with the
  /// given value.
  ///
  /// - Parameter title: The new title.
  /// - Returns: The new node.
  public func replacingTitle(_ title: String) -> LinkNode {
    return LinkNode(url: url, title: title, children: children, sourceRange: sourceRange)
  }

  /// Returns a new node equivalent to the receiver, but whose children have been replaced with the
  /// given list of nodes.
  ///
  /// - Parameter children: The new list of children.
  /// - Returns: The new node.
  public func replacingChildren(_ children: [InlineContent]) -> LinkNode {
    return LinkNode(url: url, title: title, children: children, sourceRange: sourceRange)
  }

  /// Returns a new node equivalent to the receiver, but whose source range has been replaced with
  /// the given value.
  ///
  /// - Parameter sourceRange: The new source range.
  /// - Returns: The new node.
  public func replacingSourceRange(_ sourceRange: Range<SourceLocation>?) -> LinkNode {
    return LinkNode(url: url, title: title, children: children, sourceRange: sourceRange)
  }
}
