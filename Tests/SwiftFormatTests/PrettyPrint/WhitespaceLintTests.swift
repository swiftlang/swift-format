import SwiftFormat
import _SwiftFormatTestSupport

// A note about these tests: `WhitespaceLinter` *only* emits findings; it does not do any
// reformatting. Therefore, in these tests the "expected" source code is the desired string that the
// linter is diffing against.
final class WhitespaceLintTests: WhitespaceTestCase {
  func testSpacing() {
    assertWhitespaceLint(
      input: """
        let a1️⃣ : Int = 123
        let b =2️⃣456

        """,
      expected: """
        let a: Int = 123
        let b = 456

        """,
      findings: [
        FindingSpec("1️⃣", message: "remove 1 space"),
        FindingSpec("2️⃣", message: "add 1 space"),
      ]
    )
  }

  func testTabSpacing() {
    assertWhitespaceLint(
      input: """
        let a1️⃣\t: Int = 123

        """,
      expected: """
        let a: Int = 123

        """,
      findings: [
        FindingSpec("1️⃣", message: "use spaces for spacing")
      ]
    )
  }

  func testSpaceIndentation() {
    assertWhitespaceLint(
      input: """
        1️⃣  let a = 123
        2️⃣let b = 456
        3️⃣ let c = "abc"
        4️⃣\tlet d = 111

        """,
      expected: """
        let a = 123
            let b = 456
        let c = "abc"
          let d = 111

        """,
      findings: [
        FindingSpec("1️⃣", message: "remove all leading whitespace"),
        FindingSpec("2️⃣", message: "replace leading whitespace with 4 spaces"),
        FindingSpec("3️⃣", message: "remove all leading whitespace"),
        FindingSpec("4️⃣", message: "replace leading whitespace with 2 spaces"),
      ]
    )
  }

  func testTabIndentation() {
    assertWhitespaceLint(
      input: """
        1️⃣\t\tlet a = 123
        2️⃣let b = 456
        3️⃣  let c = "abc"
        4️⃣ let d = 111

        """,
      expected: """
        let a = 123
        \tlet b = 456
        let c = "abc"
        \t\tlet d = 111

        """,
      findings: [
        FindingSpec("1️⃣", message: "remove all leading whitespace"),
        FindingSpec("2️⃣", message: "replace leading whitespace with 1 tab"),
        FindingSpec("3️⃣", message: "remove all leading whitespace"),
        FindingSpec("4️⃣", message: "replace leading whitespace with 2 tabs"),
      ]
    )
  }

  func testHeterogeneousIndentation() {
    assertWhitespaceLint(
      input: """
        1️⃣\t\t  \t let a = 123
        2️⃣let b = 456
        3️⃣  let c = "abc"
        4️⃣ \tlet d = 111
        5️⃣\t let e = 111

        """,
      expected: """
          let a = 123
        \t  \t let b = 456
        let c = "abc"
          let d = 111
         \tlet e = 111

        """,
      findings: [
        FindingSpec("1️⃣", message: "replace leading whitespace with 2 spaces"),
        FindingSpec("2️⃣", message: "replace leading whitespace with 1 tab, 2 spaces, 1 tab, 1 space"),
        FindingSpec("3️⃣", message: "remove all leading whitespace"),
        FindingSpec("4️⃣", message: "replace leading whitespace with 2 spaces"),
        FindingSpec("5️⃣", message: "replace leading whitespace with 1 space, 1 tab"),
      ]
    )
  }

  func testTrailingWhitespace() {
    assertWhitespaceLint(
      input: """
        let a = 1231️⃣\u{20}\u{20}
        let b = "abc"2️⃣\u{20}
        let c = "def"
        3️⃣\u{20}\u{20}
        let d = 4564️⃣\u{20}\u{20}\u{20}

        """,
      expected: """
        let a = 123
        let b = "abc"
        let c = "def"

        let d = 456

        """,
      findings: [
        FindingSpec("1️⃣", message: "remove trailing whitespace"),
        FindingSpec("2️⃣", message: "remove trailing whitespace"),
        FindingSpec("3️⃣", message: "remove trailing whitespace"),
        FindingSpec("4️⃣", message: "remove trailing whitespace"),
      ]
    )
  }

  func testAddLines() {
    assertWhitespaceLint(
      input: """
        let a = 1231️⃣
        let b = "abc"
        func myfun() {2️⃣ return3️⃣ }

        """,
      expected: """
        let a = 123

        let b = "abc"
        func myfun() {
          return
        }

        """,
      findings: [
        FindingSpec("1️⃣", message: "add 1 line break"),
        FindingSpec("2️⃣", message: "add 1 line break"),
        FindingSpec("3️⃣", message: "add 1 line break"),
      ]
    )
  }

  func testRemoveLines() {
    assertWhitespaceLint(
      input: """
        let a = 1231️⃣

        let b = "abc"2️⃣
        3️⃣

        let c = 456
        func myFun() {4️⃣
          return someValue5️⃣
        }

        """,
      expected: """
        let a = 123
        let b = "abc"
        let c = 456
        func myFun() { return someValue }

        """,
      findings: [
        FindingSpec("1️⃣", message: "remove line break"),
        FindingSpec("2️⃣", message: "remove line break"),
        FindingSpec("3️⃣", message: "remove line break"),
        FindingSpec("4️⃣", message: "remove line break"),
        FindingSpec("5️⃣", message: "remove line break"),
      ]
    )
  }

  func testLineLength() {
    assertWhitespaceLint(
      input: """
        1️⃣func myFunc(longVar1: Bool, longVar2: Bool, longVar3: Bool, longVar4: Bool) {
          // do stuff
        }

        2️⃣func myFunc(longVar1: Bool, longVar2: Bool,
          longVar3: Bool,
          longVar4: Bool3️⃣) {
          // do stuff
        }

        """,
      expected: """
        func myFunc(
          longVar1: Bool,
          longVar2: Bool,
          longVar3: Bool,
          longVar4: Bool
        ) {
          // do stuff
        }

        func myFunc(
          longVar1: Bool,
          longVar2: Bool,
          longVar3: Bool,
          longVar4: Bool
        ) {
          // do stuff
        }

        """,
      linelength: 30,
      findings: [
        FindingSpec("1️⃣", message: "line is too long"),
        FindingSpec("2️⃣", message: "line is too long"),
        FindingSpec("3️⃣", message: "add 1 line break"),
      ]
    )
  }
}
