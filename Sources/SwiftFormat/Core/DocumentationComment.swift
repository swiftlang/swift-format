//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2023 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import Markdown
import SwiftSyntax

/// A structured representation of information extracted from a documentation comment.
///
/// This type represents both the top-level content of a documentation comment on a declaration and
/// also the nested information that can be provided on a parameter. For example, when a parameter
/// is a function type, it can provide not only a brief summary but also its own parameter and
/// return value descriptions.
@_spi(Testing)
public struct DocumentationComment {
  /// A description of a parameter in a documentation comment.
  public struct Parameter {
    /// The name of the parameter.
    public var name: String

    /// The documentation comment of the parameter.
    ///
    /// Typically, only the `briefSummary` field of this value will be populated. However, for more
    /// complex cases like parameters whose types are functions, the grammar permits full
    /// descriptions including `Parameter(s)`, `Returns`, and `Throws` fields to be present.
    public var comment: DocumentationComment
  }

  /// Describes the structural layout of the parameter descriptions in the comment.
  public enum ParameterLayout {
    /// All parameters were written under a single `Parameters` outline section at the top level of
    /// the comment.
    case outline

    /// All parameters were written as individual `Parameter` items at the top level of the comment.
    case separated

    /// Parameters were written as a combination of one or more `Parameters` outlines and individual
    /// `Parameter` items.
    case mixed
  }

  /// A single paragraph representing a brief summary of the declaration, if present.
  public var briefSummary: Paragraph? = nil

  /// A collection of otherwise uncategorized body nodes at the top level of the comment text.
  ///
  /// If a brief summary paragraph was extracted from the comment, it will not be present in this
  /// collection.
  public var bodyNodes: [Markup] = []

  /// The structural layout of the parameter descriptions in the comment.
  public var parameterLayout: ParameterLayout? = nil

  /// Descriptions of parameters to a function, if any.
  public var parameters: [Parameter] = []

  /// A description of the return value of a function.
  ///
  /// If present, this value is a copy of the `Paragraph` node from the comment but with the
  /// `Returns:` prefix removed for convenience.
  public var returns: Paragraph? = nil

  /// A description of an error thrown by a function.
  ///
  /// If present, this value is a copy of the `Paragraph` node from the comment but with the
  /// `Throws:` prefix removed for convenience.
  public var `throws`: Paragraph? = nil

  /// Creates a new `DocumentationComment` with information extracted from the leading trivia of the
  /// given syntax node.
  ///
  /// If the syntax node does not have a preceding documentation comment, this initializer returns
  /// `nil`.
  ///
  /// - Parameter node: The syntax node from which the documentation comment should be extracted.
  public init?<Node: SyntaxProtocol>(extractedFrom node: Node) {
    guard let commentInfo = DocumentationCommentText(extractedFrom: node.leadingTrivia) else {
      return nil
    }

    // Disable smart quotes and dash conversion since we want to preserve the original content of
    // the comments instead of doing documentation generation.
    let doc = Document(parsing: commentInfo.text, options: [.disableSmartOpts])
    self.init(markup: doc)
  }

  /// Creates a new `DocumentationComment` from the given `Markup` node.
  private init(markup: Markup) {
    // Extract the first paragraph as the brief summary. It will *not* be included in the body
    // nodes.
    let remainingChildren: DropFirstSequence<MarkupChildren>
    if let firstParagraph = markup.child(through: [(0, Paragraph.self)]) {
      briefSummary = firstParagraph.detachedFromParent as? Paragraph
      remainingChildren = markup.children.dropFirst()
    } else {
      briefSummary = nil
      remainingChildren = markup.children.dropFirst(0)
    }

    for child in remainingChildren {
      if var list = child.detachedFromParent as? UnorderedList {
        // An unordered list could be one of the following:
        //
        // 1.  A parameter outline:
        //     - Parameters:
        //       - x: ...
        //       - y: ...
        //
        // 2.  An exploded parameter list:
        //     - Parameter x: ...
        //     - Parameter y: ...
        //
        // 3.  Some other simple field, like `Returns:`.
        //
        // Note that the order of execution of these two functions matters for the correct value of
        // `parameterLayout` to be computed. If these ever change, make sure to update that
        // computation inside the functions.
        extractParameterOutline(from: &list)
        extractSeparatedParameters(from: &list)

        extractSimpleFields(from: &list)

        // If the list is now empty, don't add it to the body nodes below.
        guard !list.isEmpty else { continue }
      }

      bodyNodes.append(child.detachedFromParent)
    }
  }

