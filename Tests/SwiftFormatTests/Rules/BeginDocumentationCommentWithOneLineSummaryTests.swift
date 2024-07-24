import _SwiftFormatTestSupport

@_spi(Rules) import SwiftFormat

// FIXME: We should place the diagnostic somewhere in the comment, not on the declaration.
final class BeginDocumentationCommentWithOneLineSummaryTests: LintOrFormatRuleTestCase {
  override func setUp() {
    // Reset this to false by default. Specific tests may override it.
    BeginDocumentationCommentWithOneLineSummary._forcesFallbackModeForTesting = false
    super.setUp()
  }

  func testDocLineCommentsWithoutOneSentenceSummary() {
    assertLint(
      BeginDocumentationCommentWithOneLineSummary.self,
      """
        /// Returns a bottle of Dr Pepper from the vending machine.
        public func drPepper(from vendingMachine: VendingMachine) -> Soda {}

        /// Contains a comment as description that needs a sentence
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
        1️⃣struct Test {}

        /// This docline should not succeed. There are two sentences.
        2️⃣public enum Token { case comma, semicolon, identifier }

        /// Should fail because it doesn't have a period
        3️⃣public class testNoPeriod {}
      """,
      findings: [
        FindingSpec("1️⃣", message: #"add a blank comment line after this sentence: "This docline should not succeed.""#),
        FindingSpec("2️⃣", message: #"add a blank comment line after this sentence: "This docline should not succeed.""#),
        FindingSpec("3️⃣", message: #"terminate this sentence with a period: "Should fail because it doesn't have a period""#),
      ]
    )
  }

  func testBlockLineCommentsWithoutOneSentenceSummary() {
    assertLint(
      BeginDocumentationCommentWithOneLineSummary.self,
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
        1️⃣struct TestStruct {}

        /**
        This block comment should not succeed, class.
        Add a blank comment after the first line.
        */
        2️⃣public class TestClass {}
        /** This block comment should not succeed, enum. There are two sentences. */
        3️⃣public enum testEnum {}
        /** Should fail because it doesn't have a period */
        4️⃣public class testNoPeriod {}
      """,
      findings: [
        FindingSpec("1️⃣", message: #"add a blank comment line after this sentence: "This block comment should not succeed, struct.""#),
        FindingSpec("2️⃣", message: #"add a blank comment line after this sentence: "This block comment should not succeed, class.""#),
        FindingSpec("3️⃣", message: #"add a blank comment line after this sentence: "This block comment should not succeed, enum.""#),
        FindingSpec("4️⃣", message: #"terminate this sentence with a period: "Should fail because it doesn't have a period""#),
      ]
    )
  }

  func testApproximationsOnMacOS() {
    #if os(macOS)
      // Let macOS also verify that the fallback mode works, which gives us signal about whether it
      // will also succeed on Linux (where the linguistic APIs are not currently available).
      BeginDocumentationCommentWithOneLineSummary._forcesFallbackModeForTesting = true

      assertLint(
        BeginDocumentationCommentWithOneLineSummary.self,
        """
        /// Returns a bottle of Dr Pepper from the vending machine.
        public func drPepper(from vendingMachine: VendingMachine) -> Soda {}

        /// Contains a comment as description that needs a sentence
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
        1️⃣struct Test {}

        /// This docline should not succeed. There are two sentences.
        2️⃣public enum Token { case comma, semicolon, identifier }

        /// Should fail because it doesn't have a period
        3️⃣public class testNoPeriod {}
        """,
        findings: [
          FindingSpec("1️⃣", message: #"add a blank comment line after this sentence: "This docline should not succeed.""#),
          FindingSpec("2️⃣", message: #"add a blank comment line after this sentence: "This docline should not succeed.""#),
          FindingSpec("3️⃣", message: #"terminate this sentence with a period: "Should fail because it doesn't have a period""#),
        ]
      )
    #endif
  }
    
  func testSentenceTerminationInsideQuotes() {
    assertLint(
      BeginDocumentationCommentWithOneLineSummary.self,
      """
      /// Creates an instance with the same raw value as `x` failing iff `x.kind != Subject.kind`.
      struct TestBackTick {}
      
      /// A set of `Diagnostic` that can answer the question ‘was there an error?’ in O(1).
      struct TestSingleSmartQuotes {}
      
      /// A set of `Diagnostic` that can answer the question 'was there an error?' in O(1).
      struct TestSingleStraightQuotes {}
      
      /// A set of `Diagnostic` that can answer the question “was there an error?” in O(1).
      struct TestDoubleSmartQuotes {}
      
      /// A set of `Diagnostic` that can answer the question "was there an error?" in O(1).
      struct TestDoubleStraightQuotes {}
      
      /// A set of `Diagnostic` that can answer the question “was there 
      /// an error?” in O(1).
      struct TestTwoLinesDoubleSmartQuotes {}
      
      /// A set of `Diagnostic` that can answer the question "was there
      /// an error?" in O(1).
      struct TestTwoLinesDoubleStraightQuotes {}
      """
    )
  }

  func testNestedInsideStruct() {
    assertLint(
      BeginDocumentationCommentWithOneLineSummary.self,
      """
      struct MyContainer {
        /// This docline should not succeed.
        /// There are two sentences without a blank line between them.
        1️⃣struct Test {}
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: #"add a blank comment line after this sentence: "This docline should not succeed.""#)
      ]
    )
  }

  func testNestedInsideEnum() {
    assertLint(
      BeginDocumentationCommentWithOneLineSummary.self,
      """
      enum MyContainer {
        /// This docline should not succeed.
        /// There are two sentences without a blank line between them.
        1️⃣struct Test {}
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: #"add a blank comment line after this sentence: "This docline should not succeed.""#)
      ]
    )
  }

  func testNestedInsideClass() {
    assertLint(
      BeginDocumentationCommentWithOneLineSummary.self,
      """
      class MyContainer {
        /// This docline should not succeed.
        /// There are two sentences without a blank line between them.
        1️⃣struct Test {}
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: #"add a blank comment line after this sentence: "This docline should not succeed.""#)
      ]
    )
  }

  func testNestedInsideActor() {
    assertLint(
      BeginDocumentationCommentWithOneLineSummary.self,
      """
      actor MyContainer {
        /// This docline should not succeed.
        /// There are two sentences without a blank line between them.
        1️⃣struct Test {}
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: #"add a blank comment line after this sentence: "This docline should not succeed.""#)
      ]
    )
  }

}
