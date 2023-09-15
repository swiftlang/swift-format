import SwiftFormatRules

final class ReturnVoidInsteadOfEmptyTupleTests: LintOrFormatRuleTestCase {
  func testBasic() {
    XCTAssertFormatting(
      ReturnVoidInsteadOfEmptyTuple.self,
      input:
        """
        let callback: () -> ()
        typealias x = Int -> ()
        func y() -> Int -> () { return }
        func z(d: Bool -> ()) {}
        """,
      expected:
        """
        let callback: () -> Void
        typealias x = Int -> Void
        func y() -> Int -> Void { return }
        func z(d: Bool -> Void) {}
        """,
      checkForUnassertedDiagnostics: true
    )
    XCTAssertDiagnosed(.returnVoid, line: 1, column: 21)
    XCTAssertDiagnosed(.returnVoid, line: 2, column: 22)
    XCTAssertDiagnosed(.returnVoid, line: 3, column: 20)
    XCTAssertDiagnosed(.returnVoid, line: 4, column: 19)
  }

  func testNestedFunctionTypes() {
    XCTAssertFormatting(
      ReturnVoidInsteadOfEmptyTuple.self,
      input:
        """
        typealias Nested1 = (() -> ()) -> Int
        typealias Nested2 = (() -> ()) -> ()
        typealias Nested3 = Int -> (() -> ())
        """,
      expected:
        """
        typealias Nested1 = (() -> Void) -> Int
        typealias Nested2 = (() -> Void) -> Void
        typealias Nested3 = Int -> (() -> Void)
        """,
      checkForUnassertedDiagnostics: true
    )
    XCTAssertDiagnosed(.returnVoid, line: 1, column: 28)
    XCTAssertDiagnosed(.returnVoid, line: 2, column: 28)
    XCTAssertDiagnosed(.returnVoid, line: 2, column: 35)
    XCTAssertDiagnosed(.returnVoid, line: 3, column: 35)
  }

  func testClosureSignatures() {
    XCTAssertFormatting(
      ReturnVoidInsteadOfEmptyTuple.self,
      input:
        """
        callWithTrailingClosure(arg) { arg -> () in body }
        callWithTrailingClosure(arg) { arg -> () in
          nestedCallWithTrailingClosure(arg) { arg -> () in
            body
          }
        }
        callWithTrailingClosure(arg) { (arg: () -> ()) -> Int in body }
        callWithTrailingClosure(arg) { (arg: () -> ()) -> () in body }
        """,
      expected:
        """
        callWithTrailingClosure(arg) { arg -> Void in body }
        callWithTrailingClosure(arg) { arg -> Void in
          nestedCallWithTrailingClosure(arg) { arg -> Void in
            body
          }
        }
        callWithTrailingClosure(arg) { (arg: () -> Void) -> Int in body }
        callWithTrailingClosure(arg) { (arg: () -> Void) -> Void in body }
        """,
      checkForUnassertedDiagnostics: true
    )
    XCTAssertDiagnosed(.returnVoid, line: 1, column: 39)
    XCTAssertDiagnosed(.returnVoid, line: 2, column: 39)
    XCTAssertDiagnosed(.returnVoid, line: 3, column: 47)
    XCTAssertDiagnosed(.returnVoid, line: 7, column: 44)
    XCTAssertDiagnosed(.returnVoid, line: 8, column: 44)
    XCTAssertDiagnosed(.returnVoid, line: 8, column: 51)
  }

  func testTriviaPreservation() {
    XCTAssertFormatting(
      ReturnVoidInsteadOfEmptyTuple.self,
      input:
        """
        let callback: () -> /*foo*/()/*bar*/
        let callback: ((Int) ->   /*foo*/   ()   /*bar*/) -> ()
        """,
      expected:
        """
        let callback: () -> /*foo*/Void/*bar*/
        let callback: ((Int) ->   /*foo*/   Void   /*bar*/) -> Void
        """,
      checkForUnassertedDiagnostics: true
    )
    XCTAssertDiagnosed(.returnVoid, line: 1, column: 28)
    XCTAssertDiagnosed(.returnVoid, line: 2, column: 37)
    XCTAssertDiagnosed(.returnVoid, line: 2, column: 54)
  }

  func testEmptyTupleWithInternalCommentsIsDiagnosedButNotReplaced() {
    XCTAssertFormatting(
      ReturnVoidInsteadOfEmptyTuple.self,
      input:
        """
        let callback: () -> ( )
        let callback: () -> (\t)
        let callback: () -> (
        )
        let callback: () -> ( /* please don't change me! */ )
        let callback: () -> ( /** please don't change me! */ )
        let callback: () -> (
          // don't change me either!
        )
        let callback: () -> (
          /// don't change me either!
        )
        let callback: () -> (\u{feff})

        let callback: (() -> ()) -> ( /* please don't change me! */ )
        callWithTrailingClosure(arg) { (arg: () -> ()) -> ( /* no change */ ) in body }
        """,
      expected:
        """
        let callback: () -> Void
        let callback: () -> Void
        let callback: () -> Void
        let callback: () -> ( /* please don't change me! */ )
        let callback: () -> ( /** please don't change me! */ )
        let callback: () -> (
          // don't change me either!
        )
        let callback: () -> (
          /// don't change me either!
        )
        let callback: () -> (\u{feff})

        let callback: (() -> Void) -> ( /* please don't change me! */ )
        callWithTrailingClosure(arg) { (arg: () -> Void) -> ( /* no change */ ) in body }
        """,
      checkForUnassertedDiagnostics: true
    )
    XCTAssertDiagnosed(.returnVoid, line: 1, column: 21)
    XCTAssertDiagnosed(.returnVoid, line: 2, column: 21)
    XCTAssertDiagnosed(.returnVoid, line: 3, column: 21)
    XCTAssertDiagnosed(.returnVoid, line: 5, column: 21)
    XCTAssertDiagnosed(.returnVoid, line: 6, column: 21)
    XCTAssertDiagnosed(.returnVoid, line: 7, column: 21)
    XCTAssertDiagnosed(.returnVoid, line: 10, column: 21)
    XCTAssertDiagnosed(.returnVoid, line: 13, column: 21)
    XCTAssertDiagnosed(.returnVoid, line: 15, column: 22)
    XCTAssertDiagnosed(.returnVoid, line: 15, column: 29)
    XCTAssertDiagnosed(.returnVoid, line: 16, column: 44)
    XCTAssertDiagnosed(.returnVoid, line: 16, column: 51)
  }
}
