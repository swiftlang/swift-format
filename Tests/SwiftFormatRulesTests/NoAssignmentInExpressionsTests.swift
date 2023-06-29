import SwiftFormatRules

final class NoAssignmentInExpressionsTests: LintOrFormatRuleTestCase {
  func testAssignmentInExpressionContextIsDiagnosed() {
    XCTAssertFormatting(
      NoAssignmentInExpressions.self,
      input: """
        foo(bar, baz = quux, a + b)
        """,
      expected: """
        foo(bar, baz = quux, a + b)
        """
    )
    XCTAssertDiagnosed(.moveAssignmentToOwnStatement, line: 1, column: 10)
    // Make sure no other expressions were diagnosed.
    XCTAssertNotDiagnosed(.moveAssignmentToOwnStatement)
  }

  func testReturnStatementWithoutExpressionIsUnchanged() {
    XCTAssertFormatting(
      NoAssignmentInExpressions.self,
      input: """
        func foo() {
          return
        }
        """,
      expected: """
        func foo() {
          return
        }
        """
    )
    XCTAssertNotDiagnosed(.moveAssignmentToOwnStatement)
  }

  func testReturnStatementWithNonAssignmentExpressionIsUnchanged() {
    XCTAssertFormatting(
      NoAssignmentInExpressions.self,
      input: """
        func foo() {
          return a + b
        }
        """,
      expected: """
        func foo() {
          return a + b
        }
        """
    )
    XCTAssertNotDiagnosed(.moveAssignmentToOwnStatement)
  }

  func testReturnStatementWithSimpleAssignmentExpressionIsExpanded() {
    // For this and similar tests below, we don't try to match the leading indentation in the new
    // `return` statement; the pretty-printer will fix it up.
    XCTAssertFormatting(
      NoAssignmentInExpressions.self,
      input: """
        func foo() {
          return a = b
        }
        """,
      expected: """
        func foo() {
          a = b
        return
        }
        """
    )
    XCTAssertDiagnosed(.moveAssignmentToOwnStatement, line: 2, column: 10)
  }

  func testReturnStatementWithCompoundAssignmentExpressionIsExpanded() {
    XCTAssertFormatting(
      NoAssignmentInExpressions.self,
      input: """
        func foo() {
          return a += b
        }
        """,
      expected: """
        func foo() {
          a += b
        return
        }
        """
    )
    XCTAssertDiagnosed(.moveAssignmentToOwnStatement, line: 2, column: 10)
  }

  func testReturnStatementWithAssignmentDealsWithLeadingLineCommentSensibly() {
    XCTAssertFormatting(
      NoAssignmentInExpressions.self,
      input: """
        func foo() {
          // some comment
          return a = b
        }
        """,
      expected: """
        func foo() {
          // some comment
          a = b
        return
        }
        """
    )
    XCTAssertDiagnosed(.moveAssignmentToOwnStatement, line: 3, column: 10)
  }

  func testReturnStatementWithAssignmentDealsWithTrailingLineCommentSensibly() {
    XCTAssertFormatting(
      NoAssignmentInExpressions.self,
      input: """
        func foo() {
          return a = b  // some comment
        }
        """,
      expected: """
        func foo() {
          a = b
        return  // some comment
        }
        """
    )
    XCTAssertDiagnosed(.moveAssignmentToOwnStatement, line: 2, column: 10)
  }

  func testReturnStatementWithAssignmentDealsWithTrailingBlockCommentSensibly() {
    XCTAssertFormatting(
      NoAssignmentInExpressions.self,
      input: """
        func foo() {
          return a = b  /* some comment */
        }
        """,
      expected: """
        func foo() {
          a = b
        return  /* some comment */
        }
        """
    )
    XCTAssertDiagnosed(.moveAssignmentToOwnStatement, line: 2, column: 10)
  }

  func testReturnStatementWithAssignmentDealsWithNestedBlockCommentSensibly() {
    XCTAssertFormatting(
      NoAssignmentInExpressions.self,
      input: """
        func foo() {
          return /* some comment */ a = b
        }
        """,
      expected: """
        func foo() {
          /* some comment */ a = b
        return
        }
        """
    )
    XCTAssertDiagnosed(.moveAssignmentToOwnStatement, line: 2, column: 29)
  }

  func testTryAndAwaitAssignmentExpressionsAreUnchanged() {
    XCTAssertFormatting(
      NoAssignmentInExpressions.self,
      input: """
        func foo() {
          try a.b = c
          await a.b = c
        }
        """,
      expected: """
        func foo() {
          try a.b = c
          await a.b = c
        }
        """
    )
    XCTAssertNotDiagnosed(.moveAssignmentToOwnStatement)
  }

  func testAssignmentExpressionsInAllowedFunctions() {
    XCTAssertFormatting(
      NoAssignmentInExpressions.self,
      input: """
        // These should not diagnose.
        XCTAssertNoThrow(a = try b())
        XCTAssertNoThrow { a = try b() }
        XCTAssertNoThrow({ a = try b() })
        someRegularFunction({ a = b })
        someRegularFunction { a = b }

        // This should be diagnosed.
        someRegularFunction(a = b)
        """,
      expected: """
        // These should not diagnose.
        XCTAssertNoThrow(a = try b())
        XCTAssertNoThrow { a = try b() }
        XCTAssertNoThrow({ a = try b() })
        someRegularFunction({ a = b })
        someRegularFunction { a = b }

        // This should be diagnosed.
        someRegularFunction(a = b)
        """
    )
    XCTAssertDiagnosed(.moveAssignmentToOwnStatement, line: 9, column: 21)
    // Make sure no other expressions were diagnosed.
    XCTAssertNotDiagnosed(.moveAssignmentToOwnStatement)
  }
}
