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

import SwiftFormatCore
import SwiftSyntax

/// A syntax visitor that delegates to individual rules for linting.
///
/// This file will be extended with `visit` methods in Pipelines+Generated.swift.
struct LintPipeline: SyntaxVisitor {

  /// The formatter context.
  let context: Context

  /// Creates a new lint pipeline.
  init(context: Context) {
    self.context = context
  }
}
