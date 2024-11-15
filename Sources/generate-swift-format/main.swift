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

let sourcesDirectory = URL(fileURLWithPath: #file)
  .deletingLastPathComponent()
  .deletingLastPathComponent()
let rulesDirectory =
  sourcesDirectory
  .appendingPathComponent("SwiftFormat")
  .appendingPathComponent("Rules")
let pipelineFile =
  sourcesDirectory
  .appendingPathComponent("SwiftFormat")
  .appendingPathComponent("Core")
  .appendingPathComponent("Pipelines+Generated.swift")
let ruleRegistryFile =
  sourcesDirectory
  .appendingPathComponent("SwiftFormat")
  .appendingPathComponent("Core")
  .appendingPathComponent("RuleRegistry+Generated.swift")

let ruleNameCacheFile =
  sourcesDirectory
  .appendingPathComponent("SwiftFormat")
  .appendingPathComponent("Core")
  .appendingPathComponent("RuleNameCache+Generated.swift")

let ruleDocumentationFile =
  sourcesDirectory
  .appendingPathComponent("..")
  .appendingPathComponent("Documentation")
  .appendingPathComponent("RuleDocumentation.md")

var ruleCollector = RuleCollector()
try ruleCollector.collect(from: rulesDirectory)

// Generate a file with extensions for the lint and format pipelines.
let pipelineGenerator = PipelineGenerator(ruleCollector: ruleCollector)
try pipelineGenerator.generateFile(at: pipelineFile)

// Generate the rule registry dictionary for configuration.
let registryGenerator = RuleRegistryGenerator(ruleCollector: ruleCollector)
try registryGenerator.generateFile(at: ruleRegistryFile)

// Generate the rule name cache.
let ruleNameCacheGenerator = RuleNameCacheGenerator(ruleCollector: ruleCollector)
try ruleNameCacheGenerator.generateFile(at: ruleNameCacheFile)

// Generate the Documentation/RuleDocumentation.md file with rule descriptions.
// This uses DocC comments from rule implementations.
let ruleDocumentationGenerator = RuleDocumentationGenerator(ruleCollector: ruleCollector)
try ruleDocumentationGenerator.generateFile(at: ruleDocumentationFile)
