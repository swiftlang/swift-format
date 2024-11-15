@_spi(Testing) import SwiftFormat
import SwiftParser
import SwiftSyntax
import XCTest
@_spi(Testing) import _SwiftFormatTestSupport

final class WhitespaceLinterPerformanceTests: DiagnosingTestCase {
  func testWhitespaceLinterPerformance() {
    let input = String(
      repeating: """
        import      SomeModule
        public   class   SomeClass : SomeProtocol
        {
        var someProperty : SomeType {
            get{5}set{doSomething()}
            }
            public
            func
            someFunctionName
            (
            firstArg    : FirstArgument , secondArg :
            SecondArgument){
          doSomeThings()
                           }}

        """,
      count: 20
    )
    let expected = String(
      repeating: """
        import SomeModule
        public class SomeClass: SomeProtocol {
          var someProperty: SomeType {
            get { 5 }
            set { doSomething() }
          }
          public func someFunctionName(
            firstArg: FirstArgument,
            secondArg: SecondArgument
          ) {
            doSomeThings()
          }
        }

        """,
      count: 20
    )

    measure { performWhitespaceLint(input: input, expected: expected) }
  }

  /// Perform whitespace linting by comparing the input text from the user with the expected
  /// formatted text, using the default configuration.
  ///
  /// - Parameters:
  ///   - input: The user's input text.
  ///   - expected: The formatted text.
  private func performWhitespaceLint(input: String, expected: String) {
    let sourceFileSyntax = Parser.parse(source: input)
    let context = makeContext(
      sourceFileSyntax: sourceFileSyntax,
      selection: .infinite,
      findingConsumer: { _ in }
    )
    let linter = WhitespaceLinter(user: input, formatted: expected, context: context)
    linter.lint()
  }
}
