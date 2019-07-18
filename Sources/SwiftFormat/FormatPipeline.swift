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

/// A type that invokes individual format rules.
///
/// Note that this type is not a `SyntaxVisitor` or `SyntaxRewriter`. That is because, at this time,
/// we need to run each of the format rules individually over the entire syntax tree. We cannot
/// interleave them at the individual nodes like we do for lint rules, because some rules may want
/// to access the previous or next tokens. Doing so requires walking up to the parent node, but as
/// the tree is rewritten by one formatting rule, it will not be reattached to the tree until the
/// entire `visit` method has returned.
///
/// This file will be extended with a `visit` method in Pipelines+Generated.swift.
struct FormatPipeline {

  /// The formatter context.
  let context: Context

  /// Creates a new format pipeline.
  init(context: Context) {
    self.context = context
  }
}
