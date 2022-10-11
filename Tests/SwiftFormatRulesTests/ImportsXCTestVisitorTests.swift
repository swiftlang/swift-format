import SwiftFormatCore
import SwiftFormatRules
import SwiftFormatTestSupport
import SwiftParser
import XCTest

class ImportsXCTestVisitorTests: DiagnosingTestCase {
  func testDoesNotImportXCTest() throws {
    XCTAssertEqual(
      try makeContextAndSetImportsXCTest(source: """
        import Foundation
        """),
      .doesNotImportXCTest
    )
  }

  func testImportsXCTest() throws {
    XCTAssertEqual(
      try makeContextAndSetImportsXCTest(source: """
        import Foundation
        import XCTest
        """),
      .importsXCTest
    )
  }

  func testImportsSpecificXCTestDecl() throws {
    XCTAssertEqual(
      try makeContextAndSetImportsXCTest(source: """
        import Foundation
        import class XCTest.XCTestCase
        """),
      .importsXCTest
    )
  }

  func testImportsXCTestInsideConditional() throws {
    XCTAssertEqual(
      try makeContextAndSetImportsXCTest(source: """
        import Foundation
        #if SOME_FEATURE_FLAG
          import XCTest
        #endif
        """),
      .importsXCTest
    )
  }

  /// Parses the given source, makes a new `Context`, then populates and returns its `XCTest`
  /// import state.
  private func makeContextAndSetImportsXCTest(source: String) throws -> Context.XCTestImportState {
    let sourceFile = try Parser.parse(source: source)
    let context = makeContext(sourceFileSyntax: sourceFile)
    setImportsXCTest(context: context, sourceFile: sourceFile)
    return context.importsXCTest
  }
}
