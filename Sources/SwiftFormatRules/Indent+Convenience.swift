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
import SwiftSyntax

extension Indent {

  public var asTrivia: Trivia {
    switch self {
    case .spaces(let num):
      return [.spaces(num)]
    case .tabs(let num):
      return [.tabs(num)]
    }
  }
}
