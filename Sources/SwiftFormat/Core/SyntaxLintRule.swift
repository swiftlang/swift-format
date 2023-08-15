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

import Foundation
import SwiftSyntax

/// A rule that lints a given file.
open class SyntaxLintRule: SyntaxVisitor, Rule {
  /// Whether this rule is opt-in, meaning it's disabled by default. Rules are opt-out unless they
  /// override this property.
  open class var isOptIn: Bool {
    return false
  }

  /// The context in which the rule is executed.
  public let context: Context

  /// Creates a new rule in a given context.
  public required init(context: Context) {
    self.context = context
    super.init(viewMode: .sourceAccurate)
  }
}
