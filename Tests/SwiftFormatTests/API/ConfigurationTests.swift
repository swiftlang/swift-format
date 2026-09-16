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
import SwiftFormat
import XCTest

final class ConfigurationTests: XCTestCase {
  func testDefaultConfigurationIsSameAsEmptyDecode() {
    // Since we don't use the synthesized `init(from: Decoder)` and allow fields
    // to be missing, we provide defaults there as well as in the property
    // declarations themselves. This test ensures that creating a default-
    // initialized `Configuration` is identical to decoding one from an empty
    // JSON input, which verifies that those defaults are always in sync.
    let defaultInitConfig = Configuration()

    let emptyDictionaryData = "{}\n".data(using: .utf8)!
    let jsonDecoder = JSONDecoder()
    #if canImport(Darwin) || compiler(>=6)
    jsonDecoder.allowsJSON5 = true
    #endif
    let emptyJSONConfig =
      try! jsonDecoder.decode(Configuration.self, from: emptyDictionaryData)

    XCTAssertEqual(defaultInitConfig, emptyJSONConfig)
  }

  func testMissingConfigurationFile() throws {
    #if os(Windows)
    #if compiler(<6.0.2)
    try XCTSkipIf(true, "Requires https://github.com/swiftlang/swift-foundation/pull/983")
    #endif
    let path = #"C:\test.swift"#
    #else
    let path = "/test.swift"
    #endif
    XCTAssertNil(Configuration.url(forConfigurationFileApplyingTo: URL(fileURLWithPath: path)))
  }

  func testMissingConfigurationFileInSubdirectory() throws {
    #if os(Windows)
    #if compiler(<6.0.2)
    try XCTSkipIf(true, "Requires https://github.com/swiftlang/swift-foundation/pull/983")
    #endif
    let path = #"C:\whatever\test.swift"#
    #else
    let path = "/whatever/test.swift"
    #endif
    XCTAssertNil(Configuration.url(forConfigurationFileApplyingTo: URL(fileURLWithPath: path)))
  }

