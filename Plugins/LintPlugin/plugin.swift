import PackagePlugin
import Foundation

@main
struct LintPlugin {
  func lint(tool: PluginContext.Tool, targetDirectories: [String], configurationFilePath: String?) throws {
    let swiftFormatExec = URL(fileURLWithPath: tool.path.string)
    
    var arguments: [String] = ["lint"]
    
    arguments.append(contentsOf: targetDirectories)
    print(arguments)
    arguments.append(contentsOf: ["--recursive", "--parallel"])
    
    if let configurationFilePath = configurationFilePath {
      arguments.append(contentsOf: ["--configuration", configurationFilePath])
    }

    // Make sure that we don't have `--strict` anywhere in the args as it causes non-0 exits.
    arguments = arguments.filter { $0 != "--strict" }

    let process = try Process.run(swiftFormatExec, arguments: arguments)
    process.waitUntilExit()
    
    if process.terminationReason == .exit && process.terminationStatus == 0 {
      print("Linted the source code.")
    }
    else {
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
    let targetsToFormat = try context.package.targets(named: targetNames)
    
    let configurationFilePath = argExtractor.extractOption(named: "configuration").first
    
    let sourceCodeTargets = targetsToFormat.compactMap { $0 as? SourceModuleTarget }
    print(sourceCodeTargets)
    try lint(
      tool: swiftFormatTool,
      targetDirectories: sourceCodeTargets.map(\.directory.string),
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
    let configurationFilePath = argExtractor.extractOption(named: "configuration").first
    
    try lint(
      tool: swiftFormatTool,
      targetDirectories: [context.xcodeProject.directory.string],
      configurationFilePath: configurationFilePath
    )
  }
}
#endif
