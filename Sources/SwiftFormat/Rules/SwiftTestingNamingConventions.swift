//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import SwiftSyntax

/// Enforces naming conventions for code that uses Swift Testing.
///
/// This rule has the following options in the `swiftTestingNamingConventions`
/// section of the configuration.
///
/// *   `forbidSuiteWithoutParameters`: If true, `@Suite` should not be used if
///     it doesn't specify any arguments; that is, marking a test type with
///     `@Suite` is unnecessary because any type with `@Test`s is automatically
///     a suite.
/// *   `forbidSuiteDescription`: If true, `@Suite` should not specify a
///     separate string description.
/// *   `requireRawIdentifierTestNames`: If true, `@Test` function names must be
///     raw identifiers.
/// *   `forbidTestDescription`: If true, `@Test` should not specify a separate
///      string description.
///
/// All options are `false` by default; because of this, the rule itself is not
/// opt-in, because it is a no-op until at least one of these options is set to
/// `true`.
///
/// Lint: Violating these rules yields a lint error.
@_spi(Rules)
public final class SwiftTestingNamingConventions: SyntaxLintRule {
  public override func visit(_ node: AttributeSyntax) -> SyntaxVisitorContinueKind {
    let config = context.configuration.swiftTestingNamingConventions
    if node.isAttribute(named: "Suite", inModule: "Testing") {
      if config.forbidSuiteDescription && node.hasUnlabeledStringDescription {
        diagnose(.doNotUseSuiteStringDescription, on: node)
      } else if config.forbidSuiteWithoutParameters && node.isEmpty {
        diagnose(.removeEmptySuiteAttribute, on: node)
      }
    } else if node.isAttribute(named: "Test", inModule: "Testing") {
      if config.forbidTestDescription && node.hasUnlabeledStringDescription {
        diagnose(.doNotUseTestStringDescription, on: node)
      }
    }
    return .skipChildren
  }

  public override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
    let config = context.configuration.swiftTestingNamingConventions
    if config.requireRawIdentifierTestNames && node.hasAttribute("Test", inModule: "Testing") {
      let functionName = node.name
      let text = functionName.text
      if !(text.hasPrefix("`") && text.hasSuffix("`")) {
        diagnose(.testFunctionNameMustBeRawIdentifier(name: text), on: functionName)
      }
    }
    return .visitChildren
  }
}

extension Finding.Message {
  fileprivate static let removeEmptySuiteAttribute: Finding.Message =
    "remove '@Suite' attribute when it is empty"

  fileprivate static let doNotUseSuiteStringDescription: Finding.Message =
    "remove the string description from '@Suite'"

  fileprivate static let doNotUseTestStringDescription: Finding.Message =
    "remove the string description from '@Test'"

  fileprivate static func testFunctionNameMustBeRawIdentifier(name: String) -> Finding.Message {
    """
    convert test function '\(name)' to a space-separated description \
    surrounded by backticks
    """
  }
}

extension AttributeSyntax {
  /// Returns true if the first argument of the attribute is an unlabeled string
  /// literal/interpolation.
  fileprivate var hasUnlabeledStringDescription: Bool {
    guard let arguments = self.arguments else {
      return false
    }
    switch arguments {
    case .argumentList(let list):
      guard let firstArg = list.first else { return false }
      return firstArg.label == nil && firstArg.expression.is(StringLiteralExprSyntax.self)
    default:
      return false
    }
  }
}
