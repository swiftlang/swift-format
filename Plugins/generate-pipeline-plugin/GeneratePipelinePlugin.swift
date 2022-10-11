//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2022 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import PackagePlugin

/// The name of the Swift file to generate for a particular target.
let targetGeneratedSourceMapping = [
  "SwiftFormat": "Pipelines+Generated.swift",
  "SwiftFormatConfiguration": "RuleRegistry+Generated.swift",
  "SwiftFormatRules": "RuleNameCache+Generated.swift",
]

/// A Swift Package Manager build tool that runs `generate-pipeline` to generate the format/lint
/// pipelines from the current state of the rules.
@main
struct GeneratePipelinePlugin: BuildToolPlugin {
  enum Error: Swift.Error, CustomStringConvertible {
    /// The plugin was applied to a target that isn't supported.
    case notApplicableToTarget(String)

    var description: String {
      switch self {
      case .notApplicableToTarget(let target):
        return """
          'generate-pipeline-plugin' cannot be applied to '\(target)'; \
          supported targets are \(targetGeneratedSourceMapping.keys)
          """
      }
    }
  }

  func createBuildCommands(context: PluginContext, target: Target) throws -> [Command] {
    guard let generatedSourceName = targetGeneratedSourceMapping[target.name] else {
      throw Error.notApplicableToTarget(target.name)
    }

    let generatePipelineTool = try context.tool(named: "generate-pipeline")
    let sourcesDir = context.package.directory.appending("Sources")
    let outputFile = context.pluginWorkDirectory
      .appending("GeneratedSources")
      .appending(generatedSourceName)

    let rulesSources =
      (try context.package.targets(named: ["SwiftFormatRules"]).first as? SwiftSourceModuleTarget)?
      .sourceFiles.map(\.path) ?? []

    return [
      .buildCommand(
        displayName: "Generating \(generatedSourceName) for \(target.name)",
        executable: generatePipelineTool.path,
        arguments: [
          "--sources-directory",
          sourcesDir.string,
          "--output-file",
          outputFile.string,
          "--target",
          target.name,
        ],
        inputFiles: rulesSources,
        outputFiles: [outputFile]
      )
    ]
  }
}
