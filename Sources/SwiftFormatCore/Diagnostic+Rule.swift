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

import SwiftSyntaxParser

extension Diagnostic.Message {
  /// Prepends the name of a rule to this diagnostic message.
  /// - parameter rule: The rule whose name will be prepended to the diagnostic.
  /// - returns: A new `Diagnostic.Message` with the name of the provided rule prepended.
  public func withRule(_ rule: Rule) -> Diagnostic.Message {
    return .init(severity, "[\(type(of: rule).ruleName)]: \(text)")
  }
}
