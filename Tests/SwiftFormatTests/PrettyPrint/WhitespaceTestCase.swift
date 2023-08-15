import SwiftFormatConfiguration
import SwiftFormatCore
import SwiftFormatWhitespaceLinter
import SwiftSyntax
import SwiftParser
import XCTest
import _SwiftFormatTestSupport

class WhitespaceTestCase: DiagnosingTestCase {
  override func setUp() {
    super.setUp()
    shouldCheckForUnassertedDiagnostics = true
  }

  /// Perform whitespace linting by comparing the input text from the user with the expected
  /// formatted text.
  ///
  /// - Parameters:
  ///   - input: The user's input text.
  ///   - expected: The formatted text.
  ///   - linelength: The maximum allowed line length of the output.
  final func performWhitespaceLint(input: String, expected: String, linelength: Int? = nil) {
    let sourceFileSyntax = Parser.parse(source: input)
    var configuration = Configuration.forTesting
    if let linelength = linelength {
      configuration.lineLength = linelength
    }

    let context = makeContext(sourceFileSyntax: sourceFileSyntax, configuration: configuration)
    let linter = WhitespaceLinter(user: input, formatted: expected, context: context)
    linter.lint()
  }
}