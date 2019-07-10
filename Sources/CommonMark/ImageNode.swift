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

/// An inline element that represents an image.
public struct ImageNode: InlineContent {

  /// The URL from which the image should be loaded.
  ///
  /// The value of this property will be nil if the image has no URL set, or if the URL string in a
  /// parsed document was a value that Foundation's `URL` could not parse.
  public let url: URL?

  /// The title text associated with the image, if any.
  ///
  /// When rendered to HTML, the title is used as the `title` attribute of the image, which browsers
  /// typically render as a tooltip when the user hovers over it.
  public let title: String

  /// The children of the receiver.
  ///
  /// The children of an image node can be used by renderers as an alternate representation if the
  /// client doesn't support images. For example, when rendered in HTML, the text of the child nodes
  /// is used as the `alt` tag of the `<img>` tag.
  public let children: [InlineContent]

  public let sourceRange: Range<SourceLocation>?

  public var primitiveRepresentation: PrimitiveNode { return .image(self) }

  /// Creates a new image node.
  ///
  /// - Parameters:
  ///   - url: The URL from which the image should be loaded.
  ///   - title: The title text associated with the image, if any.
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
  public func replacingURL(_ url: URL?) -> ImageNode {
    return ImageNode(url: url, title: title, children: children, sourceRange: sourceRange)
  }

  /// Returns a new node equivalent to the receiver, but whose title has been replaced with the
  /// given value.
  ///
  /// - Parameter title: The new title.
  /// - Returns: The new node.
  public func replacingTitle(_ title: String) -> ImageNode {
    return ImageNode(url: url, title: title, children: children, sourceRange: sourceRange)
  }

  /// Returns a new node equivalent to the receiver, but whose children have been replaced with the
  /// given list of nodes.
  ///
  /// - Parameter children: The new list of children.
  /// - Returns: The new node.
  public func replacingChildren(_ children: [InlineContent]) -> ImageNode {
    return ImageNode(url: url, title: title, children: children, sourceRange: sourceRange)
  }

  /// Returns a new node equivalent to the receiver, but whose source range has been replaced with
  /// the given value.
  ///
  /// - Parameter sourceRange: The new source range.
  /// - Returns: The new node.
  public func replacingSourceRange(_ sourceRange: Range<SourceLocation>?) -> ImageNode {
    return ImageNode(url: url, title: title, children: children, sourceRange: sourceRange)
  }
}
