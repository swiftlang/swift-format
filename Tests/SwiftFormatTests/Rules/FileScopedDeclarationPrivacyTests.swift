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
@_spi(Rules) import SwiftFormat
import SwiftSyntax
import _SwiftFormatTestSupport

private typealias TestConfiguration = (
  original: String,
  desired: FileScopedDeclarationPrivacyConfiguration.AccessLevel,
  expected: String
)

/// Test configurations for file-scoped declarations, which should be changed if the access level
/// does not match the desired level in the formatter configuration.
private let changingTestConfigurations: [TestConfiguration] = [
  (original: "private", desired: .fileprivate, expected: "fileprivate"),
  (original: "private", desired: .private, expected: "private"),
  (original: "fileprivate", desired: .fileprivate, expected: "fileprivate"),
  (original: "fileprivate", desired: .private, expected: "private"),
]

/// Test configurations for declarations that should not have their access level changed; extensions
/// and nested declarations (i.e., not at file scope).
private let unchangingTestConfigurations: [TestConfiguration] = [
  (original: "private", desired: .fileprivate, expected: "private"),
  (original: "private", desired: .private, expected: "private"),
  (original: "fileprivate", desired: .fileprivate, expected: "fileprivate"),
  (original: "fileprivate", desired: .private, expected: "fileprivate"),
]

final class FileScopedDeclarationPrivacyTests: LintOrFormatRuleTestCase {
  func testFileScopeDecls() {
    runWithMultipleConfigurations(
      source: """
        1️⃣$access$ class Foo {}
        2️⃣$access$ struct Foo {}
        3️⃣$access$ enum Foo {}
        4️⃣$access$ protocol Foo {}
        5️⃣$access$ typealias Foo = Bar
        6️⃣$access$ func foo() {}
        7️⃣$access$ var foo: Bar
        """,
      testConfigurations: changingTestConfigurations
    ) { original, expected in
      [
        FindingSpec("1️⃣", message: "replace '\(original)' with '\(expected)' on file-scoped declarations"),
        FindingSpec("2️⃣", message: "replace '\(original)' with '\(expected)' on file-scoped declarations"),
        FindingSpec("3️⃣", message: "replace '\(original)' with '\(expected)' on file-scoped declarations"),
        FindingSpec("4️⃣", message: "replace '\(original)' with '\(expected)' on file-scoped declarations"),
        FindingSpec("5️⃣", message: "replace '\(original)' with '\(expected)' on file-scoped declarations"),
        FindingSpec("6️⃣", message: "replace '\(original)' with '\(expected)' on file-scoped declarations"),
        FindingSpec("7️⃣", message: "replace '\(original)' with '\(expected)' on file-scoped declarations"),
      ]
    }
  }

  func testFileScopeExtensionsAreNotChanged() {
    runWithMultipleConfigurations(
      source: """
        $access$ extension Foo {}
        """,
      testConfigurations: unchangingTestConfigurations
    ) { _, _ in [] }
  }

  func testNonFileScopeDeclsAreNotChanged() {
    runWithMultipleConfigurations(
      source: """
        enum Namespace {
          $access$ class Foo {}
          $access$ struct Foo {}
          $access$ enum Foo {}
          $access$ typealias Foo = Bar
          $access$ func foo() {}
          $access$ var foo: Bar
        }
        """,
      testConfigurations: unchangingTestConfigurations
    ) { _, _ in [] }
  }

  func testFileScopeDeclsInsideConditionals() {
    runWithMultipleConfigurations(
      source: """
        #if FOO
          1️⃣$access$ class Foo {}
        #elseif BAR
          2️⃣$access$ class Foo {}
        #else
          3️⃣$access$ class Foo {}
        #endif
        """,
      testConfigurations: changingTestConfigurations
    ) { original, expected in
      [
        FindingSpec("1️⃣", message: "replace '\(original)' with '\(expected)' on file-scoped declarations"),
        FindingSpec("2️⃣", message: "replace '\(original)' with '\(expected)' on file-scoped declarations"),
        FindingSpec("3️⃣", message: "replace '\(original)' with '\(expected)' on file-scoped declarations"),
      ]
    }
  }

