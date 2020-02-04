import SwiftFormatRules

final class BeginDocumentationCommentWithOneLineSummaryTests: LintOrFormatRuleTestCase {
  override func setUp() {
    // Reset this to false by default. Specific tests may override it.
    BeginDocumentationCommentWithOneLineSummary._forcesFallbackModeForTesting = false
    super.setUp()
  }

  func testDocLineCommentsWithoutOneSentenceSummary() {
    let input =
      """
      /// Returns a bottle of Dr Pepper from the vending machine.
      public func drPepper(from vendingMachine: VendingMachine) -> Soda {}

      /// Contains a comment as description that needs a sentece
      /// of two lines of code.
      public var twoLinesForOneSentence = "test"

      /// The background color of the view.
      var backgroundColor: UIColor

      /// Returns the sum of the numbers.
      ///
      /// - Parameter numbers: The numbers to sum.
      /// - Returns: The sum of the numbers.
      func sum(_ numbers: [Int]) -> Int {
      // ...
      }

      /// This docline should not succeed.
      /// There are two sentences without a blank line between them.
      struct Test {}

      /// This docline should not succeed. There are two sentences.
      public enum Token { case comma, semicolon, identifier }

      /// Should fail because it doesn't have a period
      public class testNoPeriod {}
      """
    performLint(BeginDocumentationCommentWithOneLineSummary.self, input: input)
    XCTAssertDiagnosed(.addBlankLineAfterFirstSentence("This docline should not succeed."))
    XCTAssertDiagnosed(.addBlankLineAfterFirstSentence("This docline should not succeed."))
    XCTAssertDiagnosed(.terminateSentenceWithPeriod("Should fail because it doesn't have a period"))

    XCTAssertNotDiagnosed(.addBlankLineAfterFirstSentence(
      "Returns a bottle of Dr Pepper from the vending machine."))
    XCTAssertNotDiagnosed(.addBlankLineAfterFirstSentence(
      "Contains a comment as description that needs a sentece of two lines of code."))
    XCTAssertNotDiagnosed(.addBlankLineAfterFirstSentence("The background color of the view."))
    XCTAssertNotDiagnosed(.addBlankLineAfterFirstSentence("Returns the sum of the numbers."))
  }

  func testBlockLineCommentsWithoutOneSentenceSummary() {
    let input =
    """
      /**
       * Returns the numeric value.
       *
       * - Parameters:
       *   - digit: The Unicode scalar whose numeric value should be returned.
       *   - radix: The radix, between 2 and 36, used to compute the numeric value.
       * - Returns: The numeric value of the scalar.*/
      func numericValue(of digit: UnicodeScalar, radix: Int = 10) -> Int {}

      /**
       * This block comment contains a sentence summary
       * of two lines of code.
       */
      public var twoLinesForOneSentence = "test"

      /**
       * This block comment should not succeed, struct.
       * There are two sentences without a blank line between them.
       */
      struct TestStruct {}

      /**
      This block comment should not succeed, class.
      Add a blank comment after the first line.
      */
      public class TestClass {}
      /** This block comment should not succeed, enum. There are two sentences. */
      public enum testEnum {}
      /** Should fail because it doesn't have a period */
      public class testNoPeriod {}
      """
    performLint(BeginDocumentationCommentWithOneLineSummary.self, input: input)
    XCTAssertDiagnosed(.addBlankLineAfterFirstSentence("This block comment should not succeed, struct."))
    XCTAssertDiagnosed(.addBlankLineAfterFirstSentence("This block comment should not succeed, class."))
    XCTAssertDiagnosed(.addBlankLineAfterFirstSentence("This block comment should not succeed, enum."))
    XCTAssertDiagnosed(.terminateSentenceWithPeriod("Should fail because it doesn't have a period"))

    XCTAssertNotDiagnosed(.addBlankLineAfterFirstSentence("Returns the numeric value."))
    XCTAssertNotDiagnosed(.addBlankLineAfterFirstSentence(
      "This block comment contains a sentence summary of two lines of code."))
  }

  func testApproximationsOnMacOS() {
    #if os(macOS)
    // Let macOS also verify that the fallback mode works, which gives us signal about whether it
    // will also succeed on Linux (where the linguistic APIs are not currently available).
    BeginDocumentationCommentWithOneLineSummary._forcesFallbackModeForTesting = true

    let input =
    """
      /// Returns a bottle of Dr Pepper from the vending machine.
      public func drPepper(from vendingMachine: VendingMachine) -> Soda {}

      /// Contains a comment as description that needs a sentece
      /// of two lines of code.
      public var twoLinesForOneSentence = "test"

      /// The background color of the view.
      var backgroundColor: UIColor

      /// Returns the sum of the numbers.
      ///
      /// - Parameter numbers: The numbers to sum.
      /// - Returns: The sum of the numbers.
      func sum(_ numbers: [Int]) -> Int {
      // ...
      }

      /// This docline should not succeed.
      /// There are two sentences without a blank line between them.
      struct Test {}

      /// This docline should not succeed. There are two sentences.
      public enum Token { case comma, semicolon, identifier }

      /// Should fail because it doesn't have a period
      public class testNoPeriod {}
      """
    performLint(BeginDocumentationCommentWithOneLineSummary.self, input: input)
    XCTAssertDiagnosed(.addBlankLineAfterFirstSentence("This docline should not succeed."))
    XCTAssertDiagnosed(.addBlankLineAfterFirstSentence("This docline should not succeed."))
    XCTAssertDiagnosed(.terminateSentenceWithPeriod("Should fail because it doesn't have a period"))

    XCTAssertNotDiagnosed(.addBlankLineAfterFirstSentence(
      "Returns a bottle of Dr Pepper from the vending machine."))
    XCTAssertNotDiagnosed(.addBlankLineAfterFirstSentence(
      "Contains a comment as description that needs a sentece of two lines of code."))
    XCTAssertNotDiagnosed(.addBlankLineAfterFirstSentence("The background color of the view."))
    XCTAssertNotDiagnosed(.addBlankLineAfterFirstSentence("Returns the sum of the numbers."))
    #endif
  }
}
