import PackagePlugin
import Foundation

@main
struct LintPlugin {
  private func lint(tool: PluginContext.Tool, targetDirectories: [String], configurationFilePath: String?) throws {
    let swiftFormatExec = URL(fileURLWithPath: tool.path.string)
    
    var swiftFormatArgs = ["lint"]
    swiftFormatArgs.append(contentsOf: targetDirectories)
    swiftFormatArgs.append(contentsOf: ["--recursive", "--parallel", "--strict"])
    if let configurationFilePath {
      swiftFormatArgs.append(contentsOf: ["--configuration", configurationFilePath])
    }
    
    let process = try Process.run(swiftFormatExec, arguments: swiftFormatArgs)
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
    let sourceCodeTargets = targetsToFormat.compactMap { $0 as? SourceModuleTarget }
    
    let configurationFilePath = argExtractor.extractOption(named: "configuration").first
    
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
