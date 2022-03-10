// swift-tools-version:5.1
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

import PackageDescription
import Foundation

let package = Package(
  name: "swift-format",
  platforms: [
    .macOS(.v10_11)
  ],
  products: [
    .executable(name: "swift-format", targets: ["swift-format"]),
    .library(name: "SwiftFormat", targets: ["SwiftFormat", "SwiftFormatConfiguration"]),
    .library(name: "SwiftFormatConfiguration", targets: ["SwiftFormatConfiguration"]),
  ],
  dependencies: [
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
        "SwiftSyntax",
        "SwiftSyntaxParser",
      ]
    ),
    .target(name: "SwiftFormatConfiguration"),
    .target(name: "SwiftFormatCore", dependencies: ["SwiftFormatConfiguration", "SwiftSyntax"]),
    .target(
      name: "SwiftFormatRules",
      dependencies: ["SwiftFormatCore", "SwiftFormatConfiguration"]
    ),
    .target(
      name: "SwiftFormatPrettyPrint",
      dependencies: ["SwiftFormatCore", "SwiftFormatConfiguration"]
    ),
    .target(
      name: "SwiftFormatTestSupport",
      dependencies: [
        "SwiftFormatCore",
        "SwiftFormatRules",
        "SwiftFormatConfiguration",
      ]
    ),
    .target(
      name: "SwiftFormatWhitespaceLinter",
      dependencies: [
        "SwiftFormatCore",
        "SwiftSyntax",
      ]
    ),
    .target(
      name: "generate-pipeline",
      dependencies: [
        "SwiftFormatCore",
        "SwiftFormatRules",
        "SwiftSyntax",
        "SwiftSyntaxParser",
      ]
    ),
    .target(
      name: "swift-format",
      dependencies: [
        "ArgumentParser",
        "SwiftFormat",
        "SwiftFormatConfiguration",
        "SwiftFormatCore",
        "SwiftSyntax",
        "TSCBasic",
      ]
    ),
    .testTarget(
      name: "SwiftFormatTests",
      dependencies: [
        "SwiftFormat",
        "SwiftSyntax",
        "SwiftSyntaxParser",
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
        "SwiftSyntax",
        "SwiftSyntaxParser",
      ]
    ),
    .testTarget(
      name: "SwiftFormatPerformanceTests",
      dependencies: [
        "SwiftFormatTestSupport",
        "SwiftFormatWhitespaceLinter",
        "SwiftSyntax",
        "SwiftSyntaxParser",
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
        "SwiftSyntax",
        "SwiftSyntaxParser",
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
        "SwiftSyntax",
        "SwiftSyntaxParser",
      ]
    ),
    .testTarget(
      name: "SwiftFormatWhitespaceLinterTests",
      dependencies: [
        "SwiftFormatConfiguration",
        "SwiftFormatCore",
        "SwiftFormatTestSupport",
        "SwiftFormatWhitespaceLinter",
        "SwiftSyntax",
        "SwiftSyntaxParser",
      ]
    ),
  ]
)


if ProcessInfo.processInfo.environment["SWIFTCI_USE_LOCAL_DEPS"] == nil {
  // Building standalone.
  package.dependencies += [
    .package(url: "https://github.com/apple/swift-argument-parser.git", .upToNextMinor(from: "1.0.3")),
    .package(url: "https://github.com/apple/swift-syntax", .branch("release/5.6")),
    .package(url: "https://github.com/apple/swift-tools-support-core.git", .upToNextMinor(from: "0.2.5")),
  ]
} else {
  package.dependencies += [
    .package(path: "../swift-argument-parser"),
    .package(path: "../swift-syntax"),
    .package(path: "../swift-tools-support-core"),
  ]
}
