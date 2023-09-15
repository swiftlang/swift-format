import SwiftFormatConfiguration
import SwiftFormatCore
import SwiftFormatRules
import SwiftSyntax

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
        $access$ class Foo {}
        $access$ struct Foo {}
        $access$ enum Foo {}
        $access$ protocol Foo {}
        $access$ typealias Foo = Bar
        $access$ func foo() {}
        $access$ var foo: Bar
        """,
      testConfigurations: changingTestConfigurations
    ) { assertDiagnosticWasEmittedOrNot in
      assertDiagnosticWasEmittedOrNot(1, 1)
      assertDiagnosticWasEmittedOrNot(2, 1)
      assertDiagnosticWasEmittedOrNot(3, 1)
      assertDiagnosticWasEmittedOrNot(4, 1)
      assertDiagnosticWasEmittedOrNot(5, 1)
      assertDiagnosticWasEmittedOrNot(6, 1)
      assertDiagnosticWasEmittedOrNot(7, 1)
    }
  }

  func testFileScopeExtensionsAreNotChanged() {
    runWithMultipleConfigurations(
      source: """
        $access$ extension Foo {}
        """,
      testConfigurations: unchangingTestConfigurations
    ) { assertDiagnosticWasEmittedOrNot in
      assertDiagnosticWasEmittedOrNot(1, 1)
    }
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
    ) { assertDiagnosticWasEmittedOrNot in
      assertDiagnosticWasEmittedOrNot(1, 1)
      assertDiagnosticWasEmittedOrNot(2, 1)
      assertDiagnosticWasEmittedOrNot(3, 1)
      assertDiagnosticWasEmittedOrNot(4, 1)
      assertDiagnosticWasEmittedOrNot(5, 1)
      assertDiagnosticWasEmittedOrNot(6, 1)
      assertDiagnosticWasEmittedOrNot(7, 1)
    }
  }

  func testFileScopeDeclsInsideConditionals() {
    runWithMultipleConfigurations(
      source: """
        #if FOO
          $access$ class Foo {}
          $access$ struct Foo {}
          $access$ enum Foo {}
          $access$ protocol Foo {}
          $access$ typealias Foo = Bar
          $access$ func foo() {}
          $access$ var foo: Bar
        #elseif BAR
          $access$ class Foo {}
          $access$ struct Foo {}
          $access$ enum Foo {}
          $access$ protocol Foo {}
          $access$ typealias Foo = Bar
          $access$ func foo() {}
          $access$ var foo: Bar
        #else
          $access$ class Foo {}
          $access$ struct Foo {}
          $access$ enum Foo {}
          $access$ protocol Foo {}
          $access$ typealias Foo = Bar
          $access$ func foo() {}
          $access$ var foo: Bar
        #endif
        """,
      testConfigurations: changingTestConfigurations
    ) { assertDiagnosticWasEmittedOrNot in
      assertDiagnosticWasEmittedOrNot(2, 3)
      assertDiagnosticWasEmittedOrNot(3, 3)
      assertDiagnosticWasEmittedOrNot(4, 3)
      assertDiagnosticWasEmittedOrNot(5, 3)
      assertDiagnosticWasEmittedOrNot(6, 3)
      assertDiagnosticWasEmittedOrNot(7, 3)
      assertDiagnosticWasEmittedOrNot(8, 3)
      assertDiagnosticWasEmittedOrNot(10, 3)
      assertDiagnosticWasEmittedOrNot(11, 3)
      assertDiagnosticWasEmittedOrNot(12, 3)
      assertDiagnosticWasEmittedOrNot(13, 3)
      assertDiagnosticWasEmittedOrNot(14, 3)
      assertDiagnosticWasEmittedOrNot(15, 3)
      assertDiagnosticWasEmittedOrNot(16, 3)
      assertDiagnosticWasEmittedOrNot(18, 3)
      assertDiagnosticWasEmittedOrNot(19, 3)
      assertDiagnosticWasEmittedOrNot(20, 3)
      assertDiagnosticWasEmittedOrNot(21, 3)
      assertDiagnosticWasEmittedOrNot(22, 3)
      assertDiagnosticWasEmittedOrNot(23, 3)
      assertDiagnosticWasEmittedOrNot(24, 3)
    }
  }

  func testFileScopeDeclsInsideNestedConditionals() {
    runWithMultipleConfigurations(
      source: """
        #if FOO
          #if BAR
            $access$ class Foo {}
            $access$ struct Foo {}
            $access$ enum Foo {}
            $access$ protocol Foo {}
            $access$ typealias Foo = Bar
            $access$ func foo() {}
            $access$ var foo: Bar
          #endif
        #endif
        """,
      testConfigurations: changingTestConfigurations
    ) { assertDiagnosticWasEmittedOrNot in
      assertDiagnosticWasEmittedOrNot(3, 5)
      assertDiagnosticWasEmittedOrNot(4, 5)
      assertDiagnosticWasEmittedOrNot(5, 5)
      assertDiagnosticWasEmittedOrNot(6, 5)
      assertDiagnosticWasEmittedOrNot(7, 5)
      assertDiagnosticWasEmittedOrNot(8, 5)
      assertDiagnosticWasEmittedOrNot(9, 5)
    }
  }

  func testLeadingTriviaIsPreserved() {
    runWithMultipleConfigurations(
      source: """
        /// Some doc comment
        $access$ class Foo {}

        @objc /* comment */ $access$ class Bar {}
        """,
      testConfigurations: changingTestConfigurations
    ) { assertDiagnosticWasEmittedOrNot in
      assertDiagnosticWasEmittedOrNot(2, 1)
      assertDiagnosticWasEmittedOrNot(4, 21)
    }
  }

  func testModifierDetailIsPreserved() {
    runWithMultipleConfigurations(
      source: """
        public $access$(set) var foo: Int
        """,
      testConfigurations: changingTestConfigurations
    ) { assertDiagnosticWasEmittedOrNot in
      assertDiagnosticWasEmittedOrNot(1, 8)
    }
  }

  /// Runs a test for this rule in multiple configurations.
  private func runWithMultipleConfigurations(
    source: String,
    testConfigurations: [TestConfiguration],
    file: StaticString = #file,
    line: UInt = #line,
    completion: ((Int, Int) -> Void) -> Void
  ) {
    for testConfig in testConfigurations {
      var configuration = Configuration()
      configuration.fileScopedDeclarationPrivacy.accessLevel = testConfig.desired

      let substitutedInput = source.replacingOccurrences(of: "$access$", with: testConfig.original)
      let substitutedExpected =
        source.replacingOccurrences(of: "$access$", with: testConfig.expected)

      XCTAssertFormatting(
        FileScopedDeclarationPrivacy.self,
        input: substitutedInput,
        expected: substitutedExpected,
        checkForUnassertedDiagnostics: true,
        configuration: configuration,
        file: file,
        line: line)

      let message: Finding.Message =
        testConfig.desired == .private
        ? .replaceFileprivateWithPrivate
        : .replacePrivateWithFileprivate

      if testConfig.original == testConfig.expected {
        completion { _, _ in
          XCTAssertNotDiagnosed(message, file: file, line: line)
        }
      } else {
        completion { diagnosticLine, diagnosticColumn in
          XCTAssertDiagnosed(
            message, line: diagnosticLine, column: diagnosticColumn, file: file, line: line)
        }
      }
    }
  }
}
