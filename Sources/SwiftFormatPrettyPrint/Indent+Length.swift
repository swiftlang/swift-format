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

import SwiftFormatConfiguration

extension Indent {
  var character: Character {
    switch self {
    case .tabs: return "\t"
    case .spaces: return " "
    }
  }

  var text: String {
    return String(repeating: character, count: count)
  }

  func length(in configuration: Configuration) -> Int {
    switch self {
    case .spaces(let count): return count
    case .tabs(let count): return count * configuration.tabWidth
    }
  }
}

extension Array where Element == Indent {
  func indentation() -> String {
    return map { $0.text }.joined()
  }

  func length(in configuration: Configuration) -> Int {
    return reduce(into: 0) { $0 += $1.length(in: configuration) }
  }
}
