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

final class ReflowCommentsTests: LintOrFormatRuleTestCase {
  func testMergesTwoLineComment() {
    assertFormatting(
      ReflowComments.self,
      input: """
        // This comment was
        1️⃣// unnecessarily wrapped.
        let x = 1
        """,
      expected: """
        // This comment was unnecessarily wrapped.
        let x = 1
        """,
      findings: [
        FindingSpec("1️⃣", message: "join this comment with the preceding line")
      ]
    )
  }

  func testMergesIndentedLineComments() {
    assertFormatting(
      ReflowComments.self,
      input: """
        func foo() {
          // This comment was
          1️⃣// unnecessarily wrapped.
          let x = 1
        }
        """,
      expected: """
        func foo() {
          // This comment was unnecessarily wrapped.
          let x = 1
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "join this comment with the preceding line")
      ]
    )
  }

  func testDoesNotMergeIndentedLineCommentsThatOverflowAtTheirColumn() {
    // The merged line fits at column 0 (32 columns) but not at the comment's indented column
    // (34 columns). Don't merge.
    assertFormatting(
      ReflowComments.self,
      input: """
        func foo() {
          // aaaa bbbb cccc dddd
          // eeee ffff
          let x = 1
        }
        """,
      expected: """
        func foo() {
          // aaaa bbbb cccc dddd
          // eeee ffff
          let x = 1
        }
        """,
      findings: [],
      configuration: {
        var config = Configuration.forTesting(enabledRule: ReflowComments.ruleName)
        config.lineLength = 33
        return config
      }()
    )
  }

  func testMergesThreeLineComment() {
    assertFormatting(
      ReflowComments.self,
      input: """
        // This comment was split
        1️⃣// across three
        2️⃣// separate lines.
        let x = 1
        """,
      expected: """
        // This comment was split across three separate lines.
        let x = 1
        """,
      findings: [
        FindingSpec("1️⃣", message: "join this comment with the preceding line"),
        FindingSpec("2️⃣", message: "join this comment with the preceding line"),
      ]
    )
  }

  func testMergesDocComment() {
    assertFormatting(
      ReflowComments.self,
      input: """
        /// This doc comment was
        1️⃣/// unnecessarily wrapped.
        func foo() {}
        """,
      expected: """
        /// This doc comment was unnecessarily wrapped.
        func foo() {}
        """,
      findings: [
        FindingSpec("1️⃣", message: "join this comment with the preceding line")
      ]
    )
  }

  func testDoesNotMergeAcrossBlankCommentLine() {
    assertFormatting(
      ReflowComments.self,
      input: """
        // First paragraph.
        //
        // Second paragraph.
        let x = 1
        """,
      expected: """
        // First paragraph.
        //
        // Second paragraph.
        let x = 1
        """,
      findings: []
    )
  }

  func testDoesNotMergeAcrossBlankLine() {
    assertFormatting(
      ReflowComments.self,
      input: """
        // First comment.

        // Second comment.
        let x = 1
        """,
      expected: """
        // First comment.

        // Second comment.
        let x = 1
        """,
      findings: []
    )
  }

  func testDoesNotMergeWhenResultExceedsLineLength() {
    assertFormatting(
      ReflowComments.self,
      input: """
        // This comment line is already quite long and cannot be
        // merged with this continuation without exceeding the limit.
        let x = 1
        """,
      expected: """
        // This comment line is already quite long and cannot be
        // merged with this continuation without exceeding the limit.
        let x = 1
        """,
      findings: [],
      // Set a short line length so the merge would overflow.
      configuration: {
        var config = Configuration.forTesting
        config.lineLength = 60
        return config
      }()
    )
  }

  func testDoesNotMergeListItems() {
    assertFormatting(
      ReflowComments.self,
      input: """
        // Items:
        // - first
        // - second
        let x = 1
        """,
      expected: """
        // Items:
        // - first
        // - second
        let x = 1
        """,
      findings: []
    )
  }

  func testDoesNotMergeNumberedListItems() {
    assertFormatting(
      ReflowComments.self,
      input: """
        // Steps:
        // 1. first
        // 2. second
        let x = 1
        """,
      expected: """
        // Steps:
        // 1. first
        // 2. second
        let x = 1
        """,
      findings: []
    )
  }

  func testDoesNotMergeIndentedCodeBlock() {
    assertFormatting(
      ReflowComments.self,
      input: """
        /// Example:
        ///
        ///     foo()
        ///     bar()
        func baz() {}
        """,
      expected: """
        /// Example:
        ///
        ///     foo()
        ///     bar()
        func baz() {}
        """,
      findings: []
    )
  }

  func testDoesNotMergeMarkdownHeading() {
    assertFormatting(
      ReflowComments.self,
      input: """
        // # Section
        // body text
        let x = 1
        """,
      expected: """
        // # Section
        // body text
        let x = 1
        """,
      findings: []
    )
  }

  func testDoesNotMixRegularAndDocComments() {
    assertFormatting(
      ReflowComments.self,
      input: """
        // regular comment
        /// doc comment
        func foo() {}
        """,
      expected: """
        // regular comment
        /// doc comment
        func foo() {}
        """,
      findings: []
    )
  }

  func testDoesNotMergeXcodeAnnotations() {
    assertFormatting(
      ReflowComments.self,
      input: """
        // MARK: - Section
        // TODO: fix this
        // FIXME: broken
        let x = 1
        """,
      expected: """
        // MARK: - Section
        // TODO: fix this
        // FIXME: broken
        let x = 1
        """,
      findings: []
    )
  }

  func testMergesLinesContainingURL() {
    // URLs are ordinary prose: a line containing a URL merges with its neighbor when the result
    // fits.
    assertFormatting(
      ReflowComments.self,
      input: """
        // Visit https://example.com today
        1️⃣// for the full guide.
        let x = 1
        """,
      expected: """
        // Visit https://example.com today for the full guide.
        let x = 1
        """,
      findings: [
        FindingSpec("1️⃣", message: "join this comment with the preceding line")
      ]
    )
  }

  func testCustomPreservedLinePrefix() {
    // A user-supplied prefix wins: the rule leaves the `NOTE:` line alone, while ordinary prose in
    // the same block still merges.
    assertFormatting(
      ReflowComments.self,
      input: """
        // This ordinary comment was
        1️⃣// wrapped and should join.
        //
        // NOTE: keep this on
        // its own line.
        let x = 1
        """,
      expected: """
        // This ordinary comment was wrapped and should join.
        //
        // NOTE: keep this on
        // its own line.
        let x = 1
        """,
      findings: [
        FindingSpec("1️⃣", message: "join this comment with the preceding line")
      ],
      configuration: {
        var config = Configuration.forTesting(enabledRule: ReflowComments.ruleName)
        config.reflowComments.preservedLinePrefixes = ["NOTE:"]
        return config
      }()
    )
  }

  func testDoesNotReflowLicenseHeader() {
    // The standard Swift.org file header must survive untouched, even when the line length is
    // generous enough that adjacent lines would otherwise merge.
    let header = """
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
      let x = 1
      """
    assertFormatting(
      ReflowComments.self,
      input: header,
      expected: header,
      findings: [],
      configuration: {
        var config = Configuration.forTesting(enabledRule: ReflowComments.ruleName)
        config.lineLength = 200
        config.reflowComments.preservedLinePrefixes = []
        return config
      }()
    )
  }

  func testDoesNotMergeSectionDividerWithText() {
    assertFormatting(
      ReflowComments.self,
      input: """
        //===--- Section Header ---===//
        // this describes the section
        let x = 1
        """,
      expected: """
        //===--- Section Header ---===//
        // this describes the section
        let x = 1
        """,
      findings: []
    )
  }

  func testMergesThreeDocLineComment() {
    assertFormatting(
      ReflowComments.self,
      input: """
        /// This doc comment was split
        1️⃣/// across three
        2️⃣/// separate lines.
        func foo() {}
        """,
      expected: """
        /// This doc comment was split across three separate lines.
        func foo() {}
        """,
      findings: [
        FindingSpec("1️⃣", message: "join this comment with the preceding line"),
        FindingSpec("2️⃣", message: "join this comment with the preceding line"),
      ]
    )
  }

  func testMergesLineCommentsOnlyWithinParagraph() {
    assertFormatting(
      ReflowComments.self,
      input: """
        // First paragraph was
        1️⃣// wrapped here.
        //
        // Second paragraph was
        2️⃣// also wrapped.
        let x = 1
        """,
      expected: """
        // First paragraph was wrapped here.
        //
        // Second paragraph was also wrapped.
        let x = 1
        """,
      findings: [
        FindingSpec("1️⃣", message: "join this comment with the preceding line"),
        FindingSpec("2️⃣", message: "join this comment with the preceding line"),
      ]
    )
  }

  func testReflowsDocCommentSummaryButPreservesParameterList() {
    // The summary paragraph is reflowed, but the DocC `- Parameter`/`- Returns` list items are
    // recognized as Markdown list items and left untouched.
    assertFormatting(
      ReflowComments.self,
      input: """
        /// Combines the two given values into a single result using the
        1️⃣/// documented algorithm.
        ///
        /// - Parameter first: The first value.
        /// - Parameter second: The second value.
        /// - Returns: The combined result.
        func combine(first: Int, second: Int) -> Int { 0 }
        """,
      expected: """
        /// Combines the two given values into a single result using the documented algorithm.
        ///
        /// - Parameter first: The first value.
        /// - Parameter second: The second value.
        /// - Returns: The combined result.
        func combine(first: Int, second: Int) -> Int { 0 }
        """,
      findings: [
        FindingSpec("1️⃣", message: "join this comment with the preceding line")
      ]
    )
  }

  func testMergesWrappedParameterDescription() {
    // The summary reflows, and a wrapped description inside a `- Parameters:` outline item is
    // joined too, while separate items stay separate.
    assertFormatting(
      ReflowComments.self,
      input: """
        /// Processes the input using the configured strategy and returns
        1️⃣/// the transformed output.
        ///
        /// - Parameters:
        ///   - value: The value to process that is
        2️⃣///     described across two lines.
        ///   - count: The number of iterations.
        func process(value: Int, count: Int) {}
        """,
      expected: """
        /// Processes the input using the configured strategy and returns the transformed output.
        ///
        /// - Parameters:
        ///   - value: The value to process that is described across two lines.
        ///   - count: The number of iterations.
        func process(value: Int, count: Int) {}
        """,
      findings: [
        FindingSpec("1️⃣", message: "join this comment with the preceding line"),
        FindingSpec("2️⃣", message: "join this comment with the preceding line"),
      ]
    )
  }

  func testReflowsOnlyLineCommentsWhenDocLineDisabled() {
    assertFormatting(
      ReflowComments.self,
      input: """
        // This regular comment was
        1️⃣// wrapped here.
        /// This doc comment was
        /// wrapped here.
        func foo() {}
        """,
      expected: """
        // This regular comment was wrapped here.
        /// This doc comment was
        /// wrapped here.
        func foo() {}
        """,
      findings: [
        FindingSpec("1️⃣", message: "join this comment with the preceding line")
      ],
      // Only reflow `//` line comments; leave `///` doc comments untouched.
      configuration: {
        var config = Configuration.forTesting(enabledRule: ReflowComments.ruleName)
        config.reflowComments.reflowedCommentKinds = [.line]
        return config
      }()
    )
  }

  func testReflowsOnlyDocLineCommentsWhenLineDisabled() {
    assertFormatting(
      ReflowComments.self,
      input: """
        // This regular comment was
        // wrapped here.
        /// This doc comment was
        1️⃣/// wrapped here.
        func foo() {}
        """,
      expected: """
        // This regular comment was
        // wrapped here.
        /// This doc comment was wrapped here.
        func foo() {}
        """,
      findings: [
        FindingSpec("1️⃣", message: "join this comment with the preceding line")
      ],
      // Only reflow `///` doc comments; leave `//` line comments untouched.
      configuration: {
        var config = Configuration.forTesting(enabledRule: ReflowComments.ruleName)
        config.reflowComments.reflowedCommentKinds = [.docLine]
        return config
      }()
    )
  }

  func testDoesNotMergeBlockquoteLines() {
    assertFormatting(
      ReflowComments.self,
      input: """
        // > quoted line one
        // > quoted line two
        let x = 1
        """,
      expected: """
        // > quoted line one
        // > quoted line two
        let x = 1
        """,
      findings: []
    )
  }

  func testDoesNotMergeDecoratedBanners() {
    assertFormatting(
      ReflowComments.self,
      input: """
        // ----- Section -----
        // some description
        // === Notes ===
        // detail line
        //===--- Foo ---===//
        // trailing text
        let x = 1
        """,
      expected: """
        // ----- Section -----
        // some description
        // === Notes ===
        // detail line
        //===--- Foo ---===//
        // trailing text
        let x = 1
        """,
      findings: []
    )
  }
}
