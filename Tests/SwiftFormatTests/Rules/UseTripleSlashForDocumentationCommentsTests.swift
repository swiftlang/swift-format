@_spi(Rules) import SwiftFormat

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

  func testMultipleTypesOfDocComments() {
    XCTAssertFormatting(
      UseTripleSlashForDocumentationComments.self,
      input: """
             /**
              * This is my preamble. It could be important.
              * This comment stays as-is.
              */

             /// This decl has a comment.
             /// The comment is multiple lines long.
             public class AClazz {
             }
             """,
      expected: """
                /**
                 * This is my preamble. It could be important.
                 * This comment stays as-is.
                 */

                /// This decl has a comment.
                /// The comment is multiple lines long.
                public class AClazz {
                }
                """)
  }

  func testMultipleDocLineComments() {
    XCTAssertFormatting(
      UseTripleSlashForDocumentationComments.self,
      input: """
             /// This is my preamble. It could be important.
             /// This comment stays as-is.
             ///

             /// This decl has a comment.
             /// The comment is multiple lines long.
             public class AClazz {
             }
             """,
      expected: """
                /// This is my preamble. It could be important.
                /// This comment stays as-is.
                ///

                /// This decl has a comment.
                /// The comment is multiple lines long.
                public class AClazz {
                }
                """)
  }

  func testManyDocComments() {
    // Note that this retains the trailing space at the end of a single-line doc block comment
    // (i.e., the space in `name. */`). It's fine to leave it here; the pretty printer will remove
    // it later.
    XCTAssertFormatting(
      UseTripleSlashForDocumentationComments.self,
      input: """
             /**
              * This is my preamble. It could be important.
              * This comment stays as-is.
              */

             /// This is a doc-line comment!

             /** This is a fairly short doc-block comment. */

             /// Why are there so many comments?
             /// Who knows! But there are loads.

             /** AClazz is a class with good name. */
             public class AClazz {
             }
             """,
      expected: """
                /**
                 * This is my preamble. It could be important.
                 * This comment stays as-is.
                 */

                /// This is a doc-line comment!

                /** This is a fairly short doc-block comment. */

                /// Why are there so many comments?
                /// Who knows! But there are loads.

                /// AClazz is a class with good name.\u{0020}
                public class AClazz {
                }
                """)
  }

  func testDocLineCommentsAreNotNormalized() {
    XCTAssertFormatting(
      UseTripleSlashForDocumentationComments.self,
      input: """
        ///
        ///   Normally that initial blank line and these leading spaces
        ///   would be removed by DocumentationCommentText. But we don't
        ///   touch the comment if it's already a doc line comment.
        ///
        public class AClazz {
        }
        """,
      expected: """
        ///
        ///   Normally that initial blank line and these leading spaces
        ///   would be removed by DocumentationCommentText. But we don't
        ///   touch the comment if it's already a doc line comment.
        ///
        public class AClazz {
        }
        """)
  }
}
