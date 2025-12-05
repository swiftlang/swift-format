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

import Foundation
import PackagePlugin

@main
struct LintPlugin {
  func lint(tool: PluginContext.Tool, targetDirectories: [String], configurationFilePath: String?) throws {
    let swiftFormatExec = tool.url

    var arguments: [String] = ["lint"]

    arguments.append(contentsOf: targetDirectories)

    arguments.append(contentsOf: ["--recursive", "--parallel", "--strict"])

    if let configurationFilePath = configurationFilePath {
      arguments.append(contentsOf: ["--configuration", configurationFilePath])
    }

    let process = try Process.run(swiftFormatExec, arguments: arguments)
    process.waitUntilExit()

    if process.terminationReason == .exit && process.terminationStatus == 0 {
      print("Linted the source code.")
    } else {
      let problem = "\(process.terminationReason):\(process.terminationStatus)"
      Diagnostics.error("swift-format invocation failed: \(problem)")
    }
  }
}

extension LintPlugin: CommandPlugin {
  func performCommand(
    context: PluginContext,
    arguments: [String]
  ) async throws {
    let swiftFormatTool = try context.tool(named: "swift-format")

    // Extract the arguments that specify what targets to format.
    var argExtractor = ArgumentExtractor(arguments)
    let targetNames = argExtractor.extractOption(named: "target")

    let targetsToFormat =
      targetNames.isEmpty ? context.package.targets : try context.package.targets(named: targetNames)
    let configurationFilePath = argExtractor.extractOption(named: "swift-format-configuration").first

    let sourceCodeTargets = targetsToFormat.compactMap { $0 as? SourceModuleTarget }

    try lint(
      tool: swiftFormatTool,
      // This should be `directoryURL`, but it's only available in 6.1+
      targetDirectories: sourceCodeTargets.map { String(describing: $0.directory) },
      configurationFilePath: configurationFilePath
    )
  }
}

#if canImport(XcodeProjectPlugin)
import XcodeProjectPlugin

extension LintPlugin: XcodeCommandPlugin {
  func performCommand(context: XcodeProjectPlugin.XcodePluginContext, arguments: [String]) throws {
    let swiftFormatTool = try context.tool(named: "swift-format")
    var argExtractor = ArgumentExtractor(arguments)
    let configurationFilePath = argExtractor.extractOption(named: "swift-format-configuration").first

    try lint(
      tool: swiftFormatTool,
      targetDirectories: [context.xcodeProject.directoryURL.path()],
      configurationFilePath: configurationFilePath
    )
  }
}
#endif
