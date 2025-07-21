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
@_spi(Internal) import _GenerateSwiftFormat

let ruleCollector = RuleCollector()
try ruleCollector.collect(from: GenerateSwiftFormatPaths.rulesDirectory)

// Generate a file with extensions for the lint and format pipelines.
let pipelineGenerator = PipelineGenerator(ruleCollector: ruleCollector)
try pipelineGenerator.generateFile(at: GenerateSwiftFormatPaths.pipelineFile)

// Generate the rule registry dictionary for configuration.
let registryGenerator = RuleRegistryGenerator(ruleCollector: ruleCollector)
try registryGenerator.generateFile(at: GenerateSwiftFormatPaths.ruleRegistryFile)

// Generate the rule name cache.
let ruleNameCacheGenerator = RuleNameCacheGenerator(ruleCollector: ruleCollector)
try ruleNameCacheGenerator.generateFile(at: GenerateSwiftFormatPaths.ruleNameCacheFile)

// Generate the Documentation/RuleDocumentation.md file with rule descriptions.
// This uses DocC comments from rule implementations.
let ruleDocumentationGenerator = RuleDocumentationGenerator(ruleCollector: ruleCollector)
try ruleDocumentationGenerator.generateFile(at: GenerateSwiftFormatPaths.ruleDocumentationFile)
