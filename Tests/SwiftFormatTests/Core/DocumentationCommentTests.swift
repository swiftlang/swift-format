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

import Markdown
@_spi(Testing) import SwiftFormat
import SwiftSyntax
import SwiftSyntaxBuilder
import XCTest

final class DocumentationCommentTests: XCTestCase {
  func testBriefSummaryOnly() throws {
    let decl: DeclSyntax = """
      /// A brief summary.
      func f() {}
      """
    let comment = try XCTUnwrap(DocumentationComment(extractedFrom: decl))
    XCTAssertEqual(
      try XCTUnwrap(comment.briefSummary).debugDescription(),
      """
      Paragraph
      └─ Text "A brief summary."
      """
    )
    XCTAssertTrue(comment.bodyNodes.isEmpty)
    XCTAssertNil(comment.parameterLayout)
    XCTAssertTrue(comment.parameters.isEmpty)
    XCTAssertNil(comment.returns)
    XCTAssertNil(comment.throws)
  }

  func testBriefSummaryAndAdditionalParagraphs() throws {
    let decl: DeclSyntax = """
      /// A brief summary.
      ///
      /// Some detail.
      ///
      /// More detail.
      func f() {}
      """
    let comment = try XCTUnwrap(DocumentationComment(extractedFrom: decl))
    XCTAssertEqual(
      comment.briefSummary?.debugDescription(),
      """
      Paragraph
      └─ Text "A brief summary."
      """
    )
    XCTAssertEqual(
      comment.bodyNodes.map { $0.debugDescription() },
      [
        """
        Paragraph
        └─ Text "Some detail."
        """,
        """
        Paragraph
        └─ Text "More detail."
        """,
      ]
    )
    XCTAssertNil(comment.parameterLayout)
    XCTAssertTrue(comment.parameters.isEmpty)
    XCTAssertNil(comment.returns)
    XCTAssertNil(comment.throws)
  }

  func testParameterOutline() throws {
    let decl: DeclSyntax = """
      /// - Parameters:
      ///   - x: A value.
      ///   - y: Another value.
      func f(x: Int, y: Int) {}
      """
    let comment = try XCTUnwrap(DocumentationComment(extractedFrom: decl))
    XCTAssertNil(comment.briefSummary)
    XCTAssertTrue(comment.bodyNodes.isEmpty)
    XCTAssertEqual(comment.parameterLayout, .outline)
    XCTAssertEqual(comment.parameters.count, 2)
    XCTAssertEqual(comment.parameters[0].name, "x")
    XCTAssertEqual(
      comment.parameters[0].comment.briefSummary?.debugDescription(),
      """
      Paragraph
      └─ Text " A value."
      """
    )
    XCTAssertEqual(comment.parameters[1].name, "y")
    XCTAssertEqual(
      comment.parameters[1].comment.briefSummary?.debugDescription(),
      """
      Paragraph
      └─ Text " Another value."
      """
    )
    XCTAssertNil(comment.returns)
    XCTAssertNil(comment.throws)
  }

  func testSeparatedParameters() throws {
    let decl: DeclSyntax = """
      /// - Parameter x: A value.
      /// - Parameter y: Another value.
      func f(x: Int, y: Int) {}
      """
    let comment = try XCTUnwrap(DocumentationComment(extractedFrom: decl))
    XCTAssertNil(comment.briefSummary)
    XCTAssertTrue(comment.bodyNodes.isEmpty)
    XCTAssertEqual(comment.parameterLayout, .separated)
    XCTAssertEqual(comment.parameters.count, 2)
    XCTAssertEqual(comment.parameters[0].name, "x")
    XCTAssertEqual(
      comment.parameters[0].comment.briefSummary?.debugDescription(),
      """
      Paragraph
      └─ Text " A value."
      """
    )
    XCTAssertEqual(comment.parameters[1].name, "y")
    XCTAssertEqual(
      comment.parameters[1].comment.briefSummary?.debugDescription(),
      """
      Paragraph
      └─ Text " Another value."
      """
    )
    XCTAssertNil(comment.returns)
    XCTAssertNil(comment.throws)
  }

  func testMalformedTagsGoIntoBodyNodes() throws {
    let decl: DeclSyntax = """
      /// - Parameter: A value.
      /// - Parameter y Another value.
      /// - Parmeter z: Another value.
      /// - Parameter *x*: Another value.
      /// - Return: A value.
      /// - Throw: An error.
      func f(x: Int, y: Int) {}
      """
    let comment = try XCTUnwrap(DocumentationComment(extractedFrom: decl))
    XCTAssertEqual(comment.bodyNodes.count, 1)
    XCTAssertEqual(
      comment.bodyNodes[0].debugDescription(),
      """
      UnorderedList
      ├─ ListItem
      │  └─ Paragraph
      │     └─ Text "Parameter: A value."
      ├─ ListItem
      │  └─ Paragraph
      │     └─ Text "Parameter y Another value."
      ├─ ListItem
      │  └─ Paragraph
      │     └─ Text "Parmeter z: Another value."
      ├─ ListItem
      │  └─ Paragraph
      │     ├─ Text "Parameter "
      │     ├─ Emphasis
      │     │  └─ Text "x"
      │     └─ Text ": Another value."
      ├─ ListItem
      │  └─ Paragraph
      │     └─ Text "Return: A value."
      └─ ListItem
         └─ Paragraph
            └─ Text "Throw: An error."
      """
    )
    XCTAssertNil(comment.parameterLayout)
    XCTAssertTrue(comment.parameters.isEmpty)
  }

