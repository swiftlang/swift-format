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

var products: [Product] = [
  .executable(
    name: "swift-format",
    targets: ["swift-format"]
  ),
  .library(
    name: "SwiftFormat",
    targets: ["SwiftFormat"]
  ),
  .plugin(
    name: "FormatPlugin",
    targets: ["Format Source Code"]
  ),
  .plugin(
    name: "LintPlugin",
    targets: ["Lint Source Code"]
  ),
]

var targets: [Target] = [
  .target(
    name: "_SwiftFormatInstructionCounter",
    exclude: ["CMakeLists.txt"]
  ),

  .target(
    name: "SwiftFormat",
    dependencies: [
      .product(name: "Markdown", package: "swift-markdown")
    ]
      + swiftSyntaxDependencies([
        "SwiftOperators", "SwiftParser", "SwiftParserDiagnostics", "SwiftSyntax", "SwiftSyntaxBuilder",
      ]),
    exclude: ["CMakeLists.txt"]
  ),
  .target(
    name: "_SwiftFormatTestSupport",
    dependencies: [
      "SwiftFormat"
    ]
      + swiftSyntaxDependencies([
        "SwiftOperators", "SwiftParser", "SwiftParserDiagnostics", "SwiftSyntax", "SwiftSyntaxBuilder",
      ])
  ),
  .plugin(
    name: "Format Source Code",
    capability: .command(
      intent: .sourceCodeFormatting(),
      permissions: [
        .writeToPackageDirectory(reason: "This command formats the Swift source files")
      ]
    ),
    dependencies: [
      .target(name: "swift-format")
    ],
    path: "Plugins/FormatPlugin"
  ),
  .plugin(
    name: "Lint Source Code",
    capability: .command(
      intent: .custom(
        verb: "lint-source-code",
        description: "Lint source code for a specified target."
      )
    ),
    dependencies: [
      .target(name: "swift-format")
    ],
    path: "Plugins/LintPlugin"
  ),
  .executableTarget(
    name: "generate-swift-format",
    dependencies: [
      "SwiftFormat"
    ]
  ),
  .executableTarget(
    name: "swift-format",
    dependencies: [
      "_SwiftFormatInstructionCounter",
      "SwiftFormat",
      .product(name: "ArgumentParser", package: "swift-argument-parser"),
    ] + swiftSyntaxDependencies(["SwiftParser", "SwiftSyntax"]),
    exclude: ["CMakeLists.txt"],
    linkerSettings: swiftformatLinkSettings
  ),

  .testTarget(
    name: "SwiftFormatPerformanceTests",
    dependencies: [
      "SwiftFormat",
      "_SwiftFormatTestSupport",
    ] + swiftSyntaxDependencies(["SwiftParser", "SwiftSyntax"])
  ),
  .testTarget(
    name: "SwiftFormatTests",
    dependencies: [
      "SwiftFormat",
      "_SwiftFormatTestSupport",
      .product(name: "Markdown", package: "swift-markdown"),
    ] + swiftSyntaxDependencies(["SwiftOperators", "SwiftParser", "SwiftSyntax", "SwiftSyntaxBuilder"])
  ),
]

if buildOnlyTests {
  products = []
  targets = targets.compactMap { target in
    guard target.isTest || target.name == "_SwiftFormatTestSupport" else {
      return nil
    }
    target.dependencies = target.dependencies.filter { dependency in
      if case .byNameItem(name: "_SwiftFormatTestSupport", _) = dependency {
        return true
      }
      return false
    }
    return target
  }
}

let package = Package(
  name: "swift-format",
  platforms: [
    .macOS("12.0"),
    .iOS("13.0"),
  ],
  products: products,
  dependencies: dependencies,
  targets: targets
)

func swiftSyntaxDependencies(_ names: [String]) -> [Target.Dependency] {
  if buildDynamicSwiftSyntaxLibrary {
    return [.product(name: "_SwiftSyntaxDynamic", package: "swift-syntax")]
  } else {
    return names.map { .product(name: $0, package: "swift-syntax") }
  }
}

// MARK: - Parse build arguments

func hasEnvironmentVariable(_ name: String) -> Bool {
  return ProcessInfo.processInfo.environment[name] != nil
}

// When building the toolchain on the CI, don't add the CI's runpath for the
// final build before installing.
var installAction: Bool { hasEnvironmentVariable("SWIFTFORMAT_CI_INSTALL") }

/// Assume that all the package dependencies are checked out next to sourcekit-lsp and use that instead of fetching a
/// remote dependency.
var useLocalDependencies: Bool { hasEnvironmentVariable("SWIFTCI_USE_LOCAL_DEPS") }

/// Build only tests targets and test support modules.
///
/// This is used to test swift-format on Windows, where the modules required for the `swift-format` executable are
/// built using CMake. When using this setting, the caller is responsible for passing the required search paths to
/// the `swift test` invocation so that all pre-built modules can be found.
var buildOnlyTests: Bool { hasEnvironmentVariable("SWIFTFORMAT_BUILD_ONLY_TESTS") }

/// Whether swift-syntax is being built as a single dynamic library instead of as a separate library per module.
///
/// This means that the swift-syntax symbols don't need to be statically linked, which alles us to stay below the
/// maximum number of exported symbols on Windows, in turn allowing us to build sourcekit-lsp using SwiftPM on Windows
/// and run its tests.
var buildDynamicSwiftSyntaxLibrary: Bool {
  hasEnvironmentVariable("SWIFTSYNTAX_BUILD_DYNAMIC_LIBRARY")
}

// MARK: - Dependencies

var dependencies: [Package.Dependency] {
  if buildOnlyTests {
    return []
  } else if useLocalDependencies {
    return [
      .package(path: "../swift-argument-parser"),
      .package(path: "../swift-markdown"),
      .package(path: "../swift-syntax"),
    ]
  } else {
    return [
      .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.2.2"),
      .package(url: "https://github.com/apple/swift-markdown.git", from: "0.2.0"),
      .package(url: "https://github.com/swiftlang/swift-syntax.git", from: "601.0.0-prerelease-2024-11-18"),
    ]
  }
}

// MARK: - Compute custom build settings

var swiftformatLinkSettings: [LinkerSetting] {
  if installAction {
    return [.unsafeFlags(["-no-toolchain-stdlib-rpath"], .when(platforms: [.linux, .android]))]
  } else {
    return []
  }
}
