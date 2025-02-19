@_spi(Testing) import SwiftFormat
import SwiftParser
import SwiftSyntax
import XCTest
@_spi(Testing) import _SwiftFormatTestSupport

final class WhitespaceLinterPerformanceTests: DiagnosingTestCase {
  /// When executing in Swift CI, run the block to make sure it doesn't hit any assertions because we don't look at
  /// performance numbers in CI and CI nodes can have variable performance characteristics if they are not bare-metal.
  ///
  /// Anywhere else, run XCTest's `measure` function to measure the performance of the block.
  private func measureIfNotInCI(_ block: () -> Void) {
    if ProcessInfo.processInfo.environment["SWIFTCI_USE_LOCAL_DEPS"] != nil {
      block()
    } else {
      measure { block() }
    }
  }

  func testWhitespaceLinterPerformance() throws {
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

    measureIfNotInCI { performWhitespaceLint(input: input, expected: expected) }
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
