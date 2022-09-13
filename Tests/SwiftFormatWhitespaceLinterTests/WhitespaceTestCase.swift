import SwiftFormatConfiguration
import SwiftFormatCore
import SwiftFormatTestSupport
import SwiftFormatWhitespaceLinter
import SwiftSyntax
import SwiftParser
import XCTest

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
    let sourceFileSyntax: SourceFileSyntax
    do {
      sourceFileSyntax = try Parser.parse(source: input)
    } catch {
      XCTFail("Parsing failed with error: \(error)")
      return
    }

    var configuration = Configuration()
    if let linelength = linelength {
      configuration.lineLength = linelength
    }

    let context = makeContext(sourceFileSyntax: sourceFileSyntax, configuration: configuration)
    let linter = WhitespaceLinter(user: input, formatted: expected, context: context)
    linter.lint()
  }
}
