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

let package = Package(
  name: "swift-format",
  platforms: [
    .iOS("13.0"),
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
    .plugin(
      name: "FormatPlugin",
      targets: ["Format Source Code"]
    ),
    .plugin(
      name: "LintPlugin",
      targets: ["Lint Source Code"]
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
        .product(name: "Markdown", package: "swift-markdown"),
        .product(name: "SwiftSyntax", package: "swift-syntax"),
        .product(name: "SwiftOperators", package: "swift-syntax"),
        .product(name: "SwiftParser", package: "swift-syntax"),
        .product(name: "SwiftParserDiagnostics", package: "swift-syntax"),
      ]
    ),
    .target(
      name: "SwiftFormatConfiguration"
    ),
    .target(
      name: "_SwiftFormatTestSupport",
      dependencies: [
        "SwiftFormat",
        "SwiftFormatConfiguration",
        .product(name: "SwiftOperators", package: "swift-syntax"),
      ]
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
      name: "generate-pipeline",
      dependencies: [
        "SwiftFormat",
        .product(name: "SwiftSyntax", package: "swift-syntax"),
        .product(name: "SwiftParser", package: "swift-syntax"),
      ]
    ),
    .executableTarget(
      name: "swift-format",
      dependencies: [
        "SwiftFormat",
        "SwiftFormatConfiguration",
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
        .product(name: "SwiftSyntax", package: "swift-syntax"),
        .product(name: "SwiftParser", package: "swift-syntax"),
      ]
    ),

    .testTarget(
      name: "SwiftFormatConfigurationTests",
      dependencies: ["SwiftFormatConfiguration"]
    ),
    .testTarget(
      name: "SwiftFormatPerformanceTests",
      dependencies: [
        "SwiftFormat",
        "_SwiftFormatTestSupport",
        .product(name: "SwiftSyntax", package: "swift-syntax"),
        .product(name: "SwiftParser", package: "swift-syntax"),
      ]
    ),
    .testTarget(
      name: "SwiftFormatTests",
      dependencies: [
        "SwiftFormat",
        "SwiftFormatConfiguration",
        "_SwiftFormatTestSupport",
        .product(name: "Markdown", package: "swift-markdown"),
        .product(name: "SwiftOperators", package: "swift-syntax"),
        .product(name: "SwiftParser", package: "swift-syntax"),
        .product(name: "SwiftSyntax", package: "swift-syntax"),
        .product(name: "SwiftSyntaxBuilder", package: "swift-syntax"),
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
      from: "1.2.2"
    ),
    .package(
      url: "https://github.com/apple/swift-markdown.git",
      from: "0.2.0"
    ),
    .package(
      url: "https://github.com/apple/swift-syntax.git",
      branch: "release/5.9"
    ),
  ]
} else {
  package.dependencies += [
    .package(path: "../swift-argument-parser"),
    .package(path: "../swift-markdown"),
    .package(path: "../swift-syntax"),
  ]
}