  /// Extracts parameter fields in an outlined parameters list (i.e., `- Parameters:` containing a
  /// nested list of parameter fields) from the given unordered list.
  ///
  /// If parameters were successfully extracted, the provided list is mutated to remove them as a
  /// side effect of this function.
  private mutating func extractParameterOutline(from list: inout UnorderedList) {
    var unprocessedChildren: [Markup] = []

    for child in list.children {
      guard
        let listItem = child as? ListItem,
        let firstText = listItem.child(through: [
          (0, Paragraph.self),
          (0, Text.self),
        ]) as? Text,
        firstText.string.trimmingCharacters(in: .whitespaces).lowercased() == "parameters:"
      else {
        unprocessedChildren.append(child.detachedFromParent)
        continue
      }

      for index in 1..<listItem.childCount {
        let listChild = listItem.child(at: index)
        guard let sublist = listChild as? UnorderedList else { continue }
        for sublistItem in sublist.listItems {
          guard
            let paramField = parameterField(extractedFrom: sublistItem, expectParameterLabel: false)
          else {
            continue
          }
          self.parameters.append(paramField)
          self.parameterLayout = .outline
        }
      }
    }

    list = list.withUncheckedChildren(unprocessedChildren) as! UnorderedList
  }

  /// Extracts parameter fields in separated form (i.e., individual `- Parameter <name>:` items in
  /// a top-level list in the comment text) from the given unordered list.
  ///
  /// If parameters were successfully extracted, the provided list is mutated to remove them as a
  /// side effect of this function.
  private mutating func extractSeparatedParameters(from list: inout UnorderedList) {
    var unprocessedChildren: [Markup] = []

    for child in list.children {
      guard
        let listItem = child as? ListItem,
        let paramField = parameterField(extractedFrom: listItem, expectParameterLabel: true)
      else {
        unprocessedChildren.append(child.detachedFromParent)
        continue
      }

      self.parameters.append(paramField)

      switch self.parameterLayout {
      case nil:
        self.parameterLayout = .separated
      case .outline:
        self.parameterLayout = .mixed
      default:
        break
      }
    }

    list = list.withUncheckedChildren(unprocessedChildren) as! UnorderedList
  }

  /// Returns a new `ParameterField` containing parameter information extracted from the given list
  /// item, or `nil` if it was not a valid parameter field.
  private func parameterField(
    extractedFrom listItem: ListItem,
    expectParameterLabel: Bool
  ) -> Parameter? {
    var rewriter = ParameterOutlineMarkupRewriter(
      origin: listItem,
      expectParameterLabel: expectParameterLabel
    )
    guard
      let newListItem = listItem.accept(&rewriter) as? ListItem,
      let name = rewriter.parameterName
    else { return nil }

    return Parameter(name: name, comment: DocumentationComment(markup: newListItem))
  }

  /// Extracts simple fields like `- Returns:` and `- Throws:` from the top-level list in the
  /// comment text.
  ///
  /// If fields were successfully extracted, the provided list is mutated to remove them.
  private mutating func extractSimpleFields(from list: inout UnorderedList) {
    var unprocessedChildren: [Markup] = []

    for child in list.children {
      guard
        let listItem = child as? ListItem,
        case var rewriter = SimpleFieldMarkupRewriter(origin: listItem),
        listItem.accept(&rewriter) as? ListItem != nil,
        let name = rewriter.fieldName,
        let paragraph = rewriter.paragraph
      else {
        unprocessedChildren.append(child)
        continue
      }

      switch name.lowercased() {
      case "returns":
        self.returns = paragraph
      case "throws":
        self.throws = paragraph
      default:
        unprocessedChildren.append(child)
      }
    }

    list = list.withUncheckedChildren(unprocessedChildren) as! UnorderedList
  }
}

