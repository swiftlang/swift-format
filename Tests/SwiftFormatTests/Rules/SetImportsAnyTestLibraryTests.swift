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

import Foundation
import SwiftFormat
@_spi(Rules) @_spi(Testing) import SwiftFormat
import SwiftParser
import Testing

@Suite
struct SetImportsAnyTestLibraryTests {
  struct TestCase: CustomTestStringConvertible {
    let id: String
    let source: String
    let expected: Context.AnyTestImportState

    var testDescription: String { id }
  }

  fileprivate static func getImportTestData(library: String) -> [TestCase] {
    [
      TestCase(
        id: "\(library): imports test library",
        source: """
          import Foundation
          import \(library)
          """,
        expected: .importsATestLirary
      ),
      TestCase(
        id: "\(library): imports specific test library declaration",
        source: """
          import Foundation
          import class \(library).SomeOtherType
          """,
        expected: .importsATestLirary
      ),
      TestCase(
        id: "\(library): import test library inside conditional",
        source: """
          import Foundation
          #if SOME_FEATURE_FLAG
            import \(library)
          #endif
          """,
        expected: .importsATestLirary
      ),
      TestCase(
        id: "\(library): import test library inside nested conditional",
        source: """
          import Foundation
          #if SOME_FEATURE_FLAG
            import FooBar
            #if os(macOS)
              import \(library)
            #endif
          #endif
          """,
        expected: .importsATestLirary
      ),
      TestCase(
        id: "\(library): import test library inside elseif conditional",
        source: """
          import Foundation
          #if SOME_FEATURE_FLAG
            import FooBar
          #elsif os(macOS)
              import \(library)
          #endif
          """,
        expected: .importsATestLirary
      ),
      TestCase(
        id: "\(library): import test library inside nested elseif conditional",
        source: """
          import Foundation
          #if SOME_FEATURE_FLAG
            import FooBar
          #elseif os(macOS)
              #if FOO
              #elseif BAR
                import \(library)
              #endif
          #endif
          """,
        expected: .importsATestLirary
      ),

      TestCase(
        id: "\(library): import test library inside else conditional",
        source: """
          import Foundation
          #if SOME_FEATURE_FLAG
            import FooBar
          #else
              import \(library)
          #endif
          """,
        expected: .importsATestLirary
      ),
      TestCase(
        id: "\(library): import test library inside nested else conditional",
        source: """
          import Foundation
          #if SOME_FEATURE_FLAG
            import FooBar
          #else
              #if FOO
              #else BAR
                import \(library)
              #endif
          #endif
          """,
        expected: .importsATestLirary
      ),

    ]
  }

  static let testData = supportedTestLibraryModuleNames.flatMap { Self.getImportTestData(library: $0) }
  static let importsAllTestLibraries = supportedTestLibraryModuleNames.map { "import \($0)" }.joined(separator: "\n")

  @Test(
    arguments: [
      TestCase(
        id: "Does not import a test library",
        source: """
          import Foundation
          """,
        expected: .doesNotImportATestLibrary
      ),
      TestCase(
        id: "imports all supported test libraries",
        source: """
          import Foundation
          """ + Self.importsAllTestLibraries,
        expected: .importsATestLirary
      ),
    ] + testData
  )
  func setImportsAnyTestLibraryReturnsExpectedResult(testCase: TestCase) throws {
    let sourceFile = Parser.parse(source: testCase.source)
    let context = Context(
      configuration: Configuration(),
      operatorTable: .standardOperators,
      findingConsumer: { _ in },
      fileURL: URL(fileURLWithPath: "/tmp/test.swift"),
      sourceFileSyntax: sourceFile,
      ruleNameCache: ruleNameCache
    )

    setImportsAnyTestLibrary(context: context, sourceFile: sourceFile)

    #expect(context.importsAnyTestLibrary == testCase.expected)
  }
}
