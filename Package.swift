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
      dependencies: ["SwiftFormatCore", "SwiftFormatConfiguration"]
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
      ]
    ),
    .testTarget(
      name: "SwiftFormatTests",
      dependencies: [
        "SwiftFormat",
      ]
    ),
    .testTarget(
      name: "SwiftFormatConfigurationTests",
      dependencies: ["SwiftFormatConfiguration"]
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
      ]
    ),
    .testTarget(
      name: "SwiftFormatCoreTests",
      dependencies: [
        "SwiftFormatConfiguration",
        "SwiftFormatCore",
        "SwiftSyntax",
      ]
    ),
    .testTarget(
      name: "SwiftFormatPerformanceTests",
      dependencies: [
        "SwiftFormatTestSupport",
        "SwiftFormatWhitespaceLinter",
        "SwiftSyntax",
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
      ]
    ),
  ]
)


if ProcessInfo.processInfo.environment["SWIFTCI_USE_LOCAL_DEPS"] == nil {
  // Building standalone.
  package.dependencies += [
    .package(url: "https://github.com/apple/swift-syntax", .upToNextMinor(from: "0.50400.0")),
    .package(url: "https://github.com/apple/swift-argument-parser.git", .upToNextMinor(from: "0.4.3")),
  ]
} else {
  package.dependencies += [
    .package(path: "../swift-syntax"),
    .package(path: "../swift-argument-parser"),
  ]
}
