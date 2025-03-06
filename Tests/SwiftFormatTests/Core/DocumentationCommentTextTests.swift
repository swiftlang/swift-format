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

@_spi(Testing) import SwiftFormat
import SwiftSyntax
import SwiftSyntaxBuilder
import XCTest

final class DocumentationCommentTextTests: XCTestCase {
  func testSimpleDocLineComment() throws {
    let decl: DeclSyntax = """
      /// A simple doc comment.
      func f() {}
      """
    let commentText = try XCTUnwrap(DocumentationCommentText(extractedFrom: decl.leadingTrivia))
    XCTAssertEqual(commentText.introducer, .line)
    XCTAssertEqual(
      commentText.text,
      """
      A simple doc comment.

      """
    )
  }

  func testOneLineDocBlockComment() throws {
    let decl: DeclSyntax = """
      /** A simple doc comment. */
      func f() {}
      """
    let commentText = try XCTUnwrap(DocumentationCommentText(extractedFrom: decl.leadingTrivia))
    XCTAssertEqual(commentText.introducer, .block)
    XCTAssertEqual(
      commentText.text,
      """
      A simple doc comment.\u{0020}

      """
    )
  }

  func testDocBlockCommentWithASCIIArt() throws {
    let decl: DeclSyntax = """
      /**
       * A simple doc comment.
       */
      func f() {}
      """
    let commentText = try XCTUnwrap(DocumentationCommentText(extractedFrom: decl.leadingTrivia))
    XCTAssertEqual(commentText.introducer, .block)
    XCTAssertEqual(
      commentText.text,
      """
      A simple doc comment.

      """
    )
  }

  func testIndentedDocBlockCommentWithASCIIArt() throws {
    let decl: DeclSyntax = """
        /**
         * A simple doc comment.
         */
        func f() {}
      """
    let commentText = try XCTUnwrap(DocumentationCommentText(extractedFrom: decl.leadingTrivia))
    XCTAssertEqual(commentText.introducer, .block)
    XCTAssertEqual(
      commentText.text,
      """
      A simple doc comment.

      """
    )
  }

  func testDocBlockCommentWithoutASCIIArt() throws {
    let decl: DeclSyntax = """
      /**
         A simple doc comment.
       */
      func f() {}
      """
    let commentText = try XCTUnwrap(DocumentationCommentText(extractedFrom: decl.leadingTrivia))
    XCTAssertEqual(commentText.introducer, .block)
    XCTAssertEqual(
      commentText.text,
      """
      A simple doc comment.

      """
    )
  }

  func testMultilineDocLineComment() throws {
    let decl: DeclSyntax = """
      /// A doc comment.
      ///
      /// This is a longer paragraph,
      /// containing more detail.
      ///
      /// - Parameter x: A parameter.
      /// - Returns: A value.
      func f(x: Int) -> Int {}
      """
    let commentText = try XCTUnwrap(DocumentationCommentText(extractedFrom: decl.leadingTrivia))
    XCTAssertEqual(commentText.introducer, .line)
    XCTAssertEqual(
      commentText.text,
      """
      A doc comment.

      This is a longer paragraph,
      containing more detail.

      - Parameter x: A parameter.
      - Returns: A value.

      """
    )
  }

  func testDocLineCommentStopsAtBlankLine() throws {
    let decl: DeclSyntax = """
      /// This should not be part of the comment.

      /// A doc comment.
      func f(x: Int) -> Int {}
      """
    let commentText = try XCTUnwrap(DocumentationCommentText(extractedFrom: decl.leadingTrivia))
    XCTAssertEqual(commentText.introducer, .line)
    XCTAssertEqual(
      commentText.text,
      """
      A doc comment.

      """
    )
  }

  func testDocBlockCommentStopsAtBlankLine() throws {
    let decl: DeclSyntax = """
      /** This should not be part of the comment. */

      /**
       * This is part of the comment.
       */
      /** so is this */
      func f(x: Int) -> Int {}
      """
    let commentText = try XCTUnwrap(DocumentationCommentText(extractedFrom: decl.leadingTrivia))
    XCTAssertEqual(commentText.introducer, .block)
    XCTAssertEqual(
      commentText.text,
      """
      This is part of the comment.
       so is this\u{0020}

      """
    )
  }

  func testDocCommentHasMixedIntroducers() throws {
    let decl: DeclSyntax = """
      /// This is part of the comment.
      /** This is too. */
      func f(x: Int) -> Int {}
      """
    let commentText = try XCTUnwrap(DocumentationCommentText(extractedFrom: decl.leadingTrivia))
    XCTAssertEqual(commentText.introducer, .mixed)
    XCTAssertEqual(
      commentText.text,
      """
      This is part of the comment.
      This is too.\u{0020}

      """
    )
  }

  func testNilIfNoComment() throws {
    let decl: DeclSyntax = """
      func f(x: Int) -> Int {}
      """
    XCTAssertNil(DocumentationCommentText(extractedFrom: decl.leadingTrivia))
  }
}
