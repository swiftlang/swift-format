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

/// A Markdown node that represents inline content; that is, content that only takes up as much
/// width as necessary and is laid out on the same line as sibling content (or is line-wrapped) when
/// rendered.
///
/// Examples of inline content include text, hyperlinks, and images.
///
/// At this time, the `InlineContent` protocol does not add any members of its own over what is
/// already required by `MarkdownNode`. Instead, it is used as a means of enforcing containment
/// relationships between nodes in the AST.
public protocol InlineContent: MarkdownNode {}
