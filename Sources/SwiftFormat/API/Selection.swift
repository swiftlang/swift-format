//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2024 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import Foundation
import SwiftSyntax

/// The selection as given on the command line - an array of offets and lengths
public enum Selection {
  /// The entire file is selected.
  case infinite

  /// A selection representing the given open ranges of UTF-8 offsets.
  case ranges([Range<AbsolutePosition>])

  /// A selection representing the given closed ranges of line numbers.
  case unresolvedLineRanges([ClosedRange<Int>])

  /// Create a selection from an array of utf8 ranges. An empty array means an infinite selection.
  public init(offsetRanges: [Range<Int>]) {
    if offsetRanges.isEmpty {
      self = .infinite
    } else {
      let ranges = offsetRanges.map {
        AbsolutePosition(utf8Offset: $0.lowerBound)..<AbsolutePosition(utf8Offset: $0.upperBound)
      }
      self = .ranges(ranges)
    }
  }

  public init(lineRanges: [ClosedRange<Int>]) {
    if lineRanges.isEmpty {
      self = .infinite
    } else {
      self = .unresolvedLineRanges(lineRanges)
    }
  }

  public func resolved(with converter: SourceLocationConverter) -> Selection {
    switch self {
    case .infinite, .ranges:
      return self
    case .unresolvedLineRanges(let lineRanges):
      let resolvedRanges: [Range<AbsolutePosition>] = lineRanges.compactMap { lineRange in
        let start = converter.position(ofLine: lineRange.lowerBound, column: 1)
        let nextLineStart = converter.position(ofLine: lineRange.upperBound + 1, column: 1)
        if start == nextLineStart {
          return nil
        }
        // Subtract 1 from the next line's start offset to get the end of the current line.
        let end = AbsolutePosition(utf8Offset: nextLineStart.utf8Offset - 1)
        return start..<end
      }
      return .ranges(resolvedRanges)
    }
  }

  public func contains(_ position: AbsolutePosition) -> Bool {
    switch self {
    case .infinite:
      return true
    case .ranges(let ranges):
      return ranges.contains { $0.contains(position) }
    case .unresolvedLineRanges:
      fatalError("Must resolve Selection before calling contains")
    }
  }

  public func overlapsOrTouches(_ range: Range<AbsolutePosition>) -> Bool {
    switch self {
    case .infinite:
      return true
    case .ranges(let ranges):
      return ranges.contains { $0.overlapsOrTouches(range) }
    case .unresolvedLineRanges:
      fatalError("Must resolve Selection before calling overlapsOrTouches")
    }
  }

  /// Returns a copy of this selection with its UTF-8 byte ranges adjusted to account for syntax
  /// rewrites between `oldTree` and `newTree`.
  func adjusted(from oldTree: Syntax, to newTree: Syntax) -> Selection {
    switch self {
    case .infinite:
      return .infinite
    case .ranges(let ranges):
      guard !ranges.isEmpty else { return self }
      var edits: [(range: Range<AbsolutePosition>, delta: Int)] = []
      Self.collectEdits(from: oldTree, to: newTree, into: &edits)
      guard !edits.isEmpty else { return self }

      let adjustedRanges = ranges.map { range -> Range<AbsolutePosition> in
        var lowerDelta = 0
        var upperDelta = 0
        for edit in edits {
          if edit.range.upperBound.utf8Offset <= range.lowerBound.utf8Offset {
            lowerDelta += edit.delta
            upperDelta += edit.delta
          } else if edit.range.lowerBound.utf8Offset < range.upperBound.utf8Offset {
            if edit.range.lowerBound.utf8Offset < range.lowerBound.utf8Offset {
              let minLower = edit.range.lowerBound.utf8Offset - range.lowerBound.utf8Offset
              lowerDelta += max(minLower, min(0, edit.delta))
            }
            upperDelta += edit.delta
          }
        }
        let newLower = max(0, range.lowerBound.utf8Offset + lowerDelta)
        let newUpper = max(newLower, range.upperBound.utf8Offset + upperDelta)
        return AbsolutePosition(utf8Offset: newLower)..<AbsolutePosition(utf8Offset: newUpper)
      }
      return .ranges(adjustedRanges)
    case .unresolvedLineRanges:
      fatalError("Must resolve Selection before calling adjusted(from:to:)")
    }
  }

  /// Recursively computes the UTF-8 byte-length deltas between `oldNode` and `newNode`, expressed
  /// in the coordinate space of `oldNode`.
  private static func collectEdits(
    from oldNode: Syntax,
    to newNode: Syntax,
    into edits: inout [(range: Range<AbsolutePosition>, delta: Int)]
  ) {
    if oldNode.detached == newNode.detached {
      return
    }

    if oldNode.kind == newNode.kind {
      let oldChildren = Array(oldNode.children(viewMode: .all))
      let newChildren = Array(newNode.children(viewMode: .all))
      if !oldChildren.isEmpty || !newChildren.isEmpty {
        var prefixCount = 0
        while prefixCount < oldChildren.count,
          prefixCount < newChildren.count,
          oldChildren[prefixCount].detached == newChildren[prefixCount].detached
        {
          prefixCount += 1
        }

        var suffixCount = 0
        while suffixCount < (oldChildren.count - prefixCount),
          suffixCount < (newChildren.count - prefixCount),
          oldChildren[oldChildren.count - 1 - suffixCount].detached
            == newChildren[newChildren.count - 1 - suffixCount].detached
        {
          suffixCount += 1
        }

        let oldMid = oldChildren[prefixCount..<(oldChildren.count - suffixCount)]
        let newMid = newChildren[prefixCount..<(newChildren.count - suffixCount)]

        if oldMid.count == newMid.count {
          for (oldChild, newChild) in zip(oldMid, newMid) {
            collectEdits(from: oldChild, to: newChild, into: &edits)
          }
          return
        }

        let newLen = newMid.reduce(0) { $0 + $1.totalLength.utf8Length }
        if let firstOld = oldMid.first, let lastOld = oldMid.last {
          let start = firstOld.position
          let end = lastOld.endPosition
          let oldLen = end.utf8Offset - start.utf8Offset
          let delta = newLen - oldLen
          if delta != 0 {
            edits.append((range: start..<end, delta: delta))
          }
        } else if newLen != 0 {
          let insertionPoint: AbsolutePosition
          if prefixCount > 0 {
            insertionPoint = oldChildren[prefixCount - 1].endPosition
          } else if suffixCount > 0 {
            insertionPoint = oldChildren[oldChildren.count - suffixCount].position
          } else {
            insertionPoint = oldNode.position
          }
          edits.append((range: insertionPoint..<insertionPoint, delta: newLen))
        }
        return
      }
    }

    let delta = newNode.totalLength.utf8Length - oldNode.totalLength.utf8Length
    if delta != 0 {
      edits.append((range: oldNode.position..<oldNode.endPosition, delta: delta))
    }
  }
}

public extension Syntax {
  /// - Returns: `true` if the node is _completely_ inside any range in the selection
  func isInsideSelection(_ selection: Selection) -> Bool {
    switch selection {
    case .infinite:
      return true
    case .ranges(let ranges):
      return ranges.contains {
        return $0.lowerBound <= positionAfterSkippingLeadingTrivia
          && endPositionBeforeTrailingTrivia <= $0.upperBound
      }
    case .unresolvedLineRanges:
      fatalError("Must resolve Selection before calling isInsideSelection")
    }
  }
}
