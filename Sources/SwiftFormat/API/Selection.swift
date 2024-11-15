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
  case infinite
  case ranges([Range<AbsolutePosition>])

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

  public func contains(_ position: AbsolutePosition) -> Bool {
    switch self {
    case .infinite:
      return true
    case .ranges(let ranges):
      return ranges.contains { $0.contains(position) }
    }
  }

  public func overlapsOrTouches(_ range: Range<AbsolutePosition>) -> Bool {
    switch self {
    case .infinite:
      return true
    case .ranges(let ranges):
      return ranges.contains { $0.overlapsOrTouches(range) }
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
      return ranges.contains { return $0.lowerBound <= position && endPosition <= $0.upperBound }
    }
  }
}
