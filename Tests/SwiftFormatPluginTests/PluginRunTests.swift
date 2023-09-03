import Foundation
import XCTest

final class PluginRunTests: XCTestCase {

  var workingDirUrl: URL!
  var taskProcess: Process!

  var allOutputTxt: String = ""
  var stdoutTxt: String = ""
  var stderrTxt: String = ""

  override func setUp() {
    setupProject()
    fixCodesigning()
    setupProcess()
  }

  // In a tmp dir, create a SPM project which depends on this project, and build it.
  // Project contains targets: executable, library, test, plugin.
  func setupProject() {

    // currentDirectoryPath: /path/to/swift-format/.build/arm64-apple-macosx/debug
    let swiftFormatProjectDirPath = URL(
      fileURLWithPath: FileManager.default.currentDirectoryPath,
      isDirectory: true
    )
    .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().path

    let packageTxt = """
      // swift-tools-version: 5.9

      import PackageDescription

      let package = Package(
          name: "Swift-Format-Plugin-Test",
          products: [
              .library(
                  name: "LibraryTarget",
                  targets: ["LibraryTarget"]
              ),
              .plugin(
                      name: "PluginTarget",
                      targets: ["PluginTarget"]
              )
          ],
          dependencies: [
              .package(path: "\(swiftFormatProjectDirPath)"),
          ],
          targets: [
              .executableTarget(
                      name: "ExecutableTarget",
                      dependencies: [
                          "LibraryTarget",
                      ],
                      path: "Sources/ExecutableTarget"
              ),
              .target(
                      name: "LibraryTarget",
                      path: "Sources/LibraryTarget"
              ),
              .plugin(
                      name: "PluginTarget",
                      capability: .command(
                              intent: .custom(
                                      verb: "test-plugin",
                                      description: "A test plugin"
                              ),
                              permissions: [
                                      .writeToPackageDirectory(reason: "This command generates files")
                              ]
                      ),
                      dependencies: [
                          "ExecutableTarget"
                      ],
                      path: "Plugins/PluginTarget"
              ),
              .testTarget(
                  name: "TestTarget",
                  dependencies: [
                      "LibraryTarget"
                  ]
              )
          ]
      )
      """

    let tempDirUrl = FileManager.default.temporaryDirectory.appendingPathComponent(
      UUID().uuidString)

    do {
      try FileManager.default.createDirectory(at: tempDirUrl, withIntermediateDirectories: false)

      FileManager.default.createFile(
        atPath: tempDirUrl.appendingPathComponent("package.swift").path,
        contents: packageTxt.data(using: .utf8)
      )

      try FileManager.default.createDirectory(
        at: tempDirUrl.appendingPathComponent("Sources").appendingPathComponent("ExecutableTarget"),
        withIntermediateDirectories: true)
      FileManager.default.createFile(
        atPath: tempDirUrl.appendingPathComponent("Sources").appendingPathComponent(
          "ExecutableTarget"
        ).appendingPathComponent("maain.swift").path,
        contents: "".data(using: .utf8)
      )

      try FileManager.default.createDirectory(
        at: tempDirUrl.appendingPathComponent("Sources").appendingPathComponent("LibraryTarget"),
        withIntermediateDirectories: true)
      FileManager.default.createFile(
        atPath: tempDirUrl.appendingPathComponent("Sources").appendingPathComponent("LibraryTarget")
          .appendingPathComponent("library.swift").path,
        contents: "".data(using: .utf8)
      )

      try FileManager.default.createDirectory(
        at: tempDirUrl.appendingPathComponent("Tests").appendingPathComponent("TestTarget"),
        withIntermediateDirectories: true)
      FileManager.default.createFile(
        atPath: tempDirUrl.appendingPathComponent("Tests").appendingPathComponent("TestTarget")
          .appendingPathComponent("test.swift").path,
        contents: "".data(using: .utf8)
      )

      let pluginTxt = """
        import Foundation
        import PackagePlugin

        @main
        struct TestPlugin: CommandPlugin {
            func performCommand(context: PackagePlugin.PluginContext, arguments: [String]) async throws {
                print("TestPlugin is working.")
            }
        }
        """

      try FileManager.default.createDirectory(
        at: tempDirUrl.appendingPathComponent("Plugins").appendingPathComponent("PluginTarget"),
        withIntermediateDirectories: true)
      FileManager.default.createFile(
        atPath: tempDirUrl.appendingPathComponent("Plugins").appendingPathComponent("PluginTarget")
          .appendingPathComponent("plugin.swift").path,
        contents: pluginTxt.data(using: .utf8)
      )

      setupProcess()
      taskProcess.arguments = [
        "build"
      ]
      try taskProcess.run()
      taskProcess.waitUntilExit()

      XCTAssertTrue(stdoutTxt.contains("Build complete!"))

      workingDirUrl = tempDirUrl
    } catch {
      XCTFail("Error setting up test fixture project at: \(tempDirUrl.path)")
    }
  }

