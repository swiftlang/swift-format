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

/// Represents an indentation unit that is applied to lines that are pretty-printed.
public enum Indent: Hashable, Codable {

  /// An indentation unit equal to the given number of tab characters.
  ///
  /// This value is independent of the actual tab width, which is set separately in the
  /// `Configuration`.
  case tabs(Int)

  /// An indentation unit equal to the given number of spaces.
  case spaces(Int)

  private enum CodingKeys: CodingKey {
    case tabs
    case spaces
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let spacesCount = try container.decodeIfPresent(Int.self, forKey: .spaces)
    let tabsCount = try container.decodeIfPresent(Int.self, forKey: .tabs)

    if spacesCount != nil && tabsCount != nil {
      throw DecodingError.dataCorrupted(
        DecodingError.Context(
          codingPath: decoder.codingPath,
          debugDescription: "Only one of \"tabs\" or \"spaces\" may be specified"
        )
      )
    }
    if let spacesCount = spacesCount {
      self = .spaces(spacesCount)
      return
    }
    if let tabsCount = tabsCount {
      self = .tabs(tabsCount)
      return
    }

    throw DecodingError.dataCorrupted(
      DecodingError.Context(
        codingPath: decoder.codingPath,
        debugDescription: "One of \"tabs\" or \"spaces\" must be specified"
      )
    )
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    switch self {
    case .tabs(let count):
      try container.encode(count, forKey: .tabs)
    case .spaces(let count):
      try container.encode(count, forKey: .spaces)
    }
  }

  /// Returns the number of units (tabs or spaces) that this indent represents.
  ///
  /// Note that this does _not_ represent the physical number of spaces occupied by the indentation.
  public var count: Int {
    switch self {
    case .spaces(let count):
      return count
    case .tabs(let count):
      return count
    }
  }
}
