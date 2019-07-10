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

/// A node that represents the document root.
public struct MarkdownDocument: MarkdownNode {

  /// Options that control behavior when parsing a document.
  public struct ParsingOptions: OptionSet {

    /// The parser should normalize the resulting tree by consolidating adjacent text nodes.
    public static let normalize = ParsingOptions(rawValue: CMARK_OPT_NORMALIZE)

    /// The parser should produce a tree that contains "smart" punctuation.
    ///
    /// For example, smart punctuation will substitute curly quotes for pairs of straight quotes,
    /// and translate `"--"` into en-dashes and `"---"` into em-dashes.
    public static let smartPunctuation = ParsingOptions(rawValue: CMARK_OPT_SMART)

    /// The parser should verify that the input is valid UTF-8, replacing any illegal sequences with
    /// the Unicode replacement character U+FFFD.
    public static let validateUTF8 = ParsingOptions(rawValue: CMARK_OPT_VALIDATE_UTF8)

    public let rawValue: Int32

    public init(rawValue: Int32) {
      self.rawValue = rawValue
    }
  }

  /// The children of the receiver.
  public let children: [BlockContent]

  public let sourceRange: Range<SourceLocation>?

  public var primitiveRepresentation: PrimitiveNode { return .document(self) }

  /// Creates a new Markdown document.
  ///
  /// - Parameters:
  ///   - children: Block content nodes that are children of the new node.
  ///   - sourceRange: The source range from which the node was parsed, if known.
  public init(children: [BlockContent], sourceRange: Range<SourceLocation>? = nil) {
    self.children = children
    self.sourceRange = sourceRange
  }

  /// Creates a Markdown document by parsing the given text.
  ///
  /// - Parameters:
  ///   - text: The Markdown text that should be parsed.
  ///   - options: Options that control the behavior of the parser; empty by default.
  public init(byParsing text: String, options: ParsingOptions = []) {
    guard let cDocument = cmark_parse_document(text, text.utf8.count, options.rawValue) else {
      fatalError("cmark_parse_document unexpectedly returned nil")
    }
    self.init(
      children: makeNodes(fromChildrenOf: cDocument) as! [BlockContent],
      sourceRange: makeSourceRange(for: cDocument)
    )
  }

  /// Returns a new node equivalent to the receiver, but whose children have been replaced with the
  /// given list of nodes.
  ///
  /// - Parameter children: The new list of children.
  /// - Returns: The new node.
  public func replacingChildren(_ children: [BlockContent]) -> MarkdownDocument {
    return MarkdownDocument(children: children, sourceRange: sourceRange)
  }

  /// Returns a new node equivalent to the receiver, but whose source range has been replaced with
  /// the given value.
  ///
  /// - Parameter sourceRange: The new source range.
  /// - Returns: The new node.
  public func replacingSourceRange(_ sourceRange: Range<SourceLocation>?) -> MarkdownDocument {
    return MarkdownDocument(children: children, sourceRange: sourceRange)
  }

  /// Returns a string that contains the content of the Markdown document rendered using the given
  /// renderer.
  ///
  /// - Parameters:
  ///   - renderer: A value from `MarkdownRenderer` that indicates what output format the document
  ///     should be rendered in.
  ///   - options: Additional options that control the renderers output; empty by default.
  /// - Returns: A string containing the rendered content of the Markdown document.
  public func string(
    renderedUsing renderer: MarkdownRenderer,
    options: MarkdownRenderer.Options = []
  ) -> String {
    let rawOptions = options.rawValue
    let cNode = primitiveRepresentation.makeCNode()

    let cString: UnsafeMutablePointer<Int8>
    switch renderer {
    case .xml: cString = cmark_render_xml(cNode, rawOptions)
    case .html: cString = cmark_render_html(cNode, rawOptions)
    case .manPage(let width): cString = cmark_render_man(cNode, rawOptions, numericCast(width))
    case .commonMark(let width):
      cString = cmark_render_commonmark(cNode, rawOptions, numericCast(width))
    case .latex(let width): cString = cmark_render_latex(cNode, rawOptions, numericCast(width))
    }

    return String(cString: cString)
  }
}
