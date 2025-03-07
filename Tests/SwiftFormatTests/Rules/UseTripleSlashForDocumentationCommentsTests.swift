//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2025 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

@_spi(Rules) import SwiftFormat
import _SwiftFormatTestSupport

final class UseTripleSlashForDocumentationCommentsTests: LintOrFormatRuleTestCase {
  func testRemoveDocBlockComments() {
    assertFormatting(
      UseTripleSlashForDocumentationComments.self,
      input: """
        /**
         * This comment should not be converted.
         */

        1️⃣/**
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
        """,
      findings: [
        FindingSpec("1️⃣", message: "replace documentation block comments with documentation line comments")
      ]
    )
  }

  func testRemoveDocBlockCommentsWithoutStars() {
    assertFormatting(
      UseTripleSlashForDocumentationComments.self,
      input: """
        1️⃣/**
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
        """,
      findings: [
        FindingSpec("1️⃣", message: "replace documentation block comments with documentation line comments")
      ]
    )
  }

  func testMultipleTypesOfDocComments() {
    assertFormatting(
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
        """,
      findings: []
    )
  }

  func testMultipleDocLineComments() {
    assertFormatting(
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
        """,
      findings: []
    )
  }

  func testManyDocComments() {
    // Note that this retains the trailing space at the end of a single-line doc block comment
    // (i.e., the space in `name. */`). It's fine to leave it here; the pretty printer will remove
    // it later.
    assertFormatting(
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

        1️⃣/** AClazz is a class with good name. */
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
        """,
      findings: [
        FindingSpec("1️⃣", message: "replace documentation block comments with documentation line comments")
      ]
    )
  }

  func testDocLineCommentsAreNotNormalized() {
    assertFormatting(
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
        """,
      findings: []
    )
  }
}
