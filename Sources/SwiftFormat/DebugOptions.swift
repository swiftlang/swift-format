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

/// Advanced options that are useful when debugging and developing the formatter, but are otherwise
/// not meant for general use.
public struct DebugOptions: OptionSet {

  /// Disables the pretty-printer pass entirely, executing only the syntax-transforming rules in the
  /// pipeline.
  public static let disablePrettyPrint = DebugOptions(rawValue: 1 << 0)

  /// Dumps a verbose representation of the raw pretty-printer token stream.
  public static let dumpTokenStream = DebugOptions(rawValue: 1 << 1)

  public let rawValue: Int

  public init(rawValue: Int) { self.rawValue = rawValue }

  /// Inserts or removes the given element from the option set, based on the value of `enabled`.
  public mutating func set(_ element: Element, enabled: Bool) {
    if enabled { insert(element) } else { remove(element) }
  }
}
