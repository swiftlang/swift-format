// swift-tools-version:5.6
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
import PackageDescription

// FIXME: The `generate-pipeline-plugin` doesn't appear to be executing correctly during the build
// on Windows. To work around this for the time being, we check in the generated files and don't
// run the plugin there, but continue to run the plugin on other platforms and exclue the generated
// files from the build.
#if os(Windows)
  let swiftFormatExclusions: [String] = []
  let swiftFormatConfigurationExclusions: [String] = []
  let swiftFormatRulesExclusions: [String] = []
  let pluginsToRun: [Target.PluginUsage] = []
#else
  let swiftFormatExclusions: [String] = ["Pipelines+Generated.swift"]
  let swiftFormatConfigurationExclusions: [String] = ["RuleRegistry+Generated.swift"]
  let swiftFormatRulesExclusions: [String] = ["RuleNameCache+Generated.swift"]
  let pluginsToRun: [Target.PluginUsage] = ["generate-pipeline-plugin"]
#endif

let package = Package(
  name: "swift-format",
  platforms: [
    .macOS("10.15")
  ],
  products: [
    .executable(
      name: "swift-format",
      targets: ["swift-format"]
    ),
    .library(
      name: "SwiftFormat",
      targets: ["SwiftFormat", "SwiftFormatConfiguration"]
    ),
    .library(
      name: "SwiftFormatConfiguration",
      targets: ["SwiftFormatConfiguration"]
    ),
  ],
  dependencies: [
    // See the "Dependencies" section below.
  ],
  targets: [
    .target(
      name: "SwiftFormat",
      dependencies: [
        "SwiftFormatConfiguration",
        "SwiftFormatCore",
        "SwiftFormatPrettyPrint",
        "SwiftFormatRules",
        "SwiftFormatWhitespaceLinter",
        .product(name: "SwiftSyntax", package: "swift-syntax"),
        .product(name: "SwiftOperators", package: "swift-syntax"),
        .product(name: "SwiftParser", package: "swift-syntax"),
      ],
      exclude: swiftFormatExclusions,
      plugins: pluginsToRun
    ),
    .target(
      name: "SwiftFormatConfiguration",
      exclude: swiftFormatConfigurationExclusions,
      plugins: pluginsToRun
    ),
    .target(
      name: "SwiftFormatCore",
      dependencies: [
        "SwiftFormatConfiguration",
        .product(name: "SwiftOperators", package: "swift-syntax"),
        .product(name: "SwiftSyntax", package: "swift-syntax"),
      ]
    ),
    .target(
      name: "SwiftFormatRules",
      dependencies: ["SwiftFormatCore", "SwiftFormatConfiguration"],
      exclude: swiftFormatRulesExclusions,
      plugins: pluginsToRun
    ),
    .target(
      name: "SwiftFormatPrettyPrint",
      dependencies: [
        "SwiftFormatCore",
        "SwiftFormatConfiguration",
        .product(name: "SwiftOperators", package: "swift-syntax"),
      ]
    ),
    .target(
      name: "SwiftFormatTestSupport",
      dependencies: [
        "SwiftFormatCore",
        "SwiftFormatRules",
        "SwiftFormatConfiguration",
        .product(name: "SwiftOperators", package: "swift-syntax"),
      ]
    ),
    .target(
      name: "SwiftFormatWhitespaceLinter",
      dependencies: [
        "SwiftFormatCore",
        .product(name: "SwiftSyntax", package: "swift-syntax"),
      ]
    ),

    .plugin(
      name: "generate-pipeline-plugin",
      capability: .buildTool(),
      dependencies: [
        "generate-pipeline"
      ]
    ),
    .executableTarget(
      name: "generate-pipeline",
      dependencies: [
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
        .product(name: "SwiftSyntax", package: "swift-syntax"),
        .product(name: "SwiftParser", package: "swift-syntax"),
      ]
    ),

    .executableTarget(
      name: "swift-format",
      dependencies: [
        "SwiftFormat",
        "SwiftFormatConfiguration",
        "SwiftFormatCore",
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
        .product(name: "SwiftSyntax", package: "swift-syntax"),
        .product(name: "SwiftParser", package: "swift-syntax"),
        .product(name: "TSCBasic", package: "swift-tools-support-core"),
      ]
    ),

    .testTarget(
      name: "SwiftFormatTests",
      dependencies: [
        "SwiftFormat",
        .product(name: "SwiftSyntax", package: "swift-syntax"),
        .product(name: "SwiftParser", package: "swift-syntax"),
      ]
    ),
    .testTarget(
      name: "SwiftFormatConfigurationTests",
      dependencies: ["SwiftFormatConfiguration"]
    ),
    .testTarget(
      name: "SwiftFormatCoreTests",
      dependencies: [
        "SwiftFormatConfiguration",
        "SwiftFormatCore",
        .product(name: "SwiftSyntax", package: "swift-syntax"),
        .product(name: "SwiftParser", package: "swift-syntax"),
      ]
    ),
    .testTarget(
      name: "SwiftFormatPerformanceTests",
      dependencies: [
        "SwiftFormatTestSupport",
        "SwiftFormatWhitespaceLinter",
        .product(name: "SwiftSyntax", package: "swift-syntax"),
        .product(name: "SwiftParser", package: "swift-syntax"),
      ]
    ),
    .testTarget(
      name: "SwiftFormatPrettyPrintTests",
      dependencies: [
        "SwiftFormatConfiguration",
        "SwiftFormatCore",
        "SwiftFormatPrettyPrint",
        "SwiftFormatRules",
        "SwiftFormatTestSupport",
        .product(name: "SwiftSyntax", package: "swift-syntax"),
        .product(name: "SwiftOperators", package: "swift-syntax"),
        .product(name: "SwiftParser", package: "swift-syntax"),
      ]
    ),
    .testTarget(
      name: "SwiftFormatRulesTests",
      dependencies: [
        "SwiftFormatConfiguration",
        "SwiftFormatCore",
        "SwiftFormatPrettyPrint",
        "SwiftFormatRules",
        "SwiftFormatTestSupport",
        .product(name: "SwiftSyntax", package: "swift-syntax"),
        .product(name: "SwiftParser", package: "swift-syntax"),
      ]
    ),
    .testTarget(
      name: "SwiftFormatWhitespaceLinterTests",
      dependencies: [
        "SwiftFormatConfiguration",
        "SwiftFormatCore",
        "SwiftFormatTestSupport",
        "SwiftFormatWhitespaceLinter",
        .product(name: "SwiftSyntax", package: "swift-syntax"),
        .product(name: "SwiftParser", package: "swift-syntax"),
      ]
    ),
  ]
)

// MARK: Dependencies

if ProcessInfo.processInfo.environment["SWIFTCI_USE_LOCAL_DEPS"] == nil {
  // Building standalone.
  package.dependencies += [
    .package(
      url: "https://github.com/apple/swift-argument-parser.git",
      branch: "main"
    ),
    .package(
      url: "https://github.com/apple/swift-syntax.git",
      branch: "main"
    ),
    .package(
      url: "https://github.com/apple/swift-tools-support-core.git",
      branch: "main"
    ),
  ]
} else {
  package.dependencies += [
    .package(path: "../swift-argument-parser"),
    .package(path: "../swift-syntax"),
    .package(path: "../swift-tools-support-core"),
  ]
}
