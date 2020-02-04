import SwiftFormatRules

final class UseTripleSlashForDocumentationCommentsTests: LintOrFormatRuleTestCase {
  func testRemoveDocBlockComments() {
    XCTAssertFormatting(
      UseTripleSlashForDocumentationComments.self,
      input: """
             /**
              * This comment should not be converted.
              */
             
             /**
              * Returns a docLineComment.
              *
              * - Parameters:
              *   - withOutStar: Indicates if the comment start with a star.
              * - Returns: docLineComment.
              */
             func foo(withOutStar: Bool) {}
             """,
      expected: """
                /**
                 * This comment should not be converted.
                 */
                
                /// Returns a docLineComment.
                ///
                /// - Parameters:
                ///   - withOutStar: Indicates if the comment start with a star.
                /// - Returns: docLineComment.
                func foo(withOutStar: Bool) {}
                """)
  }
  
  func testRemoveDocBlockCommentsWithoutStars() {
    XCTAssertFormatting(
      UseTripleSlashForDocumentationComments.self,
      input: """
             /**
              Returns a docLineComment.
             
              - Parameters:
                - withStar: Indicates if the comment start with a star.
              - Returns: docLineComment.
              */
             public var test = 1
             """,
      expected: """
                /// Returns a docLineComment.
                ///
                /// - Parameters:
                ///   - withStar: Indicates if the comment start with a star.
                /// - Returns: docLineComment.
                public var test = 1
                """)
  }
}
