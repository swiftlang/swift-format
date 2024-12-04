@_spi(Rules) import SwiftFormat
import _SwiftFormatTestSupport

final class SeverityOverrideRuleTest: LintOrFormatRuleTestCase {
  func testDoNotUseSemicolonAsError() {

    var config = Configuration.forTesting.disableAllRules()
    config.rules[DoNotUseSemicolons.self.ruleName] = .error

    assertFormatting(
      DoNotUseSemicolons.self,
      input: """
        print("hello")1️⃣;
        """,
      expected: """
        print("hello")
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove ';'", severity: .error),
      ],
      configuration: config
    )
  }

  func testDoNotUseSemicolonDisabled() {

    var config = Configuration.forTesting.disableAllRules()
    config.rules[DoNotUseSemicolons.self.ruleName] = .disabled

    assertFormatting(
      DoNotUseSemicolons.self,
      input: """
        print("hello");
        """,
      expected: """
        print("hello");
        """,
      findings: [],
      configuration: config
    )
  }
}

final class SeverityOverridePrettyPrintTest: PrettyPrintTestCase {

  func testTrailingCommaDiagnosticsDisabled() {
    assertPrettyPrintEqual(
      input: """
        let a = [1, 2, 3,]
        """,
      expected: """
        let a = [1, 2, 3,]
        
        """,
      linelength: 45,
      configuration: Configuration.forTesting.disableAllRules().enable("TrailingComma", severity: .disabled),
      whitespaceOnly: true,
      findings: []
    )
  }

  func testTrailingCommaDiagnosticsAsError() {
    assertPrettyPrintEqual(
      input: """
        let a = [1, 2, 31️⃣,]
        """,
      expected: """
        let a = [1, 2, 3,]
        
        """,
      linelength: 45,
      configuration: Configuration.forTesting.disableAllRules().enable("TrailingComma", severity: .error),
      whitespaceOnly: true,
      findings: [
        FindingSpec("1️⃣", message: "remove trailing comma from the last element in single line collection literal", severity: .error),
      ]
    )
  }
}

final class SeverityOverrideWhitespaceTest: WhitespaceTestCase {
  func testTrailingWhitespaceAsError() {
    assertWhitespaceLint(
      input: """
        let a = 1231️⃣\u{20}\u{20}
        
        """,
      expected: """
        let a = 123
        
        """,
      configuration: Configuration.forTesting.disableAllRules().enable("TrailingWhitespace", severity: .error),
      findings: [
        FindingSpec("1️⃣", message: "remove trailing whitespace", severity: .error),
      ]
    )
  }

  func testTrailingWhitespaceDisabled() {
    assertWhitespaceLint(
      input: """
        let a = 123\u{20}\u{20}
        
        """,
      expected: """
        let a = 123
        
        """,
      configuration: Configuration.forTesting.disableAllRules().enable("TrailingWhitespace", severity: .disabled),
      findings: []
    )
  }
}
