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

import SwiftFormat
import _SwiftFormatTestSupport

final class CommentTests: PrettyPrintTestCase {
  func testDocumentationComments() {
    let input =
      """
      /// This is a documentation comment
      ///
      /// - Parameters:
      ///   - param1: Param1 comment
      ///   - param2: Param2 comment
      /// - Returns: The output
      func myfun(param1: Int, param2: Double) -> String {
        let out = "123"
        return out
      }

      /// A brief doc comment
      func myfun() {
        let a = 123
        let b = "456"
      }

      public class MyClass {
        /// Doc comment
        var myVariable: Int

        /// Method doc comment
        ///
        /// - Parameters:
        ///   - param1: Param1 comment
        ///   - param2: Param2 comment
        /// - Returns: The output
        func myFun(param1: Int, param2: Int) -> String {
          let a = 123
          let b = "456"
          return b
        }
      }
      """

    let expected =
      """
      /// This is a documentation comment
      ///
      /// - Parameters:
      ///   - param1: Param1 comment
      ///   - param2: Param2 comment
      /// - Returns: The output
      func myfun(param1: Int, param2: Double) -> String {
        let out = "123"
        return out
      }

      /// A brief doc comment
      func myfun() {
        let a = 123
        let b = "456"
      }

      public class MyClass {
        /// Doc comment
        var myVariable: Int

        /// Method doc comment
        ///
        /// - Parameters:
        ///   - param1: Param1 comment
        ///   - param2: Param2 comment
        /// - Returns: The output
        func myFun(param1: Int, param2: Int) -> String {
          let a = 123
          let b = "456"
          return b
        }
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 55)
  }

  func testLineComments() {
    let input =
      """
      // Line Comment0

      // Line Comment1
      // Line Comment2
      let a = 123
      let b = "456"  // End of line comment
      let c = "More content"

      // Comment 3
      // Comment 4

      let reallyLongVariableName = 123 // This comment should not wrap
      // and should not combine with this comment

      func MyFun() {
        // just a comment
      }

      func MyFun() {
        // Comment 1
        // Comment 2
        let a = 123

        let b = 456  // Comment 3
      }

      func MyFun() {
        let c = 789 // Comment 4
        // Comment 5
      }

      let a = myfun(123 // Cmt 7
      )
      let a = myfun(var1: 123 // Cmt 7
      )

      guard condition else { return // Cmt 6
      }

      switch myvar {
      case .one, .two, // three
           .four:
        dostuff()
      default: ()
      }

      let a = 123 +  // comment
        b + c

      let d = 123
      // Trailing Comment
      """

    let expected =
      """
      // Line Comment0

      // Line Comment1
      // Line Comment2
      let a = 123
      let b = "456"  // End of line comment
      let c = "More content"

      // Comment 3
      // Comment 4

      let reallyLongVariableName = 123  // This comment should not wrap
      // and should not combine with this comment

      func MyFun() {
        // just a comment
      }

      func MyFun() {
        // Comment 1
        // Comment 2
        let a = 123

        let b = 456  // Comment 3
      }

      func MyFun() {
        let c = 789  // Comment 4
        // Comment 5
      }

      let a = myfun(
        123  // Cmt 7
      )
      let a = myfun(
        var1: 123  // Cmt 7
      )

      guard condition else {
        return  // Cmt 6
      }

      switch myvar {
      case .one, .two,  // three
        .four:
        dostuff()
      default: ()
      }

      let a =
        123  // comment
        + b + c

      let d = 123
      // Trailing Comment

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 45)
  }

  func testLineCommentsWithCustomLeadingSpaces() {
    let pairs: [(String, String)] = [
      (
        """
        // Line Comment0

        // Line Comment1
        // Line Comment2
        let a = 123
        let b = "456"  // End of line comment
        let c = "More content"

        """,
        """
        // Line Comment0

        // Line Comment1
        // Line Comment2
        let a = 123
        let b = "456"   // End of line comment
        let c = "More content"

        """
      ),
      (
        """
        // Comment 3
        // Comment 4

        let reallyLongVariableName = 123 // This comment should not wrap
        // and should not combine with this comment

        func MyFun() {
          // just a comment
        }
        """,
        """
        // Comment 3
        // Comment 4

        let reallyLongVariableName = 123   // This comment should not wrap
        // and should not combine with this comment

        func MyFun() {
          // just a comment
        }

        """
      ),
      (
        """
        func MyFun() {
          // Comment 1
          // Comment 2
          let a = 123

          let b = 456  // Comment 3
        }

        func MyFun() {
          let c = 789 // Comment 4
          // Comment 5
        }
        """,
        """
        func MyFun() {
          // Comment 1
          // Comment 2
          let a = 123

          let b = 456   // Comment 3
        }

        func MyFun() {
          let c = 789   // Comment 4
          // Comment 5
        }

        """
      ),
      (
        """
        let a = myfun(123 // Cmt 7
        )
        let a = myfun(var1: 123 // Cmt 7
        )

        guard condition else { return // Cmt 6
        }

        switch myvar {
        case .one, .two, // three
             .four:
          dostuff()
        default: ()
        }

        """,
        """
        let a = myfun(
          123   // Cmt 7
        )
        let a = myfun(
          var1: 123   // Cmt 7
        )

        guard condition else {
          return   // Cmt 6
        }

        switch myvar {
        case .one, .two,   // three
          .four:
          dostuff()
        default: ()
        }

        """
      ),
      (
        """
        let a = 123 +  // comment
          b + c

        let d = 123
        // Trailing Comment
        """,
        """
        let a =
          123   // comment
          + b + c

        let d = 123
        // Trailing Comment

        """
      ),
    ]

    var config = Configuration.forTesting
    config.spacesBeforeEndOfLineComments = 3
    for (input, expected) in pairs {
      assertPrettyPrintEqual(input: input, expected: expected, linelength: 45, configuration: config)
    }
  }

  func testContainerLineComments() {
    let input =
      """
      // Array comment
      let a = [456, // small comment
        789]

      // Dictionary comment
      let b = ["abc": 456, // small comment
        "def": 789]

      // Trailing comment
      let c = [123, 456  // small comment
      ]

      // Multiline comment
      let d = [123,
        // comment line 1
        // comment line 2
        456
      ]

      /* Array comment */
      let a = [456, /* small comment */
        789]

      /* Dictionary comment */
      let b = ["abc": 456, /* small comment */
        "def": 789]
      """

    let expected =
      """
      // Array comment
      let a = [
        456,  // small comment
        789,
      ]

      // Dictionary comment
      let b = [
        "abc": 456,  // small comment
        "def": 789,
      ]

      // Trailing comment
      let c = [
        123, 456,  // small comment
      ]

      // Multiline comment
      let d = [
        123,
        // comment line 1
        // comment line 2
        456,
      ]

      /* Array comment */
      let a = [
        456, /* small comment */
        789,
      ]

      /* Dictionary comment */
      let b = [
        "abc": 456, /* small comment */
        "def": 789,
      ]

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 80)
  }

  func testContainerLineCommentsWithCustomLeadingSpaces() {
    let input =
      """
      // Array comment
      let a = [456, // small comment
        789]

      // Dictionary comment
      let b = ["abc": 456, // small comment
        "def": 789]

      // Trailing comment
      let c = [123, 456  // small comment
      ]

      // Multiline comment
      let d = [123,
        // comment line 1
        // comment line 2
        456
      ]

      /* Array comment */
      let a = [456, /* small comment */
        789]

      /* Dictionary comment */
      let b = ["abc": 456, /* small comment */
        "def": 789]
      """

    let expected =
      """
      // Array comment
      let a = [
        456, // small comment
        789,
      ]

      // Dictionary comment
      let b = [
        "abc": 456, // small comment
        "def": 789,
      ]

      // Trailing comment
      let c = [
        123, 456, // small comment
      ]

      // Multiline comment
      let d = [
        123,
        // comment line 1
        // comment line 2
        456,
      ]

      /* Array comment */
      let a = [
        456, /* small comment */
        789,
      ]

      /* Dictionary comment */
      let b = [
        "abc": 456, /* small comment */
        "def": 789,
      ]

      """
    var config = Configuration.forTesting
    config.spacesBeforeEndOfLineComments = 1
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 80, configuration: config)
  }

  func testDocumentationBlockComments() {
    let input =
      """
      /** This is a documentation comment
       *
       * - Parameters:
       *   - param1: Param1 comment
       *   - param2: Param2 comment
       * - Returns: The output
      **/
      func myfun(param1: Int, param2: Double) -> String {
        let out = "123"
        return out
      }

      /** A brief doc comment **/
      func myfun() {
        let a = 123
        let b = "456"
      }

      public class MyClass {
        /** Doc comment **/
        var myVariable: Int

        /** Method doc comment
         *
         * - Parameters:
         *   - param1: Param1 comment
         *   - param2: Param2 comment
         * - Returns: The output
        **/
        func myFun(param1: Int, param2: Int) -> String {
          let a = 123
          let b = "456"
          return b
        }
      }
      """

    let expected =
      """
      /** This is a documentation comment
       *
       * - Parameters:
       *   - param1: Param1 comment
       *   - param2: Param2 comment
       * - Returns: The output
      **/
      func myfun(param1: Int, param2: Double) -> String {
        let out = "123"
        return out
      }

      /** A brief doc comment **/
      func myfun() {
        let a = 123
        let b = "456"
      }

      public class MyClass {
        /** Doc comment **/
        var myVariable: Int

        /** Method doc comment
         *
         * - Parameters:
         *   - param1: Param1 comment
         *   - param2: Param2 comment
         * - Returns: The output
        **/
        func myFun(param1: Int, param2: Int) -> String {
          let a = 123
          let b = "456"
          return b
        }
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 55)
  }

  func testBlockComments() {
    let input =
      """
              /* Line Comment1 */
      /* Line Comment2 */
      let a = 123
      let b = "456"  /* End of line comment */
      let c = "More content"

            /* Comment 3
               Comment 4 */

      let reallyLongVariableName = 123  /* This comment should wrap */

      let a = myfun(123 /* Cmt 5 */
      )
      let a = myfun(var1: 123 /* Cmt 5 */
      )

      guard condition else { return /* Cmt 6 */
      }

      let d = 123
        /* Trailing Comment */
        /* Trailing
           Block Comment */
      """

    let expected =
      """
      /* Line Comment1 */
      /* Line Comment2 */
      let a = 123
      let b = "456" /* End of line comment */
      let c = "More content"

      /* Comment 3
         Comment 4 */

      let reallyLongVariableName =
        123 /* This comment should wrap */

      let a = myfun(
        123 /* Cmt 5 */
      )
      let a = myfun(
        var1: 123 /* Cmt 5 */
      )

      guard condition else {
        return /* Cmt 6 */
      }

      let d = 123
      /* Trailing Comment */
      /* Trailing
         Block Comment */

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 45)
  }

  func testDoesNotInsertExtraNewlinesAfterTrailingComments() {
    let input =
      """
      struct Foo {
        var foo: Int  // foo
        var bar: Int  // bar
      }

      enum Foo {
        case foo
        case bar  // bar
        case baz  // baz
        case quux
      }
      """

    let expected =
      """
      struct Foo {
        var foo: Int  // foo
        var bar: Int  // bar
      }

      enum Foo {
        case foo
        case bar  // bar
        case baz  // baz
        case quux
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 100)
  }

  func testCommentOnContinuationLine() {
    let input =
      """
      func foo() {
        return true
          // comment
          && false
      }

      func foo() {
        return
          // comment
          false
      }

      struct Foo {
        typealias Bar =
          // comment
          SomeOtherType
      }
      """

    assertPrettyPrintEqual(input: input, expected: input + "\n", linelength: 60)
  }

  func testLineCommentAtEndOfMemberDeclList() {
    let input =
      """
      enum Foo {
        case bar
          // This should be indented the same as the previous line
      }
      """

    let expected =
      """
      enum Foo {
        case bar
        // This should be indented the same as the previous line
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 100)
  }

  func testCommentsAroundIfElseStatements() {
    let input =
      """
      if foo {
      }// Comment about else-if
      else // comment about else
      if bar {
      }
      // another comment
      else
      {
      }
      """

    let expected =
      """
      if foo {
      }  // Comment about else-if
      else  // comment about else
      if bar {
      }
      // another comment
      else {
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 100)
  }

  func testCommentsMoveAroundOperators() {
    let input =
      """
      let x = a +  // comment about b
        b
      let x =  // comment about RHS
        a + b + c
      x = a + b +
      // comment about c
      c
      x = a + /* block */
      // line 2
      b
      x = a + // comment 1

      // comment 2

      b
      """

    let expected =
      """
      let x =
        a  // comment about b
        + b
      let x =  // comment about RHS
        a + b + c
      x =
        a + b
        // comment about c
        + c
      x =
        a
        // line 2
        + /* block */ b
      x =
        a  // comment 1

        // comment 2

        + b

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 100)
  }

  func testCommentsAllowedInParenthesizedExpressions() {
    // There is no group applied outside of single element tuples that don't contain sequence
    // expressions, hence the examples with a tuple wrapping `foo()` and a tuple wrapping a
    // multiline string don't break before the left paren.
    let input =
      #"""
      let x = (// call foo
        foo())
      x = (// do some addition
        x + y)
      x = (
        // localize this string?
        // second line of comment
        // third line of comment
        """
        This is a multiline string inside of a multiline
        string!
        """)
      """#

    let expected =
      #"""
      let x = (  // call foo
        foo())
      x =
        (  // do some addition
          x + y)
      x = (
        // localize this string?
        // second line of comment
        // third line of comment
        """
        This is a multiline string inside of a multiline
        string!
        """)

      """#

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 100)
  }

  func testOperatorOnNewLineWithTrailingLineComment() {
    let input =
      """
      if next
        && // final is important
        // second line about final
        final
      {
      }
      """

    let expected =
      """
      if next
        // final is important
        // second line about final
        && final
      {
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 100)
  }

  func testOperatorOnSameLineWithTrailingLineComment() {
    let input =
      """
      if next && // final is important
        // second line about final
        final
      {
      }
      """

    let expected =
      """
      if next  // final is important
        // second line about final
        && final
      {
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 100)
  }

  func testCommentsInIfStatements() {
    let input =
      """
      if foo.bar && false && // comment about foo.bar
        baz && // comment about baz
        // comment about next
        next
        && // other is important
        // second line about other
        other &&
        // comment about final on a new line
        final
      {
      }
      if foo.bar && foo.baz
        && // comment about the next line
        // another comment line
        next.line
      {
      }
      """

    let expected =
      """
      if foo.bar && false  // comment about foo.bar
        && baz  // comment about baz
        // comment about next
        && next
        // other is important
        // second line about other
        && other
        // comment about final on a new line
        && final
      {
      }
      if foo.bar && foo.baz
        // comment about the next line
        // another comment line
        && next.line
      {
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 100)
  }

  func testTrailingSpacesInComments() {
    // Xcode has a commonly enabled setting to delete trailing spaces, which also applies to
    // multi-line strings. The trailing spaces are intentionally written using a unicode escape
    // sequence to ensure they aren't deleted.
    let input = """
      /// This is a trailing space documentation comment.\u{0020}\u{0020}\u{0020}\u{0020}\u{0020}
      ///        This is a leading space documentation comment.
      func foo() {
        //       leading spaces are fine
        // trailing spaces should go\u{0020}\u{0020}\u{0020}\u{0020}\u{0020}
        let out = "123"
      }

      /**
       *    This is a leading space doc block comment
       * This is a trailing space doc block comment\u{0020}\u{0020}\u{0020}\u{0020}\u{0020}
       */
      func foo() {
        /*    block comment    */ let out = "123"
      }
      """

    let expected = """
      /// This is a trailing space documentation comment.
      ///        This is a leading space documentation comment.
      func foo() {
        //       leading spaces are fine
        // trailing spaces should go
        let out = "123"
      }

      /**
       *    This is a leading space doc block comment
       * This is a trailing space doc block comment
       */
      func foo() {
        /*    block comment    */ let out = "123"
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 60)
  }

  func testDiagnoseMoveEndOfLineComment() {
    assertPrettyPrintEqual(
      input: """
        import veryveryverylongmodulenameherebecauseitistypical  // special sentinel comment

        func fooBarBazRunningOutOfIdeas() {  1️⃣// comment that needs to move
          if foo {  // comment is fine
          }
        }

        """,
      expected: """
        import veryveryverylongmodulenameherebecauseitistypical  // special sentinel comment

        func fooBarBazRunningOutOfIdeas() {  // comment that needs to move
          if foo {  // comment is fine
          }
        }

        """,
      linelength: 45,
      whitespaceOnly: true,
      findings: [
        FindingSpec("1️⃣", message: "move end-of-line comment that exceeds the line length")
      ]
    )
  }

  // Tests that "end of line" comments are flagged only when they exceed the configured line length.
  func testDiagnoseMoveEndOfLineCommentAroundBoundary() {
    assertPrettyPrintEqual(
      input: """
        x  // 789
        x  // 7890
        x  1️⃣// 78901

        """,
      expected: """
        x  // 789
        x  // 7890
        x  // 78901

        """,
      linelength: 10,
      whitespaceOnly: true,
      findings: [
        FindingSpec("1️⃣", message: "move end-of-line comment that exceeds the line length")
      ]
    )
  }

  func testLineWithDocLineComment() {
    // none of these should be merged if/when there is comment formatting
    let input =
      """
      /// Doc line comment
      // Line comment
      /// Doc line comment
      // Line comment

      // Another line comment

      """
    assertPrettyPrintEqual(input: input, expected: input, linelength: 80)
  }

  func testNonmergeableComments() {
    // none of these should be merged if/when there is comment formatting
    let input =
      """
      let x = 1  // end of line comment
      //

      let y =  // eol comment
        1  // another
        + 2  // and another

      """

    assertPrettyPrintEqual(input: input, expected: input, linelength: 80)
  }

  func testMergeableComments() {
    // these examples should be merged and formatted if/when there is comment formatting
    let input =
      """
      let z =
        // one comment
        // and another comment
        1 + 2

      let w = [1, 2, 3]
        .foo()
        // this comment
        // could be merged with this one
        .bar()

      """

    assertPrettyPrintEqual(input: input, expected: input, linelength: 80)
  }

  func testUnexpectedUnicodeCharacters() {
    let input =
      """
      // Hello World\u{2028}
      // Hello\u{20}\u{2028}World
      // Hello World\u{2028}\u{2029}\u{2029}
      // Hello World\u{20}\u{20}\u{20}\u{2028}

      """

    assertPrettyPrintEqual(input: input, expected: input, linelength: 80)
  }

  func testReflowLineCommentsOnlyLinesOverLength() {
    let input =
      """
      // Short single-line comment stays as-is.

      // This is a single-line comment that is much longer than the configured line length and must be wrapped.

      // This is a multi-line comment
      // where short lines should not be
      // joined together.
      //
      // In this paragraph, the first line is much longer than the configured line length and wraps
      // while this second line stays on its own line.

      func foo() {
        // Inside an indented scope, the available width is smaller so this comment wraps earlier than at top level.
        let x = 1
      }
      """

    let expected =
      """
      // Short single-line comment stays as-is.

      // This is a single-line comment that is much
      // longer than the configured line length and must
      // be wrapped.

      // This is a multi-line comment
      // where short lines should not be
      // joined together.
      //
      // In this paragraph, the first line is much
      // longer than the configured line length and
      // wraps
      // while this second line stays on its own line.

      func foo() {
        // Inside an indented scope, the available width
        // is smaller so this comment wraps earlier than
        // at top level.
        let x = 1
      }

      """

    var config = Configuration.forTesting
    config.reflowComments.regularComments = .onlyLinesOverLength
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 50, configuration: config)
  }

  func testReflowLineCommentsAlways() {
    let input =
      """
      // Short single-line comment stays as-is.

      // This is a single-line comment that is much longer than the configured line length and must be wrapped.

      // This is a multi-line comment
      // where short lines should be
      // joined together and reflowed
      // to fit the line width.
      //
      // And this is a second paragraph
      // in the same comment block.

      func foo() {
        // Inside an indented scope, the available width is smaller so this comment wraps earlier than at top level.
        let x = 1
      }
      """

    let expected =
      """
      // Short single-line comment stays as-is.

      // This is a single-line comment that is much
      // longer than the configured line length and must
      // be wrapped.

      // This is a multi-line comment where short lines
      // should be joined together and reflowed to fit
      // the line width.
      //
      // And this is a second paragraph in the same
      // comment block.

      func foo() {
        // Inside an indented scope, the available width
        // is smaller so this comment wraps earlier than
        // at top level.
        let x = 1
      }

      """

    var config = Configuration.forTesting
    config.reflowComments.regularComments = .always
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 50, configuration: config)
  }

  func testReflowDocLineCommentsWithMarkdownConstructs() {
    let input =
      """
      /// A brief summary that is quite long and should be wrapped across multiple lines cleanly.
      ///
      /// This is a multi-line paragraph
      /// where short lines are joined
      /// together and reflowed.
      ///
      /// Here is a detailed discussion with *italic*, _also italic_, **bold**, __also bold__,
      /// ~~strikethrough~~, `inlineCode(x: 1, y: 2)`, ``SymbolLink``, [a link](https://swift.org),
      /// and <https://swift.org>.
      ///
      /// Hard line breaks with a trailing backslash\\
      /// are preserved on their own line.
      ///
      /// # Heading 1
      ///
      /// > A blockquote paragraph that is fairly long and should be wrapped while keeping the
      /// > leading blockquote marker on each line.
      /// >
      /// > Second paragraph in the blockquote.
      ///
      /// - Parameters:
      ///   - param1: A very long parameter description that wraps onto the next line with proper
      ///     4-space list continuation indentation.
      ///   - param2: Short description.
      /// - Returns: A very long return value description that also wraps onto the next line with
      ///   2-space list continuation indentation.
      ///
      /// 1. First ordered list item that is long enough to wrap onto a second line with 3-space
      ///    continuation indentation.
      /// 2. Second ordered list item.
      ///
      /// ```swift
      /// let veryLongCodeLineInFencedBlock = "This line exceeds 50 columns but must NOT be wrapped!"
      /// ```
      ///
      ///     let veryLongCodeLineInIndentedBlock = "This indented code block must NOT be wrapped!"
      func documentedFunction(param1: Int, param2: String) -> Bool {
        return true
      }
      """

    let expected =
      """
      /// A brief summary that is quite long and should
      /// be wrapped across multiple lines cleanly.
      ///
      /// This is a multi-line paragraph where short
      /// lines are joined together and reflowed.
      ///
      /// Here is a detailed discussion with *italic*,
      /// _also italic_, **bold**, __also bold__,
      /// ~~strikethrough~~, `inlineCode(x: 1, y: 2)`,
      /// ``SymbolLink``, [a link](https://swift.org),
      /// and <https://swift.org>.
      ///
      /// Hard line breaks with a trailing backslash\\
      /// are preserved on their own line.
      ///
      /// # Heading 1
      ///
      /// > A blockquote paragraph that is fairly long
      /// > and should be wrapped while keeping the
      /// > leading blockquote marker on each line.
      /// >
      /// > Second paragraph in the blockquote.
      ///
      /// - Parameters:
      ///   - param1: A very long parameter description
      ///     that wraps onto the next line with proper
      ///     4-space list continuation indentation.
      ///   - param2: Short description.
      /// - Returns: A very long return value
      ///   description that also wraps onto the next
      ///   line with 2-space list continuation
      ///   indentation.
      ///
      /// 1. First ordered list item that is long enough
      ///    to wrap onto a second line with 3-space
      ///    continuation indentation.
      /// 2. Second ordered list item.
      ///
      /// ```swift
      /// let veryLongCodeLineInFencedBlock = "This line exceeds 50 columns but must NOT be wrapped!"
      /// ```
      ///
      ///     let veryLongCodeLineInIndentedBlock = "This indented code block must NOT be wrapped!"
      func documentedFunction(
        param1: Int, param2: String
      ) -> Bool {
        return true
      }

      """

    var config = Configuration.forTesting
    config.reflowComments.docComments = .always
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 50, configuration: config)
  }

  func testReflowBlockComments() {
    let input =
      """
      /* Short block comment */

      /* This is a single-line block comment that exceeds the line length and wraps. */

      /* Short line 1
         Short line 2 */

      /*
        This block comment has delimiters on their own lines
        and a short second line.
      */

      /*
       * This block comment uses ASCII art asterisks on each
       * interior line and should preserve them
       * when reflowed.
       *
       * Second paragraph.
       */
      let x = 1
      """

    let expectedOnlyLinesOverLength =
      """
      /* Short block comment */

      /* This is a single-line block comment
         that exceeds the line length and
         wraps. */

      /* Short line 1
         Short line 2 */

      /*
        This block comment has delimiters on
        their own lines
        and a short second line.
      */

      /*
       * This block comment uses ASCII art
       * asterisks on each
       * interior line and should preserve
       * them
       * when reflowed.
       *
       * Second paragraph.
       */
      let x = 1

      """

    var config = Configuration.forTesting
    config.reflowComments.regularComments = .onlyLinesOverLength
    assertPrettyPrintEqual(
      input: input,
      expected: expectedOnlyLinesOverLength,
      linelength: 40,
      configuration: config
    )

    let expectedAlways =
      """
      /* Short block comment */

      /* This is a single-line block comment
         that exceeds the line length and
         wraps. */

      /* Short line 1 Short line 2 */

      /*
        This block comment has delimiters on
        their own lines and a short second
        line.
      */

      /*
       * This block comment uses ASCII art
       * asterisks on each interior line and
       * should preserve them when reflowed.
       *
       * Second paragraph.
       */
      let x = 1

      """

    config.reflowComments.regularComments = .always
    assertPrettyPrintEqual(
      input: input,
      expected: expectedAlways,
      linelength: 40,
      configuration: config
    )
  }

  func testReflowDocBlockComments() {
    let input =
      """
      /** A short doc block comment **/

      /** This single-line doc block comment is too long and must wrap onto multiple lines. **/

      /** This is a documentation comment
       * that has text on the first line
       *
       * - Parameters:
       *   - param1: A long parameter description that needs to wrap onto the next line.
       * - Returns: The output
      **/
      func myfun(param1: Int) -> String {
        return ""
      }
      """

    let expected =
      """
      /** A short doc block comment **/

      /** This single-line doc block comment is too
          long and must wrap onto multiple
          lines. **/

      /** This is a documentation comment that has
       * text on the first line
       *
       * - Parameters:
       *   - param1: A long parameter description
       *     that needs to wrap onto the next line.
       * - Returns: The output
      **/
      func myfun(param1: Int) -> String {
        return ""
      }

      """

    var config = Configuration.forTesting
    config.reflowComments.docComments = .always
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 45, configuration: config)
  }

  func testReflowCommentsPreservesBannerAndExcludesEndOfLineComments() {
    let input =
      """
      //===----------------------------------------------------------------------===//
      //
      // This source file is part of the Swift.org open source project
      //
      //===----------------------------------------------------------------------===//

      /*===----------------------------------------------------------------------===*/

      /// Doc line comment
      // Line comment
      /// Doc line comment
      // Line comment

      let x = 1  // This is a very long end-of-line comment that exceeds the line length
      // and this standalone line comment should not be merged with the end-of-line comment above.

      let z =
        // one comment
        // and another comment
        1 + 2

      let w =
        /// one doc comment
        /// and another doc comment
        1 + 2
      """

    let expected =
      """
      //===----------------------------------------------------------------------===//
      //
      // This source file is part of the Swift.org
      // open source project
      //
      //===----------------------------------------------------------------------===//

      /*===----------------------------------------------------------------------===*/

      /// Doc line comment
      // Line comment
      /// Doc line comment
      // Line comment

      let x = 1  // This is a very long end-of-line comment that exceeds the line length
      // and this standalone line comment should not
      // be merged with the end-of-line comment above.

      let z =
        // one comment
        // and another comment
        1 + 2

      let w =
        /// one doc comment and another doc comment
        1 + 2

      """

    var config = Configuration.forTesting
    config.reflowComments.regularComments = .onlyLinesOverLength
    config.reflowComments.docComments = .always
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 48, configuration: config)
  }

  func testDiagnoseReflowComment() {
    var config = Configuration.forTesting
    config.reflowComments.regularComments = .onlyLinesOverLength
    config.reflowComments.docComments = .always
    assertPrettyPrintEqual(
      input: """
        // This comment fits.

        // Short regular line 1
        // Short regular line 2

        1️⃣// This single-line comment is too long for the line.

        func foo() {
          2️⃣/// Short doc line 1
          /// Short doc line 2
          let x = 1
        }

        """,
      expected: """
        // This comment fits.

        // Short regular line 1
        // Short regular line 2

        // This single-line comment is too long for the line.

        func foo() {
          /// Short doc line 1
          /// Short doc line 2
          let x = 1
        }

        """,
      linelength: 40,
      configuration: config,
      whitespaceOnly: true,
      findings: [
        FindingSpec("1️⃣", message: "reflow comment"),
        FindingSpec("2️⃣", message: "reflow comment"),
      ]
    )
  }

  func testReflowBlockCommentClosingDelimiterBoundaryAndBlankLineIndentation() {
    // At lineLength = 25, "/* Hello world friendss" is 23 chars (fits in 25),
    // but adding " */" makes it 26 chars (> 25), so "friendss" must wrap.
    let input =
      """
      /* Hello world
         friendss */

      func foo() {
        /*
          First paragraph in indented block comment.

          Second paragraph in indented block comment.
        */
        let x = 1
      }
      """

    let expectedNoBlankIndent =
      """
      /* Hello world
         friendss */

      func foo() {
        /*
          First paragraph in
          indented block
          comment.

          Second paragraph in
          indented block
          comment.
        */
        let x = 1
      }

      """

    var config = Configuration.forTesting
    config.reflowComments.regularComments = .always
    config.indentBlankLines = false
    assertPrettyPrintEqual(
      input: input,
      expected: expectedNoBlankIndent,
      linelength: 25,
      configuration: config
    )

    let expectedWithBlankIndent =
      """
      /* Hello world
         friendss */

      func foo() {
        /*
          First paragraph in
          indented block
          comment.
      \("  ")
          Second paragraph in
          indented block
          comment.
        */
        let x = 1
      }

      """

    config.indentBlankLines = true
    assertPrettyPrintEqual(
      input: input,
      expected: expectedWithBlankIndent,
      linelength: 25,
      configuration: config
    )
  }

  func testReflowTaskListsAndLooseLists() {
    let input =
      """
      /// - [ ] An unchecked task list item that is long enough to wrap onto the next line.
      /// - [x] A checked task list item that is also long enough to wrap onto the next line.
      /// -   [ ] A task list item with extra spaces after the bullet and before the checkbox.
      /// - [x]   A task list item with extra spaces after the checkbox that also wraps.
      ///
      /// * First loose list item that is long enough to wrap onto a second line.
      ///
      /// *   Second loose list item with three spaces after the bullet that wraps.
      ///
      /// *  Third loose list item with two spaces after the bullet that wraps.
      ///
      /// 1.   First ordered list item with three spaces after the marker that wraps.
      /// 2.  Second ordered list item with two spaces after the marker that wraps.
      let x = 1
      """

    let expected =
      """
      /// - [ ] An unchecked task list item that is long
      ///       enough to wrap onto the next line.
      /// - [x] A checked task list item that is also
      ///       long enough to wrap onto the next line.
      /// -   [ ] A task list item with extra spaces
      ///         after the bullet and before the
      ///         checkbox.
      /// - [x]   A task list item with extra spaces
      ///         after the checkbox that also wraps.
      ///
      /// * First loose list item that is long enough to
      ///   wrap onto a second line.
      ///
      /// *   Second loose list item with three spaces
      ///     after the bullet that wraps.
      ///
      /// *  Third loose list item with two spaces after
      ///    the bullet that wraps.
      ///
      /// 1.   First ordered list item with three spaces
      ///      after the marker that wraps.
      /// 2.  Second ordered list item with two spaces
      ///     after the marker that wraps.
      let x = 1

      """

    var config = Configuration.forTesting
    config.reflowComments.docComments = .always
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 50, configuration: config)
  }

  func testReflowCommentPragmas() {
    let input =
      """
      // swift-format-ignore-file: AlwaysUseLowerCamelCase, NeverUseImplicitlyUnwrappedOptionals

      // This comment explains why we ignore the rule below
      // and should be reflowed without merging the directive.
      // swift-format-ignore: AlwaysUseLowerCamelCase, NeverUseForceTry
      let Bad_Name = 1

      // Short line before pragma
      // that gets merged with this line.
      // @CustomPragma(my_section_label_that_is_very_long)
      let a = 1
      // @CustomPragma(
      //   Sources/ModuleA/FirstFile.swift:label_one,
      //   Sources/ModuleB/SecondFile.swift:label_two
      // )
      // Short line after pragma
      // that also gets merged.
      let b = 2

      // @CustomPragma(Sources/Single/Line/Very/Long/Path/One.swift, Sources/Single/Line/Very/Long/Path/Two.swift)
      let c = 3

      /*
       * Introductory line in a block comment
       * that gets reflowed.
       * @CustomPragma(
       *   Sources/Block/FirstFile.swift,
       *   Sources/Block/SecondFile.swift
       * )
       * Trailing line in a block comment
       * that also gets reflowed.
       */
      let d = 4
      """

    let expected =
      """
      // swift-format-ignore-file: AlwaysUseLowerCamelCase, NeverUseImplicitlyUnwrappedOptionals

      // This comment explains why we ignore the rule
      // below and should be reflowed without merging
      // the directive.
      // swift-format-ignore: AlwaysUseLowerCamelCase, NeverUseForceTry
      let Bad_Name = 1

      // Short line before pragma that gets merged with
      // this line.
      // @CustomPragma(my_section_label_that_is_very_long)
      let a = 1
      // @CustomPragma(
      //   Sources/ModuleA/FirstFile.swift:label_one,
      //   Sources/ModuleB/SecondFile.swift:label_two
      // )
      // Short line after pragma that also gets merged.
      let b = 2

      // @CustomPragma(Sources/Single/Line/Very/Long/Path/One.swift, Sources/Single/Line/Very/Long/Path/Two.swift)
      let c = 3

      /*
       * Introductory line in a block comment that gets
       * reflowed.
       * @CustomPragma(
       *   Sources/Block/FirstFile.swift,
       *   Sources/Block/SecondFile.swift
       * )
       * Trailing line in a block comment that also gets
       * reflowed.
       */
      let d = 4

      """

    var config = Configuration.forTesting
    config.reflowComments.regularComments = .always
    config.reflowComments.commentPragmas = [
      #"^\s*@CustomPragma(\([^)]*\))?"#
    ]
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 50, configuration: config)
  }

  func testReflowCommentsIndentedCodeBlockDoesNotDuplicateBlankLine() {
    let input =
      """
      //     let x = 1
      //     let y = 2
      //
      // A paragraph after the indented code block
      // that gets merged onto fewer lines.
      let a = 1
      """

    let expected =
      """
      //     let x = 1
      //     let y = 2
      //
      // A paragraph after the indented code block that
      // gets merged onto fewer lines.
      let a = 1

      """

    var config = Configuration.forTesting
    config.reflowComments.regularComments = .always
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 50, configuration: config)
  }

  func testReflowBlockCommentWithTabAfterStarAndClosingDelimiterOverflow() {
    let input =
      """
      /*
       *\tFirst line after star-tab that should be
       *\tmerged with the second line as normal prose.
       */
      let a = 1

      /*
       * Introductory line that gets merged
       * with this line.
       * ### A heading that fills the 50-col line here */
      let b = 2
      """

    let expected =
      """
      /*
       * First line after star-tab that should be merged
       * with the second line as normal prose.
       */
      let a = 1

      /*
       * Introductory line that gets merged with this
       * line.
       * ### A heading that fills the 50-col line here
       */
      let b = 2

      """

    var config = Configuration.forTesting
    config.reflowComments.regularComments = .always
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 50, configuration: config)
  }
}
