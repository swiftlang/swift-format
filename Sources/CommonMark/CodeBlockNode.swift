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

/// A block element that represents source code, typically rendered in a fixed-width font.
public struct CodeBlockNode: BlockContent {

  /// The literal text content of the node.
  public let literalContent: String

  /// The text on the same line immediately following the opening "fence" (that is, the leading
  /// triple backticks ` ``` `) of the code block.
  ///
  /// The fence text is often used to provide additional metadata about the code block, such as a
  /// tag that indicates which language the code is written in, to support renderers that can apply
  /// language-specific syntax coloring.
  ///
  /// If there was no text following the opening fence, or if the code block as an indented code
  /// block rather than a fenced code block, this property will evaluate to the empty string.
  public var fenceText: String

  public let sourceRange: Range<SourceLocation>?

  public var primitiveRepresentation: PrimitiveNode { return .codeBlock(self) }

  /// Creates a new empty code block node.
  ///
  /// - Parameters:
  ///   - literalContent: The literal text content of the node.
  ///   - fenceText: The text that immediately follows the opening fence for a code block that is
  ///     fenced by triple backticks. If omitted, the empty string is used.
  ///   - sourceRange: The source range from which the node was parsed, if known.
  public init(
    literalContent: String,
    fenceText: String = "",
    sourceRange: Range<SourceLocation>? = nil
  ) {
    self.literalContent = literalContent
    self.fenceText = fenceText
    self.sourceRange = sourceRange
  }

  /// Returns a new node equivalent to the receiver, but whose literal content has been replaced
  /// with the given string.
  ///
  /// - Parameter literalContent: The new literal content.
  /// - Returns: The new node.
  public func replacingLiteralContent(_ literalContent: String) -> CodeBlockNode {
    return CodeBlockNode(
      literalContent: literalContent,
      fenceText: fenceText,
      sourceRange: sourceRange)
  }

  /// Returns a new node equivalent to the receiver, but whose fence text has been replaced with the
  /// given string.
  ///
  /// - Parameter fenceText: The new fence text.
  /// - Returns: The new node.
  public func replacingFenceText(_ fenceText: String) -> CodeBlockNode {
    return CodeBlockNode(
      literalContent: literalContent,
      fenceText: fenceText,
      sourceRange: sourceRange)
  }

  /// Returns a new node equivalent to the receiver, but whose source range has been replaced with
  /// the given value.
  ///
  /// - Parameter sourceRange: The new source range.
  /// - Returns: The new node.
  public func replacingSourceRange(_ sourceRange: Range<SourceLocation>?) -> CodeBlockNode {
    return CodeBlockNode(
      literalContent: literalContent,
      fenceText: fenceText,
      sourceRange: sourceRange)
  }
}