  // Prepare a new NSTask/Process with output recorded to string variables.
  func setupProcess() {

    allOutputTxt = ""
    stdoutTxt = ""
    stderrTxt = ""

    let stdoutHandler = { (file: FileHandle!) -> Void in
      let data = file.availableData

      guard !data.isEmpty, let output = String(data: data, encoding: .utf8), !output.isEmpty
      else {
        return
      }
      self.stdoutTxt += output
      self.allOutputTxt += output
    }
    let stderrHandler = { (file: FileHandle!) -> Void in
      let data = file.availableData
      guard !data.isEmpty, let output = String(data: data, encoding: .utf8), !output.isEmpty
      else {
        return
      }
      self.stderrTxt += output
      self.allOutputTxt += output
    }

    let stdOut = Pipe()
    stdOut.fileHandleForReading.readabilityHandler = stdoutHandler

    let stderr = Pipe()
    stderr.fileHandleForReading.readabilityHandler = stderrHandler

    taskProcess = Process()
    taskProcess.standardOutput = stdOut
    taskProcess.standardError = stderr
    taskProcess.currentDirectoryURL = workingDirUrl

    taskProcess.launchPath = "/usr/bin/swift"
  }

  /**
     @see https://github.com/apple/swift-package-manager/issues/6872
     */
  func fixCodesigning() {
    setupProcess()
    taskProcess.arguments = [
      "package", "plugin", "lint-source-code",
    ]
    try! taskProcess.run()
    taskProcess.waitUntilExit()

    // Do not alter the codesigning if the bug in #6872 is not present.
    if 0 == taskProcess.terminationStatus
      || !allOutputTxt.split(separator: "\n").last!.contains("Build complete!")
    {
      return
    }

    setupProcess()
    taskProcess.launchPath = "/usr/bin/codesign"
    taskProcess.arguments = [
      "-s", "-", workingDirUrl.path + "/.build/plugins/Lint Source Code/cache/Lint_Source_Code",
    ]
    try! taskProcess.run()
    taskProcess.waitUntilExit()

    setupProcess()
    taskProcess.arguments = [
      "package", "plugin", "lint-source-code",
    ]
    try! taskProcess.run()
    taskProcess.waitUntilExit()
  }

  /**
     Confirm the plugin runs without any targets specified.
      `swift package plugin lint-source-code`
      @see https://github.com/apple/swift-format/issues/483
      "error: swift-format invocation failed: NSTaskTerminationReason(rawValue: 1):64"
     */
  public func testPluginRun() {

    let processFinishExpectation = expectation(description: "process timeout")

    taskProcess.arguments = [
      "package", "plugin", "lint-source-code",
    ]
    do {
      taskProcess.terminationHandler = { (process: Process) in
        processFinishExpectation.fulfill()
      }

      try taskProcess.run()

      waitForExpectations(timeout: 30)
    } catch {
      XCTFail(allOutputTxt)
    }

    let errorMessage = "swift-format invocation failed: NSTaskTerminationReason(rawValue: 1):64"
    if stderrTxt.split(separator: "\n").last == "error: \(errorMessage)" {
      XCTFail("\(errorMessage)\nworkingdir: \(workingDirUrl.path)")
    }

    XCTAssertEqual(
      0, Int(taskProcess.terminationStatus), "Non-zero exit code\nworkingdir: \(workingDirUrl.path)"
    )
  }
}
