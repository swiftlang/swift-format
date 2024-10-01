@_spi(Rules) import SwiftFormat
import _SwiftFormatTestSupport

final class OneVariableDeclarationPerLineTests: LintOrFormatRuleTestCase {
  func testMultipleVariableBindings() {
    assertFormatting(
      OneVariableDeclarationPerLine.self,
      input: """
        1️⃣var a = 0, b = 2, (c, d) = (0, "h")
        2️⃣let e = 0, f = 2, (g, h) = (0, "h")
        var x: Int { return 3 }
        3️⃣let a, b, c: Int
        4️⃣var j: Int, k: String, l: Float
        """,
      expected: """
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
      findings: [
        FindingSpec("1️⃣", message: "split this variable declaration to introduce only one variable per 'var'"),
        FindingSpec("2️⃣", message: "split this variable declaration to introduce only one variable per 'let'"),
        FindingSpec("3️⃣", message: "split this variable declaration to introduce only one variable per 'let'"),
        FindingSpec("4️⃣", message: "split this variable declaration to introduce only one variable per 'var'"),
      ]
    )
  }

  func testNestedVariableBindings() {
    assertFormatting(
      OneVariableDeclarationPerLine.self,
      input: """
        var x: Int = {
          1️⃣let y = 5, z = 10
          return z
        }()

        func foo() {
          2️⃣let x = 4, y = 10
        }

        var x: Int {
          3️⃣let y = 5, z = 10
          return z
        }

        var a: String = "foo" {
          didSet {
            4️⃣let b, c: Bool
          }
        }

        5️⃣let
          a: Int = {
            6️⃣let p = 10, q = 20
            return p * q
          }(),
          b: Int = {
            7️⃣var s: Int, t: Double
            return 20
          }()
        """,
      expected: """
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
      findings: [
        FindingSpec("1️⃣", message: "split this variable declaration to introduce only one variable per 'let'"),
        FindingSpec("2️⃣", message: "split this variable declaration to introduce only one variable per 'let'"),
        FindingSpec("3️⃣", message: "split this variable declaration to introduce only one variable per 'let'"),
        FindingSpec("4️⃣", message: "split this variable declaration to introduce only one variable per 'let'"),
        FindingSpec("5️⃣", message: "split this variable declaration to introduce only one variable per 'let'"),
        FindingSpec("6️⃣", message: "split this variable declaration to introduce only one variable per 'let'"),
        FindingSpec("7️⃣", message: "split this variable declaration to introduce only one variable per 'var'"),
      ]
    )
  }

  func testMixedInitializedAndTypedBindings() {
    assertFormatting(
      OneVariableDeclarationPerLine.self,
      input: """
        1️⃣var a = 5, b: String
        2️⃣let c: Int, d = "d", e = "e", f: Double
        """,
      expected: """
        var a = 5
        var b: String
        let c: Int
        let d = "d"
        let e = "e"
        let f: Double
        """,
      findings: [
        FindingSpec("1️⃣", message: "split this variable declaration to introduce only one variable per 'var'"),
        FindingSpec("2️⃣", message: "split this variable declaration to introduce only one variable per 'let'"),
      ]
    )
  }

  func testCommentPrecedingDeclIsNotRepeated() {
    assertFormatting(
      OneVariableDeclarationPerLine.self,
      input: """
        // Comment
        1️⃣let a, b, c: Int
        """,
      expected: """
        // Comment
        let a: Int
        let b: Int
        let c: Int
        """,
      findings: [
        FindingSpec("1️⃣", message: "split this variable declaration to introduce only one variable per 'let'")
      ]
    )
  }

  func testCommentsPrecedingBindingsAreKept() {
    assertFormatting(
      OneVariableDeclarationPerLine.self,
      input: """
        1️⃣let /* a */ a, /* b */ b, /* c */ c: Int
        """,
      expected: """
        let /* a */ a: Int
        let /* b */ b: Int
        let /* c */ c: Int
        """,
      findings: [
        FindingSpec("1️⃣", message: "split this variable declaration to introduce only one variable per 'let'")
      ]
    )
  }

  func testInvalidBindingsAreNotDestroyed() {
    assertFormatting(
      OneVariableDeclarationPerLine.self,
      input: """
        1️⃣let a, b, c = 5
        2️⃣let d, e
        3️⃣let f, g, h: Int = 5
        4️⃣let a: Int, b, c = 5, d, e: Int
        """,
      expected: """
        let a, b, c = 5
        let d, e
        let f, g, h: Int = 5
        let a: Int
        let b, c = 5
        let d: Int
        let e: Int
        """,
      findings: [
        FindingSpec("1️⃣", message: "split this variable declaration to introduce only one variable per 'let'"),
        FindingSpec("2️⃣", message: "split this variable declaration to introduce only one variable per 'let'"),
        FindingSpec("3️⃣", message: "split this variable declaration to introduce only one variable per 'let'"),
        FindingSpec("4️⃣", message: "split this variable declaration to introduce only one variable per 'let'"),
      ]
    )
  }

  func testMultipleBindingsWithAccessorsAreCorrected() {
    // Swift parses multiple bindings with accessors but forbids them at a later
    // stage. That means that if the individual bindings would be correct in
    // isolation then we can correct them, which is kind of nice.
    assertFormatting(
      OneVariableDeclarationPerLine.self,
      input: """
        1️⃣var x: Int { return 10 }, y = "foo" { didSet { print("changed") } }
        """,
      expected: """
        var x: Int { return 10 }
        var y = "foo" { didSet { print("changed") } }
        """,
      findings: [
        FindingSpec("1️⃣", message: "split this variable declaration to introduce only one variable per 'var'")
      ]
    )
  }
}