  func testMissingConfigurationFileMountedDirectory() throws {
    #if os(Windows)
    #if compiler(<6.0.2)
    try XCTSkipIf(true, "Requires https://github.com/swiftlang/swift-foundation/pull/983")
    #endif
    #else
    try XCTSkipIf(true, #"\\ file mounts are only a concept on Windows"#)
    #endif
    let path = #"\\mount\test.swift"#
    XCTAssertNil(Configuration.url(forConfigurationFileApplyingTo: URL(fileURLWithPath: path)))
  }

  func testDecodingReflowMultilineStringLiteralsAsString() throws {
    let testCases: [String: Configuration.MultilineStringReflowBehavior] = [
      "never": .never,
      "always": .always,
      "onlyLinesOverLength": .onlyLinesOverLength,
    ]

    for (jsonString, expectedBehavior) in testCases {
      let jsonData = """
        {
            "reflowMultilineStringLiterals": "\(jsonString)"
        }
        """.data(using: .utf8)!

      let jsonDecoder = JSONDecoder()
      #if canImport(Darwin) || compiler(>=6)
      jsonDecoder.allowsJSON5 = true
      #endif
      let config = try jsonDecoder.decode(Configuration.self, from: jsonData)
      XCTAssertEqual(config.reflowMultilineStringLiterals, expectedBehavior)
    }
  }

  func testDecodingReflowMultilineStringLiteralsAsObject() throws {

    let testCases: [String: Configuration.MultilineStringReflowBehavior] = [
      "{ \"never\": {} }": .never,
      "{ \"always\": {} }": .always,
      "{ \"onlyLinesOverLength\": {} }": .onlyLinesOverLength,
    ]

    for (jsonString, expectedBehavior) in testCases {
      let jsonData = """
        {
            "reflowMultilineStringLiterals": \(jsonString)
        }
        """.data(using: .utf8)!

      let jsonDecoder = JSONDecoder()
      #if canImport(Darwin) || compiler(>=6)
      jsonDecoder.allowsJSON5 = true
      #endif
      let config = try jsonDecoder.decode(Configuration.self, from: jsonData)
      XCTAssertEqual(config.reflowMultilineStringLiterals, expectedBehavior)
    }
  }

  func testConfigurationWithComments() throws {
    #if !canImport(Darwin) && compiler(<6)
    try XCTSkipIf(true, "JSONDecoder does not support JSON5")
    #else
    let expected = Configuration()

    let jsonData = """
      {
          // Indicates the configuration schema version.
          "version": 1,
      }
      """.data(using: .utf8)!

    let jsonDecoder = JSONDecoder()

    jsonDecoder.allowsJSON5 = true
    let config = try jsonDecoder.decode(Configuration.self, from: jsonData)
    XCTAssertEqual(config, expected)
    #endif
  }

  func testDecodingFileScopedDeclarationPrivacyConfiguration() throws {
    let testCases: [String: FileScopedDeclarationPrivacyConfiguration.AccessLevel] = [
      "{ }": .private,
      "{ \"accessLevel\": \"private\" }": .private,
      "{ \"accessLevel\": \"fileprivate\" }": .fileprivate,
    ]

    for (jsonString, expectedAccessLevel) in testCases {
      let jsonData = """
        {
          "fileScopedDeclarationPrivacy": \(jsonString)
        }
        """.data(using: .utf8)!

      let jsonDecoder = JSONDecoder()
      #if canImport(Darwin) || compiler(>=6)
      jsonDecoder.allowsJSON5 = true
      #endif
      let config = try jsonDecoder.decode(Configuration.self, from: jsonData)
      XCTAssertEqual(config.fileScopedDeclarationPrivacy.accessLevel, expectedAccessLevel)
    }
  }

  func testDecodingNoAssignmentInExpressionsConfiguration() throws {
    let testCases: [String: [String]] = [
      "{ }": ["XCTAssertNoThrow"],
      "{ \"allowedFunctions\": [] }": [],
      "{ \"allowedFunctions\": [\"XCTAssertNoThrow\"] }": ["XCTAssertNoThrow"],
      "{ \"allowedFunctions\": [\"XCTAssertNoThrow\", \"Gday\"] }": ["XCTAssertNoThrow", "Gday"],
    ]

    for (jsonString, expectedAllowedFunctions) in testCases {
      let jsonData = """
        {
          "noAssignmentInExpressions": \(jsonString)
        }
        """.data(using: .utf8)!

      let jsonDecoder = JSONDecoder()
      #if canImport(Darwin) || compiler(>=6)
      jsonDecoder.allowsJSON5 = true
      #endif
      let config = try jsonDecoder.decode(Configuration.self, from: jsonData)
      XCTAssertEqual(config.noAssignmentInExpressions.allowedFunctions, expectedAllowedFunctions)
    }
  }

  func testDecodingOrderedImportsConfiguration() throws {
    typealias ExpectedValues = (includeConditionalImports: Bool, shouldGroupImports: Bool)
    let testCases: [String: ExpectedValues] = [
      "{ }": (false, true),
      "{ \"includeConditionalImports\": false }": (false, true),
      "{ \"includeConditionalImports\": true }": (true, true),
      "{ \"shouldGroupImports\": false }": (false, false),
      "{ \"shouldGroupImports\": true }": (false, true),
      "{ \"includeConditionalImports\": false, \"shouldGroupImports\": false }": (false, false),
      "{ \"includeConditionalImports\": true, \"shouldGroupImports\": true }": (true, true),
    ]

    for (jsonString, expectedValues) in testCases {
      let jsonData = """
        {
          "orderedImports": \(jsonString)
        }
        """.data(using: .utf8)!

      let jsonDecoder = JSONDecoder()
      #if canImport(Darwin) || compiler(>=6)
      jsonDecoder.allowsJSON5 = true
      #endif
      let config = try jsonDecoder.decode(Configuration.self, from: jsonData)
      XCTAssertEqual(config.orderedImports.includeConditionalImports, expectedValues.includeConditionalImports)
      XCTAssertEqual(config.orderedImports.shouldGroupImports, expectedValues.shouldGroupImports)
    }
  }

  func testDecodingSwiftTestingNamingConventionsConfiguration() throws {
    typealias ExpectedValues = (
      forbidSuiteWithoutParameters: Bool,
      forbidSuiteDescription: Bool,
      forbidTestDescription: Bool,
      requireRawIdentifierTestNames: Bool
    )

    let testCases: [String: ExpectedValues] = [
      "{ }": (false, false, false, false),
      "{ \"forbidSuiteWithoutParameters\": false }": (false, false, false, false),
      "{ \"forbidSuiteWithoutParameters\": true }": (true, false, false, false),
      "{ \"forbidSuiteDescription\": false }": (false, false, false, false),
      "{ \"forbidSuiteDescription\": true }": (false, true, false, false),
      "{ \"forbidTestDescription\": false }": (false, false, false, false),
      "{ \"forbidTestDescription\": true }": (false, false, true, false),
      "{ \"requireRawIdentifierTestNames\": false }": (false, false, false, false),
      "{ \"requireRawIdentifierTestNames\": true }": (false, false, false, true),
      """
      {
        \"forbidSuiteWithoutParameters\": false,
        \"forbidSuiteDescription\": false,
        \"forbidTestDescription\": false,
        \"requireRawIdentifierTestNames\": false
      }
      """: (false, false, false, false),
      """
      {
        \"forbidSuiteWithoutParameters\": true,
        \"forbidSuiteDescription\": true,
        \"forbidTestDescription\": true,
        \"requireRawIdentifierTestNames\": true
      }
      """: (true, true, true, true),
    ]

    for (jsonString, expectedValues) in testCases {
      let jsonData = """
        {
          "swiftTestingNamingConventions": \(jsonString)
        }
        """.data(using: .utf8)!

      let jsonDecoder = JSONDecoder()
      #if canImport(Darwin) || compiler(>=6)
      jsonDecoder.allowsJSON5 = true
      #endif
      let config = try jsonDecoder.decode(Configuration.self, from: jsonData)
      XCTAssertEqual(
        config.swiftTestingNamingConventions.forbidSuiteWithoutParameters,
        expectedValues.forbidSuiteWithoutParameters
      )
      XCTAssertEqual(
        config.swiftTestingNamingConventions.forbidSuiteDescription,
        expectedValues.forbidSuiteDescription
      )
      XCTAssertEqual(
        config.swiftTestingNamingConventions.forbidTestDescription,
        expectedValues.forbidTestDescription
      )
      XCTAssertEqual(
        config.swiftTestingNamingConventions.requireRawIdentifierTestNames,
        expectedValues.requireRawIdentifierTestNames
      )
    }
  }
}