  func testReturnsField() throws {
    let decl: DeclSyntax = """
      /// - Returns: A value.
      func f() {}
      """
    let comment = try XCTUnwrap(DocumentationComment(extractedFrom: decl))
    XCTAssertNil(comment.briefSummary)
    XCTAssertTrue(comment.bodyNodes.isEmpty)
    XCTAssertNil(comment.parameterLayout)
    XCTAssertTrue(comment.parameters.isEmpty)

    let returnsField = try XCTUnwrap(comment.returns)
    XCTAssertEqual(
      returnsField.debugDescription(),
      """
      Paragraph
      └─ Text " A value."
      """
    )
    XCTAssertNil(comment.throws)
  }

  func testThrowsField() throws {
    let decl: DeclSyntax = """
      /// - Throws: An error.
      func f() {}
      """
    let comment = try XCTUnwrap(DocumentationComment(extractedFrom: decl))
    XCTAssertNil(comment.briefSummary)
    XCTAssertTrue(comment.bodyNodes.isEmpty)
    XCTAssertNil(comment.parameterLayout)
    XCTAssertTrue(comment.parameters.isEmpty)
    XCTAssertNil(comment.returns)

    let throwsField = try XCTUnwrap(comment.throws)
    XCTAssertEqual(
      throwsField.debugDescription(),
      """
      Paragraph
      └─ Text " An error."
      """
    )
  }

  func testUnrecognizedFieldsGoIntoBodyNodes() throws {
    let decl: DeclSyntax = """
      /// - Blahblah: Blah.
      /// - Return: A value.
      /// - Throw: An error.
      func f() {}
      """
    let comment = try XCTUnwrap(DocumentationComment(extractedFrom: decl))
    XCTAssertNil(comment.briefSummary)
    XCTAssertEqual(
      comment.bodyNodes.map { $0.debugDescription() },
      [
        """
        UnorderedList
        ├─ ListItem
        │  └─ Paragraph
        │     └─ Text "Blahblah: Blah."
        ├─ ListItem
        │  └─ Paragraph
        │     └─ Text "Return: A value."
        └─ ListItem
           └─ Paragraph
              └─ Text "Throw: An error."
        """
      ]
    )
    XCTAssertNil(comment.parameterLayout)
    XCTAssertTrue(comment.parameters.isEmpty)
    XCTAssertNil(comment.returns)
    XCTAssertNil(comment.throws)
  }

  func testNestedCommentInParameter() throws {
    let decl: DeclSyntax = """
      /// - Parameters:
      ///   - g: A function.
      ///     - Parameter x: A value.
      ///     - Parameter y: Another value.
      ///     - Returns: A result.
      func f(g: (x: Int, y: Int) -> Int) {}
      """
    let comment = try XCTUnwrap(DocumentationComment(extractedFrom: decl))
    XCTAssertNil(comment.briefSummary)
    XCTAssertTrue(comment.bodyNodes.isEmpty)
    XCTAssertEqual(comment.parameterLayout, .outline)
    XCTAssertEqual(comment.parameters.count, 1)
    XCTAssertEqual(comment.parameters[0].name, "g")
    XCTAssertNil(comment.returns)
    XCTAssertNil(comment.throws)

    let paramComment = comment.parameters[0].comment
    XCTAssertEqual(
      paramComment.briefSummary?.debugDescription(),
      """
      Paragraph
      └─ Text " A function."
      """
    )
    XCTAssertTrue(paramComment.bodyNodes.isEmpty)
    XCTAssertEqual(paramComment.parameterLayout, .separated)
    XCTAssertEqual(paramComment.parameters.count, 2)
    XCTAssertEqual(paramComment.parameters[0].name, "x")
    XCTAssertEqual(
      paramComment.parameters[0].comment.briefSummary?.debugDescription(),
      """
      Paragraph
      └─ Text " A value."
      """
    )
    XCTAssertEqual(paramComment.parameters[1].name, "y")
    XCTAssertEqual(
      paramComment.parameters[1].comment.briefSummary?.debugDescription(),
      """
      Paragraph
      └─ Text " Another value."
      """
    )
    XCTAssertEqual(
      paramComment.returns?.debugDescription(),
      """
      Paragraph
      └─ Text " A result."
      """
    )
    XCTAssertNil(paramComment.throws)
  }
}
