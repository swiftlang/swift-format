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

/// Describes the available types of renderers that can be used to transform a tree of Markdown
/// nodes into various text formats.
public enum MarkdownRenderer {

  /// Options that control the rendering of Markdown nodes into text.
  public struct Options: OptionSet {

    /// The renderer should include `data-sourcepos` attributes on all block elements that map the
    /// nodes back to their original source positions in the Markdown text.
    ///
    /// This option is only supported by the `html` and `xml` renderers; it is ignored by the
    /// others.
    public static let includeSourcePositions = Options(rawValue: CMARK_OPT_SOURCEPOS)

    /// The renderer should render soft breaks as hard line breaks.
    ///
    /// This option is only supported by the `commonMark` and `html` renderers, but the `commonMark`
    /// behavior is somewhat misaligned with the name of the option:
    ///
    /// * `commonMark`: When this option is not present, soft breaks are rendered according to the
    ///   wrapping behavior of the renderer (a newline when wrapping is disabled or a single space
    ///   when wrapping is enabled) and line breaks are rendered as a backslash followed by a
    ///   newline. When this option is present, wrapping is automatically disabled; soft breaks are
    ///   rendered as a space and line breaks are rendered as a newline with no trailing backslash.
    ///
    /// * `html`: When this option is not present, soft breaks are rendered as a newline in the
    ///   output and line breaks are rendered as a `<br>` tag. When this option is present, both
    ///   types of breaks are rendered as `<br>` tags.
    public static let forceHardBreaks = Options(rawValue: CMARK_OPT_HARDBREAKS)

    /// The renderer should suppress raw HTML and unsafe links (URLs with schemes `javascript:`,
    /// `vbscript:`, `file:`, and `data:` except for `image/png`, `image/gif`, `image/jpeg`, or
    /// `image/webp` MIME types).
    ///
    /// Raw HTML is replaced by a placeholder HTML comment, and unsafe links are replaced by empty
    /// strings. This option is only supported by the `html` renderer.
    public static let sanitizeHTML = Options(rawValue: CMARK_OPT_SAFE)

    public let rawValue: Int32

    public init(rawValue: Int32) {
      self.rawValue = rawValue
    }
  }

  /// Renders the nodes as XML.
  case xml

  /// Renders the nodes as HTML.
  ///
  /// This renderer does not output a complete HTML file, but instead only an HTML fragment
  /// corresponding to the content of the nodes starting from the root. It is the caller's
  /// responsibility to add any necessary HTML (such as `head` and `body` tags) before and after the
  /// rendered output to make it complete.
  case html

  /// Renders the nodes as a groff `man` page, without the header, with the given maximum line
  /// length.
  ///
  /// A width of zero disables line wrapping. The convenience property `manPage` can also be used
  /// for this.
  case manPage(width: Int)

  /// Renders the nodes as Markdown with the given maximum line length.
  ///
  /// A width of zero disables line wrapping. The convenience property `commonMark` can also be used
  /// for this.
  ///
  /// If `MarkdownRenderer.Options.forceHardBreaks` is specified when rendering, the `width` value
  /// is ignored and treated as if it were zero (wrapping is disabled).
  case commonMark(width: Int)

  /// Renders the nodes as LaTeX with the given maximum line length.
  ///
  /// A width of zero disables line wrapping. The convenience property `latex` can also be used for
  /// this.
  case latex(width: Int)

  /// A convenience property for a groff `man` page renderer that does not perform line wrapping.
  public static let manPage = MarkdownRenderer.manPage(width: 0)

  /// A convenience property for a Markdown renderer that does not perform line wrapping.
  public static let commonMark = MarkdownRenderer.commonMark(width: 0)

  /// A convenience property for a LaTeX renderer that does not perform line wrapping.
  public static let latex = MarkdownRenderer.latex(width: 0)
}