  func testFileScopeDeclsInsideNestedConditionals() {
    runWithMultipleConfigurations(
      source: """
        #if FOO
          #if BAR
            1️⃣$access$ class Foo {}
            2️⃣$access$ struct Foo {}
            3️⃣$access$ enum Foo {}
            4️⃣$access$ protocol Foo {}
            5️⃣$access$ typealias Foo = Bar
            6️⃣$access$ func foo() {}
            7️⃣$access$ var foo: Bar
          #endif
        #endif
        """,
      testConfigurations: changingTestConfigurations
    ) { original, expected in
      [
        FindingSpec("1️⃣", message: "replace '\(original)' with '\(expected)' on file-scoped declarations"),
        FindingSpec("2️⃣", message: "replace '\(original)' with '\(expected)' on file-scoped declarations"),
        FindingSpec("3️⃣", message: "replace '\(original)' with '\(expected)' on file-scoped declarations"),
        FindingSpec("4️⃣", message: "replace '\(original)' with '\(expected)' on file-scoped declarations"),
        FindingSpec("5️⃣", message: "replace '\(original)' with '\(expected)' on file-scoped declarations"),
        FindingSpec("6️⃣", message: "replace '\(original)' with '\(expected)' on file-scoped declarations"),
        FindingSpec("7️⃣", message: "replace '\(original)' with '\(expected)' on file-scoped declarations"),
      ]
    }
  }

  func testLeadingTriviaIsPreserved() {
    runWithMultipleConfigurations(
      source: """
        /// Some doc comment
        1️⃣$access$ class Foo {}

        @objc /* comment */ 2️⃣$access$ class Bar {}
        """,
      testConfigurations: changingTestConfigurations
    ) { original, expected in
      [
        FindingSpec("1️⃣", message: "replace '\(original)' with '\(expected)' on file-scoped declarations"),
        FindingSpec("2️⃣", message: "replace '\(original)' with '\(expected)' on file-scoped declarations"),
      ]
    }
  }

  func testModifierDetailIsPreserved() {
    runWithMultipleConfigurations(
      source: """
        public 1️⃣$access$(set) var foo: Int
        """,
      testConfigurations: changingTestConfigurations
    ) { original, expected in
      [
        FindingSpec("1️⃣", message: "replace '\(original)' with '\(expected)' on file-scoped declarations")
      ]
    }
  }

  /// Runs a test for this rule in multiple configurations.
  private func runWithMultipleConfigurations(
    source: String,
    testConfigurations: [TestConfiguration],
    file: StaticString = #file,
    line: UInt = #line,
    findingsProvider: (String, String) -> [FindingSpec]
  ) {
    for testConfig in testConfigurations {
      var configuration = Configuration.forTesting
      configuration.fileScopedDeclarationPrivacy.accessLevel = testConfig.desired

      let substitutedInput = source.replacingOccurrences(of: "$access$", with: testConfig.original)

      let markedSource = MarkedText(textWithMarkers: source)
      let substitutedExpected = markedSource.textWithoutMarkers.replacingOccurrences(
        of: "$access$",
        with: testConfig.expected
      )

      // Only use the findings if the output was expected to change. If it didn't change, then the
      // rule wouldn't have emitted anything.
      let findingSpecs: [FindingSpec]
      if testConfig.original == testConfig.expected {
        findingSpecs = []
      } else {
        findingSpecs = findingsProvider(testConfig.original, testConfig.expected)
      }

      assertFormatting(
        FileScopedDeclarationPrivacy.self,
        input: substitutedInput,
        expected: substitutedExpected,
        findings: findingSpecs,
        configuration: configuration,
        file: file,
        line: line
      )
    }
  }
}
