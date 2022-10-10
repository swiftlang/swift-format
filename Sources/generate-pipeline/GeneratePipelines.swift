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

import ArgumentParser
import Foundation
import SwiftSyntax

/// The swift-format target for which sources should be generated.
enum Target: String, ExpressibleByArgument {
  case swiftFormat = "SwiftFormat"
  case swiftFormatConfiguration = "SwiftFormatConfiguration"
  case swiftFormatRules = "SwiftFormatRules"
}

@main
struct GeneratePipelines: ParsableCommand {
  @Option(help: "The path to the swift-format package's 'Sources' directory.")
  var sourcesDirectory: String

  @Option(help: "The path to the output file that should contain the generated source.")
  var outputFile: String

  @Option(help: "The swift-format target for which sources should be generated.")
  var target: Target

  func run() throws {
    let sourcesDirectoryURL = URL(fileURLWithPath: sourcesDirectory)
    let outputFileURL = URL(fileURLWithPath: outputFile)

    let rulesDirectory = sourcesDirectoryURL.appendingPathComponent("SwiftFormatRules")
    let ruleCollector = RuleCollector()
    try ruleCollector.collect(from: rulesDirectory)

    switch target {
    case .swiftFormat:
      // Generate a file with extensions for the lint and format pipelines.
      try PipelineGenerator(ruleCollector: ruleCollector).generateFile(at: outputFileURL)

    case .swiftFormatConfiguration:
      // Generate the rule registry dictionary for configuration.
      try RuleRegistryGenerator(ruleCollector: ruleCollector).generateFile(at: outputFileURL)

    case .swiftFormatRules:
      // Generate the rule name cache.
      try RuleNameCacheGenerator(ruleCollector: ruleCollector).generateFile(at: outputFileURL)
    }
  }
}
