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

                /// AClazz is a class with good name.
                public class AClazz {
                }
                """)
  }
}
