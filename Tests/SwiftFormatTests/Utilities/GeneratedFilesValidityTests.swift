//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2025 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import XCTest
@_spi(Internal) import _GenerateSwiftFormat

final class GeneratedFilesValidityTests: XCTestCase {
  var ruleCollector: RuleCollector!

  override func setUpWithError() throws {
    ruleCollector = RuleCollector()
    try ruleCollector.collect(from: GenerateSwiftFormatPaths.rulesDirectory)
  }

  func testGeneratedPipelineIsUpToDate() throws {
    let pipelineGenerator = PipelineGenerator(ruleCollector: ruleCollector)
    let generated = pipelineGenerator.generateContent()
    let fileContents = try String(contentsOf: GenerateSwiftFormatPaths.pipelineFile)
    XCTAssertEqual(
      generated,
      fileContents.normalizeNewlines(),
      "Pipelines+Generated.swift is out of date. Please run 'swift run generate-swift-format'."
    )
  }

  func testGeneratedRegistryIsUpToDate() throws {
    let registryGenerator = RuleRegistryGenerator(ruleCollector: ruleCollector)
    let generated = registryGenerator.generateContent()
    let fileContents = try String(contentsOf: GenerateSwiftFormatPaths.ruleRegistryFile)
    XCTAssertEqual(
      generated,
      fileContents.normalizeNewlines(),
      "RuleRegistry+Generated.swift is out of date. Please run 'swift run generate-swift-format'."
    )
  }

  func testGeneratedNameCacheIsUpToDate() throws {
    let ruleNameCacheGenerator = RuleNameCacheGenerator(ruleCollector: ruleCollector)
    let generated = ruleNameCacheGenerator.generateContent()
    let fileContents = try String(contentsOf: GenerateSwiftFormatPaths.ruleNameCacheFile)
    XCTAssertEqual(
      generated,
      fileContents.normalizeNewlines(),
      "RuleNameCache+Generated.swift is out of date. Please run 'swift run generate-swift-format'."
    )
  }

  func testGeneratedDocumentationIsUpToDate() throws {
    let ruleDocumentationGenerator = RuleDocumentationGenerator(ruleCollector: ruleCollector)
    let generated = ruleDocumentationGenerator.generateContent()
    let fileContents = try String(contentsOf: GenerateSwiftFormatPaths.ruleDocumentationFile)
    XCTAssertEqual(
      generated,
      fileContents.normalizeNewlines(),
      "RuleDocumentation.md is out of date. Please run 'swift run generate-swift-format'."
    )
  }
}

private extension String {
  /// Normalizes newlines for consistent comparison in tests.
  ///
  /// On Windows, `String(contentsOf:)` reads files with CRLF (`\r\n`) newlines,
  /// which cause false negatives when comparing against generated strings using LF (`\n`).
  func normalizeNewlines() -> String {
    #if os(Windows)
    return self.replacingOccurrences(of: "\r\n", with: "\n")
    #else
    return self
    #endif
  }
}
