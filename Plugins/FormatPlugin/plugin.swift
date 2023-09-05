import PackagePlugin
import Foundation

@main
struct FormatPlugin {
  private func format(tool: PluginContext.Tool, targetDirectories: [String], configurationFilePath: String?) throws {
    let swiftFormatExec = URL(fileURLWithPath: tool.path.string)
    
    var swiftFormatArgs = ["format"]
    swiftFormatArgs.append(contentsOf: targetDirectories)
    swiftFormatArgs.append(contentsOf: ["--recursive", "--parallel", "--in-place"])
    if let configurationFilePath {
      swiftFormatArgs.append(contentsOf: ["--configuration", configurationFilePath])
    }
    
    let process = try Process.run(swiftFormatExec, arguments: swiftFormatArgs)
    process.waitUntilExit()
    
    if process.terminationReason == .exit && process.terminationStatus == 0 {
      print("Formatted the source code.")
    }
    else {
      let problem = "\(process.terminationReason):\(process.terminationStatus)"
      Diagnostics.error("swift-format invocation failed: \(problem)")
    }
  }
}

extension FormatPlugin: CommandPlugin {
  func performCommand(
    context: PluginContext,
    arguments: [String]
  ) async throws {
    let swiftFormatTool = try context.tool(named: "swift-format")
    
    var argExtractor = ArgumentExtractor(arguments)
    let targetNames = argExtractor.extractOption(named: "target")
    let targetDirectories = try context.package.targets(named: targetNames)
      .compactMap { $0 as? SourceModuleTarget }
      .map(\.directory.string)
    
    let configurationFilePath = argExtractor.extractOption(named: "configuration").first
    
    try format(
      tool: swiftFormatTool,
      targetDirectories: targetDirectories,
      configurationFilePath: configurationFilePath
    )
  }
}

#if canImport(XcodeProjectPlugin)
import XcodeProjectPlugin

extension FormatPlugin: XcodeCommandPlugin {
  func performCommand(context: XcodeProjectPlugin.XcodePluginContext, arguments: [String]) throws {
    let swiftFormatTool = try context.tool(named: "swift-format")
    
    var argExtractor = ArgumentExtractor(arguments)
    let configurationFilePath = argExtractor.extractOption(named: "configuration").first
    
    try format(
      tool: swiftFormatTool,
      targetDirectories: [context.xcodeProject.directory.string],
      configurationFilePath: configurationFilePath
    )
  }
}
#endif
