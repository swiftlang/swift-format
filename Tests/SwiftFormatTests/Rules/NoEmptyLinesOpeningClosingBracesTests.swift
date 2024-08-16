import _SwiftFormatTestSupport

@_spi(Rules) import SwiftFormat

final class NoEmptyLinesOpeningClosingBracesTests: LintOrFormatRuleTestCase {
  func testNoEmptyLinesOpeningClosingBracesInCodeBlock() {
    assertFormatting(
      NoEmptyLinesOpeningClosingBraces.self,
      input: """
          func f() {1️⃣
          
            //
            return
          
          
          2️⃣}
          """,
      expected: """
          func f() {
            //
            return
          }
          """,
      findings: [
        FindingSpec("1️⃣", message: "remove empty line after '{'"),
        FindingSpec("2️⃣", message: "remove empty lines before '}'"),
      ]
    )
  }
  
  func testNoEmptyLinesOpeningClosingBracesInMemberBlock() {
    assertFormatting(
      NoEmptyLinesOpeningClosingBraces.self,
      input: """
          struct {1️⃣
            
            let x: Int
          
            let y: Int
          
          2️⃣}
          """,
      expected: """
          struct {
            let x: Int
          
            let y: Int
          }
          """,
      findings: [
        FindingSpec("1️⃣", message: "remove empty line after '{'"),
        FindingSpec("2️⃣", message: "remove empty line before '}'"),
      ]
    )
  }
  
  func testNoEmptyLinesOpeningClosingBracesInAccessorBlock() {
    assertFormatting(
      NoEmptyLinesOpeningClosingBraces.self,
      input: """
          var x: Int {1️⃣
            
          //
            return _x
          
          2️⃣}
          
          var y: Int {3️⃣
          
            get 5️⃣{
            
            //
              return _y
          
           6️⃣ }
          
            set 7️⃣{
          
            //
              _x = newValue
          
           8️⃣ }
          
          4️⃣}
          """,
      expected: """
          var x: Int {
          //
            return _x
          }
          
          var y: Int {
            get {
            //
              return _y
            }

            set {
            //
              _x = newValue
            }
          }
          """,
      findings: [
        FindingSpec("1️⃣", message: "remove empty line after '{'"),
        FindingSpec("2️⃣", message: "remove empty line before '}'"),
        FindingSpec("3️⃣", message: "remove empty line after '{'"),
        FindingSpec("4️⃣", message: "remove empty line before '}'"),
        FindingSpec("5️⃣", message: "remove empty line after '{'"),
        FindingSpec("6️⃣", message: "remove empty line before '}'"),
        FindingSpec("7️⃣", message: "remove empty line after '{'"),
        FindingSpec("8️⃣", message: "remove empty line before '}'"),
      ]
    )
  }

  func testNoEmptyLinesOpeningClosingBracesInClosureExpr() {
    assertFormatting(
      NoEmptyLinesOpeningClosingBraces.self,
      input: """
          let closure = {1️⃣
          
            //
            return
          
          2️⃣}
          """,
      expected: """
          let closure = {
            //
            return
          }
          """,
      findings: [
        FindingSpec("1️⃣", message: "remove empty line after '{'"),
        FindingSpec("2️⃣", message: "remove empty line before '}'"),
      ]
    )
  }
}
