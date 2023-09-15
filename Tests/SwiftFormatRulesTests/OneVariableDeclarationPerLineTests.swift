import SwiftFormatRules

final class OneVariableDeclarationPerLineTests: LintOrFormatRuleTestCase {
  func testMultipleVariableBindings() {
    XCTAssertFormatting(
      OneVariableDeclarationPerLine.self,
      input:
        """
        var a = 0, b = 2, (c, d) = (0, "h")
        let e = 0, f = 2, (g, h) = (0, "h")
        var x: Int { return 3 }
        let a, b, c: Int
        var j: Int, k: String, l: Float
        """,
      expected:
        """
        var a = 0
        var b = 2
        var (c, d) = (0, "h")
        let e = 0
        let f = 2
        let (g, h) = (0, "h")
        var x: Int { return 3 }
        let a: Int
        let b: Int
        let c: Int
        var j: Int
        var k: String
        var l: Float
        """,
      checkForUnassertedDiagnostics: true
    )
    XCTAssertDiagnosed(.onlyOneVariableDeclaration, line: 1, column: 1)
    XCTAssertDiagnosed(.onlyOneVariableDeclaration, line: 2, column: 1)
    XCTAssertDiagnosed(.onlyOneVariableDeclaration, line: 4, column: 1)
    XCTAssertDiagnosed(.onlyOneVariableDeclaration, line: 5, column: 1)
  }

  func testNestedVariableBindings() {
    XCTAssertFormatting(
      OneVariableDeclarationPerLine.self,
      input:
        """
        var x: Int = {
          let y = 5, z = 10
          return z
        }()

        func foo() {
          let x = 4, y = 10
        }

        var x: Int {
          let y = 5, z = 10
          return z
        }

        var a: String = "foo" {
          didSet {
            let b, c: Bool
          }
        }

        let
          a: Int = {
            let p = 10, q = 20
            return p * q
          }(),
          b: Int = {
            var s: Int, t: Double
            return 20
          }()
        """,
      expected:
        """
        var x: Int = {
          let y = 5
        let z = 10
          return z
        }()

        func foo() {
          let x = 4
        let y = 10
        }

        var x: Int {
          let y = 5
        let z = 10
          return z
        }

        var a: String = "foo" {
          didSet {
            let b: Bool
        let c: Bool
          }
        }

        let
          a: Int = {
            let p = 10
        let q = 20
            return p * q
          }()
        let
          b: Int = {
            var s: Int
        var t: Double
            return 20
          }()
        """,
      checkForUnassertedDiagnostics: true
    )
    XCTAssertDiagnosed(.onlyOneVariableDeclaration, line: 2, column: 3)
    XCTAssertDiagnosed(.onlyOneVariableDeclaration, line: 7, column: 3)
    XCTAssertDiagnosed(.onlyOneVariableDeclaration, line: 11, column: 3)
    XCTAssertDiagnosed(.onlyOneVariableDeclaration, line: 17, column: 5)
    XCTAssertDiagnosed(.onlyOneVariableDeclaration, line: 21, column: 1)
    XCTAssertDiagnosed(.onlyOneVariableDeclaration, line: 23, column: 5)
    XCTAssertDiagnosed(.onlyOneVariableDeclaration, line: 27, column: 5)
  }

  func testMixedInitializedAndTypedBindings() {
    XCTAssertFormatting(
      OneVariableDeclarationPerLine.self,
      input:
        """
        var a = 5, b: String
        let c: Int, d = "d", e = "e", f: Double
        """,
      expected:
        """
        var a = 5
        var b: String
        let c: Int
        let d = "d"
        let e = "e"
        let f: Double
        """,
      checkForUnassertedDiagnostics: true
    )
    XCTAssertDiagnosed(.onlyOneVariableDeclaration, line: 1, column: 1)
    XCTAssertDiagnosed(.onlyOneVariableDeclaration, line: 2, column: 1)
  }

  func testCommentPrecedingDeclIsNotRepeated() {
    XCTAssertFormatting(
      OneVariableDeclarationPerLine.self,
      input:
        """
        // Comment
        let a, b, c: Int
        """,
      expected:
        """
        // Comment
        let a: Int
        let b: Int
        let c: Int
        """,
      checkForUnassertedDiagnostics: true
    )
    XCTAssertDiagnosed(.onlyOneVariableDeclaration, line: 2, column: 1)
  }

  func testCommentsPrecedingBindingsAreKept() {
    XCTAssertFormatting(
      OneVariableDeclarationPerLine.self,
      input:
        """
        let /* a */ a, /* b */ b, /* c */ c: Int
        """,
      expected:
        """
        let /* a */ a: Int
        let /* b */ b: Int
        let /* c */ c: Int
        """,
      checkForUnassertedDiagnostics: true
    )
    XCTAssertDiagnosed(.onlyOneVariableDeclaration, line: 1, column: 1)
  }

  func testInvalidBindingsAreNotDestroyed() {
    XCTAssertFormatting(
      OneVariableDeclarationPerLine.self,
      input:
        """
        let a, b, c = 5
        let d, e
        let f, g, h: Int = 5
        let a: Int, b, c = 5, d, e: Int
        """,
      expected:
        """
        let a, b, c = 5
        let d, e
        let f, g, h: Int = 5
        let a: Int
        let b, c = 5
        let d: Int
        let e: Int
        """,
      checkForUnassertedDiagnostics: true
    )
    XCTAssertDiagnosed(.onlyOneVariableDeclaration, line: 1, column: 1)
    XCTAssertDiagnosed(.onlyOneVariableDeclaration, line: 2, column: 1)
    XCTAssertDiagnosed(.onlyOneVariableDeclaration, line: 3, column: 1)
    XCTAssertDiagnosed(.onlyOneVariableDeclaration, line: 4, column: 1)
  }

  func testMultipleBindingsWithAccessorsAreCorrected() {
    // Swift parses multiple bindings with accessors but forbids them at a later
    // stage. That means that if the individual bindings would be correct in
    // isolation then we can correct them, which is kind of nice.
    XCTAssertFormatting(
      OneVariableDeclarationPerLine.self,
      input:
        """
        var x: Int { return 10 }, y = "foo" { didSet { print("changed") } }
        """,
      expected:
        """
        var x: Int { return 10 }
        var y = "foo" { didSet { print("changed") } }
        """,
      checkForUnassertedDiagnostics: true
    )
    XCTAssertDiagnosed(.onlyOneVariableDeclaration, line: 1, column: 1)
  }
}
