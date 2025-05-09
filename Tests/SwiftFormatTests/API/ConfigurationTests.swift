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
}
