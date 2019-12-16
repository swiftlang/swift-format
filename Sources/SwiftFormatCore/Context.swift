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
import SwiftFormatConfiguration
import SwiftSyntax

/// Context contains the bits that each formatter and linter will need access to.
///
/// Specifically, it is the container for the shared configuration, diagnostic engine, and URL of
/// the current file.
public class Context {

  /// Tracks whether `XCTest` has been imported so that certain logic can be modified for files that
  /// are known to be tests.
  public enum XCTestImportState {

    /// Whether `XCTest` is imported or not has not yet been determined.
    case notDetermined

    /// The file is known to import `XCTest`.
    case importsXCTest

    /// The file is known to not import `XCTest`.
    case doesNotImportXCTest
  }

  /// The configuration for this run of the pipeline, provided by a configuration JSON file.
  public let configuration: Configuration

  /// The engine in which to emit diagnostics, if running in Lint mode.
  public let diagnosticEngine: DiagnosticEngine?

  /// The URL of the file being linted or formatted.
  public let fileURL: URL

  /// Indicates whether the file is known to import XCTest.
  public var importsXCTest: XCTestImportState

  /// An object that converts `AbsolutePosition` values to `SourceLocation` values.
  public let sourceLocationConverter: SourceLocationConverter

  /// Contains the rules have been disabled by comments for certain line numbers.
  public let ruleMask: RuleMask

  /// Creates a new Context with the provided configuration, diagnostic engine, and file URL.
  public init(
    configuration: Configuration,
    diagnosticEngine: DiagnosticEngine?,
    fileURL: URL,
    sourceFileSyntax: SourceFileSyntax
  ) {
    self.configuration = configuration
    self.diagnosticEngine = diagnosticEngine
    self.fileURL = fileURL
    self.importsXCTest = .notDetermined
    self.sourceLocationConverter = SourceLocationConverter(
      file: fileURL.path, tree: sourceFileSyntax)
    self.ruleMask = RuleMask(
      syntaxNode: sourceFileSyntax,
      sourceLocationConverter: sourceLocationConverter
    )
  }

  /// Given a rule's name and the node it is examining, determine if the rule is disabled at this
  /// location or not.
  public func isRuleEnabled(_ ruleName: String, node: Syntax) -> Bool {
    let loc = node.startLocation(converter: self.sourceLocationConverter)
    switch ruleMask.ruleState(ruleName, at: loc) {
    case .default:
      return configuration.rules[ruleName] ?? false
    case .disabled:
      return false
    }
  }
}
