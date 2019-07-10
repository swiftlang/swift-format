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

/// A block element that represents a bulleted or numbered list.
public struct ListNode: BlockContent {

  /// Indicates the character that is used to separate the number of an ordered list item from the
  /// text of the item.
  public enum Delimiter {

    /// The number of the list item is followed by a period (e.g., `1.`).
    case period

    /// The number of the list item is followed by a closing parenthesis (e.g., `1)`).
    case parenthesis
  }

  /// The type of the list.
  public enum ListType: Equatable {

    /// The list is a bulleted list.
    case bulleted

    /// The list is an ordered list with the given delimiter and starting number.
    case ordered(delimiter: Delimiter, startingNumber: Int)
  }

  /// The type of the list (bulleted or ordered).
  ///
  /// If the type of the list is `.ordered`, then the type's associated values convey the delimiter
  /// of the items and their starting number.
  public let listType: ListType

  /// The items in the list.
  public let items: [ListItemNode]

  /// Indicates whether or not the list is tight.
  ///
  /// The tightness of a list affects its rendering. In HTML, for example, child `ParagraphNode`s of
  /// a tight list's items are not wrapped in `<p>` tags, but they are in a loose list.
  public let isTight: Bool

  public let sourceRange: Range<SourceLocation>?

  public var primitiveRepresentation: PrimitiveNode { return .list(self) }

  /// Creates a new list node.
  ///
  /// - Parameters:
  ///   - listType: The type of the list (bulleted or ordered).
  ///   - items: The items in the list.
  ///   - isTight: Indicates whether or not the list is tight.
  ///   - sourceRange: The source range from which the node was parsed, if known.
  public init(
    listType: ListType,
    items: [ListItemNode],
    isTight: Bool = false,
    sourceRange: Range<SourceLocation>? = nil
  ) {
    self.listType = listType
    self.items = items
    self.isTight = isTight
    self.sourceRange = sourceRange
  }

  /// Returns a new node equivalent to the receiver, but whose list type has been replaced with the
  /// given value.
  ///
  /// - Parameter listType: The new list type.
  /// - Returns: The new node.
  public func replacingListType(_ listType: ListType) -> ListNode {
    return ListNode(listType: listType, items: items, isTight: isTight, sourceRange: sourceRange)
  }

  /// Returns a new node equivalent to the receiver, but whose items have been replaced with the
  /// given list of nodes.
  ///
  /// - Parameter items: The new list of items.
  /// - Returns: The new node.
  public func replacingItems(_ items: [ListItemNode]) -> ListNode {
    return ListNode(listType: listType, items: items, isTight: isTight, sourceRange: sourceRange)
  }

  /// Returns a new node equivalent to the receiver, but whose tightness has been replaced with the
  /// given value.
  ///
  /// - Parameter isTight: The new list type.
  /// - Returns: The new node.
  public func replacingIsTight(_ isTight: Bool) -> ListNode {
    return ListNode(listType: listType, items: items, isTight: isTight, sourceRange: sourceRange)
  }

  /// Returns a new node equivalent to the receiver, but whose source range has been replaced with
  /// the given value.
  ///
  /// - Parameter sourceRange: The new source range.
  /// - Returns: The new node.
  public func replacingSourceRange(_ sourceRange: Range<SourceLocation>?) -> ListNode {
    return ListNode(listType: listType, items: items, isTight: isTight, sourceRange: sourceRange)
  }
}
