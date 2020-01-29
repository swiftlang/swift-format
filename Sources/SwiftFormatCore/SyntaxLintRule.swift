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

  /// The context in which the rule is executed.
  public let context: Context

  /// Creates a new rule in a given context.
  public required init(context: Context) {
    self.context = context
  }
}

extension Rule {
  /// Emits the provided diagnostic to the diagnostic engine.
  ///
  /// - Parameters:
  ///   - message: The diagnostic message to emit.
  ///   - node: The syntax node to which the diagnostic should be attached. The diagnostic will be
  ///     placed at the start of the node (excluding leading trivia).
  ///   - leadingTriviaIndex: If non-nil, the index of a trivia piece in the node's leading trivia
  ///     that should be used to determine the location of the diagnostic. Otherwise, the
  ///     diagnostic's location will be the start of the node after any leading trivia.
  ///   - actions: A set of actions to add notes, highlights, and fix-its to diagnostics.
  public func diagnose<SyntaxType: SyntaxProtocol>(
    _ message: Diagnostic.Message,
    on node: SyntaxType?,
    leadingTriviaIndex: Trivia.Index? = nil,
    actions: ((inout Diagnostic.Builder) -> Void)? = nil
  ) {
    let location: SourceLocation?
    if let leadingTriviaIndex = leadingTriviaIndex {
      location = node?.startLocation(
        ofLeadingTriviaAt: leadingTriviaIndex, converter: context.sourceLocationConverter)
    } else {
      location = node?.startLocation(converter: context.sourceLocationConverter)
    }
    context.diagnosticEngine?.diagnose(message.withRule(self), location: location, actions: actions)
  }
}
