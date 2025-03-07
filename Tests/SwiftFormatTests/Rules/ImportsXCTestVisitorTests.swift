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
@_spi(Rules) @_spi(Testing) import SwiftFormat
import SwiftParser
import XCTest

class ImportsXCTestVisitorTests: XCTestCase {
  func testDoesNotImportXCTest() throws {
    XCTAssertEqual(
      try makeContextAndSetImportsXCTest(
        source: """
          import Foundation
          """
      ),
      .doesNotImportXCTest
    )
  }

  func testImportsXCTest() throws {
    XCTAssertEqual(
      try makeContextAndSetImportsXCTest(
        source: """
          import Foundation
          import XCTest
          """
      ),
      .importsXCTest
    )
  }

  func testImportsSpecificXCTestDecl() throws {
    XCTAssertEqual(
      try makeContextAndSetImportsXCTest(
        source: """
          import Foundation
          import class XCTest.XCTestCase
          """
      ),
      .importsXCTest
    )
  }

  func testImportsXCTestInsideConditional() throws {
    XCTAssertEqual(
      try makeContextAndSetImportsXCTest(
        source: """
          import Foundation
          #if SOME_FEATURE_FLAG
            import XCTest
          #endif
          """
      ),
      .importsXCTest
    )
  }

  /// Parses the given source, makes a new `Context`, then populates and returns its `XCTest`
  /// import state.
  private func makeContextAndSetImportsXCTest(source: String) throws -> Context.XCTestImportState {
    let sourceFile = Parser.parse(source: source)
    let context = Context(
      configuration: Configuration(),
      operatorTable: .standardOperators,
      findingConsumer: { _ in },
      fileURL: URL(fileURLWithPath: "/tmp/test.swift"),
      sourceFileSyntax: sourceFile,
      ruleNameCache: ruleNameCache
    )
    setImportsXCTest(context: context, sourceFile: sourceFile)
    return context.importsXCTest
  }
}
