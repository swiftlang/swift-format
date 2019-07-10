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

// This file contains workarounds for bugs in SwiftSyntax (or the compiler itself) and should
// hopefully be temporary.

import SwiftSyntax

extension FunctionParameterSyntax {

  /// The optional trailing comma that follows a function parameter, implementing a workaround for a
  /// bug in the Swift 4.2 compiler (and, at the time of this writing, also in master).
  ///
  /// If a function parameter has either an ellipsis or default argument expression, the trailing
  /// comma (if present) is located correctly in the layout at index 7. However, if neither an
  /// ellipsis or default argument is present, the comma token will be incorrectly located at index
  /// 5 (where the ellipsis would normally be). This workaround checks the expected location first,
  /// then falls back to the incorrect location to find a comma before giving up. (rdar://43690589)
  public var trailingCommaWorkaround: TokenSyntax? {
    if let comma = trailingComma { return comma }
    if let comma = ellipsis, comma.tokenKind == .comma { return comma }
    return nil
  }
}

extension TupleTypeElementSyntax {
  public var secondNameWorkaround: TokenSyntax? {
    if let secondName = secondName { return secondName }
    if let secondName = name { return secondName }
    return nil
  }

  public var trailingCommaWorkaround: TokenSyntax? {
    if let comma = trailingComma { return comma }
    if let comma = ellipsis, comma.tokenKind == .comma { return comma }
    return nil
  }
}