/// Visits a list item representing a parameter in a documentation comment and rewrites it to remove
/// any `Parameter` tag (if present), the name of the parameter, and the subsequent colon.
private struct ParameterOutlineMarkupRewriter: MarkupRewriter {
  /// The list item to which the rewriter will be applied.
  let origin: ListItem

  /// If true, the `Parameter` prefix is expected on the list item content and it should be dropped.
  let expectParameterLabel: Bool

  /// Populated if the list item to which this is applied represents a valid parameter field.
  private(set) var parameterName: String? = nil

  mutating func visitListItem(_ listItem: ListItem) -> Markup? {
    // Only recurse into the exact list item we're applying this to; otherwise, return it unchanged.
    guard listItem.isIdentical(to: origin) else { return listItem }
    return defaultVisit(listItem)
  }

  mutating func visitParagraph(_ paragraph: Paragraph) -> Markup? {
    // Only recurse into the first paragraph in the list item.
    guard paragraph.indexInParent == 0 else { return paragraph }
    return defaultVisit(paragraph)
  }

  mutating func visitText(_ text: Text) -> Markup? {
    // Only manipulate the first text node (of the first paragraph).
    guard text.indexInParent == 0 else { return text }

    let parameterPrefix = "parameter "
    if expectParameterLabel && !text.string.lowercased().hasPrefix(parameterPrefix) { return text }

    let string =
      expectParameterLabel ? text.string.dropFirst(parameterPrefix.count) : text.string[...]
    let nameAndRemainder = string.split(separator: ":", maxSplits: 1)
    guard nameAndRemainder.count == 2 else { return text }

    let name = nameAndRemainder[0].trimmingCharacters(in: .whitespaces)
    guard !name.isEmpty else { return text }

    self.parameterName = name
    return Text(String(nameAndRemainder[1]))
  }
}

/// Visits a list item representing a simple field in a documentation comment and rewrites it to
/// extract the field name, removing it and the subsequent colon from the item.
private struct SimpleFieldMarkupRewriter: MarkupRewriter {
  /// The list item to which the rewriter will be applied.
  let origin: ListItem

  /// Populated if the list item to which this is applied represents a valid simple field.
  private(set) var fieldName: String? = nil

  /// Populated if the list item to which this is applied represents a valid simple field.
  private(set) var paragraph: Paragraph? = nil

  mutating func visitListItem(_ listItem: ListItem) -> Markup? {
    // Only recurse into the exact list item we're applying this to; otherwise, return it unchanged.
    guard listItem.isIdentical(to: origin) else { return listItem }
    return defaultVisit(listItem)
  }

  mutating func visitParagraph(_ paragraph: Paragraph) -> Markup? {
    // Only recurse into the first paragraph in the list item.
    guard paragraph.indexInParent == 0 else { return paragraph }
    guard let newNode = defaultVisit(paragraph) else { return nil }
    guard let newParagraph = newNode as? Paragraph else { return newNode }
    self.paragraph = newParagraph.detachedFromParent as? Paragraph
    return newParagraph
  }

  mutating func visitText(_ text: Text) -> Markup? {
    // Only manipulate the first text node (of the first paragraph).
    guard text.indexInParent == 0 else { return text }

    let nameAndRemainder = text.string.split(separator: ":", maxSplits: 1)
    guard nameAndRemainder.count == 2 else { return text }

    let name = nameAndRemainder[0].trimmingCharacters(in: .whitespaces)
    guard !name.isEmpty else { return text }

    self.fieldName = name
    return Text(String(nameAndRemainder[1]))
  }
}
