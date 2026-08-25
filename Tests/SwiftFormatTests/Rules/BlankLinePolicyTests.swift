import Foundation
@_spi(Rules) import SwiftFormat
import XCTest
import _SwiftFormatTestSupport

final class BlankLinePolicyTests: LintOrFormatRuleTestCase {
  func testBetweenDeclarationsInsertsRequiredBlankLine() {
    assertFormatting(
      BlankLinePolicy.self,
      input: """
        struct A {}1️⃣
        struct B {}
        """,
      expected: """
        struct A {}

        struct B {}
        """,
      findings: [
        FindingSpec("1️⃣", message: "insert a blank line between declarations")
      ]
    )
  }

  func testBetweenDeclarationsCollapsesExtraBlankLines() {
    assertFormatting(
      BlankLinePolicy.self,
      input: """
        struct A {}1️⃣


        struct B {}
        """,
      expected: """
        struct A {}

        struct B {}
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove 1 blank line between declarations")
      ]
    )
  }

  func testScopeEdgesInFunctionBody() {
    var configuration = Configuration.forTesting(enabledRule: BlankLinePolicy.self.ruleName)
    configuration.blankLinePolicy.scopeEdges = .none
    assertFormatting(
      BlankLinePolicy.self,
      input: """
        func f() {1️⃣

          let x = 1

        2️⃣}
        """,
      expected: """
        func f() {
          let x = 1
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove 1 blank line after '{'"),
        FindingSpec("2️⃣", message: "remove 1 blank line before '}'"),
      ],
      configuration: configuration
    )
  }

  func testScopeEdgesInTypeBody() {
    var configuration = Configuration.forTesting(enabledRule: BlankLinePolicy.self.ruleName)
    configuration.blankLinePolicy.scopeEdges = .none
    assertFormatting(
      BlankLinePolicy.self,
      input: """
        struct S {1️⃣

          let x: Int

        2️⃣}
        """,
      expected: """
        struct S {
          let x: Int
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove 1 blank line after '{'"),
        FindingSpec("2️⃣", message: "remove 1 blank line before '}'"),
      ],
      configuration: configuration
    )
  }

  func testMembersScopeSeparated() {
    assertFormatting(
      BlankLinePolicy.self,
      input: """
        struct S {
          let a = 1
          let b = 21️⃣
          func f() {}2️⃣
          func g() {}
        }
        """,
      expected: """
        struct S {
          let a = 1
          let b = 2

          func f() {}

          func g() {}
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "insert a blank line between members"),
        FindingSpec("2️⃣", message: "insert a blank line between members"),
      ]
    )
  }

  func testMembersScopeSeparatedLeavesListLikeMembersAlone() {
    assertFormatting(
      BlankLinePolicy.self,
      input: """
        enum E {
          case a

          case b
        }
        """,
      expected: """
        enum E {
          case a

          case b
        }
        """,
      findings: []
    )
  }

  func testMarksBeforeAndAfter() {
    assertFormatting(
      BlankLinePolicy.self,
      input: """
        struct S {
          let a = 11️⃣
          // MARK: Stuff

          2️⃣func f() {}
        }
        """,
      expected: """
        struct S {
          let a = 1

          // MARK: Stuff
          func f() {}
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "insert a blank line before 'MARK:'"),
        FindingSpec("2️⃣", message: "remove 1 blank line after 'MARK:'"),
      ]
    )
  }

  func testSwitchCasesAutoTightensSingleLineCases() {
    assertFormatting(
      BlankLinePolicy.self,
      input: """
        func f(v: Int) {
          switch v {
          case 1: print(1)1️⃣

          case 2: print(2)
          }
        }
        """,
      expected: """
        func f(v: Int) {
          switch v {
          case 1: print(1)
          case 2: print(2)
          }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove 1 blank line between switch cases")
      ]
    )
  }

  func testSwitchCasesAutoSeparatesMultilineCases() {
    assertFormatting(
      BlankLinePolicy.self,
      input: """
        func f(v: Int) {
          switch v {
          case 1:
            print(1)1️⃣
          case 2:
            print(2)
          }
        }
        """,
      expected: """
        func f(v: Int) {
          switch v {
          case 1:
            print(1)

          case 2:
            print(2)
          }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "insert a blank line between switch cases")
      ]
    )
  }

  func testAfterCaseLabel() {
    assertFormatting(
      BlankLinePolicy.self,
      input: """
        func f(v: Int) {
          switch v {
          case 1:1️⃣

            print(1)
          }
        }
        """,
      expected: """
        func f(v: Int) {
          switch v {
          case 1:
            print(1)
          }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove 1 blank line after case label")
      ]
    )
  }

  func testAttributes() {
    assertFormatting(
      BlankLinePolicy.self,
      input: """
        @available(iOS 13, *)

        1️⃣@objc

        2️⃣func f() {}
        """,
      expected: """
        @available(iOS 13, *)
        @objc
        func f() {}
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove 1 blank line after an attribute"),
        FindingSpec("2️⃣", message: "remove 1 blank line after an attribute"),
      ]
    )
  }

  func testExpressions() {
    assertFormatting(
      BlankLinePolicy.self,
      input: """
        func f() {
          print(
            "a",1️⃣

            "b"
          )
          let xs = [
            1,2️⃣

            2,
          ]
        }
        """,
      expected: """
        func f() {
          print(
            "a",
            "b"
          )
          let xs = [
            1,
            2,
          ]
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove 1 blank line between arguments"),
        FindingSpec("2️⃣", message: "remove 1 blank line between collection elements"),
      ]
    )
  }

  func testConditionalCompilationEdges() {
    assertFormatting(
      BlankLinePolicy.self,
      input: """
        #if os(macOS)1️⃣

        func f() {}

        2️⃣#endif
        """,
      expected: """
        #if os(macOS)
        func f() {}
        #endif
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove 1 blank line after a conditional compilation directive"),
        FindingSpec("2️⃣", message: "remove 1 blank line before '#endif'"),
      ]
    )
  }

  func testGuardPrologue() {
    assertFormatting(
      BlankLinePolicy.self,
      input: """
        func f(x: Int?) {
          guard let y = x else { return }1️⃣

          guard y > 0 else { return }2️⃣
          use(y)
        }
        """,
      expected: """
        func f(x: Int?) {
          guard let y = x else { return }
          guard y > 0 else { return }

          use(y)
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove 1 blank line between guard statements"),
        FindingSpec("2️⃣", message: "insert a blank line after guard statements"),
      ]
    )
  }

  func testBeforeElse() {
    assertFormatting(
      BlankLinePolicy.self,
      input: """
        func f(v: Bool) {
          if v {
            print(1)
          }

          1️⃣else {
            print(2)
          }
        }
        """,
      expected: """
        func f(v: Bool) {
          if v {
            print(1)
          }
          else {
            print(2)
          }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove 1 blank line before 'else'")
      ]
    )
  }

  func testMembersNoneConfiguration() {
    var configuration = Configuration.forTesting(enabledRule: BlankLinePolicy.self.ruleName)
    configuration.blankLinePolicy.members = .none
    assertFormatting(
      BlankLinePolicy.self,
      input: """
        struct S {
          func f() {}1️⃣

          func g() {}
        }
        """,
      expected: """
        struct S {
          func f() {}
          func g() {}
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove 1 blank line between members")
      ],
      configuration: configuration
    )
  }

  func testMembersOptionalConfiguration() {
    var configuration = Configuration.forTesting(enabledRule: BlankLinePolicy.self.ruleName)
    configuration.blankLinePolicy.members = .optional
    assertFormatting(
      BlankLinePolicy.self,
      input: """
        struct S {
          func f() {}
          func g() {}
        }
        """,
      expected: """
        struct S {
          func f() {}
          func g() {}
        }
        """,
      findings: [],
      configuration: configuration
    )
  }

  func testGapAxesRejectExactlyOne() {
    let gapAxes = [
      "scopeEdges", "afterCaseLabel", "attributes", "expressions",
      "conditionalCompilationEdges", "beforeElse",
    ]
    for axis in gapAxes {
      let json = #"{"rules": {"BlankLinePolicy": true}, "blankLinePolicy": {"\#(axis)": "exactlyOne"}}"#
      XCTAssertThrowsError(try Configuration(data: Data(json.utf8))) { error in
        guard case DecodingError.dataCorrupted(let context) = error else {
          return XCTFail("expected dataCorrupted for \(axis), got \(error)")
        }
        XCTAssertTrue(
          context.debugDescription.contains("cannot be 'exactlyOne'"),
          "unexpected message for \(axis): \(context.debugDescription)"
        )
      }
    }
  }

  func testSemicolonJoinedMembersGetInsertedBlankLine() {
    assertFormatting(
      BlankLinePolicy.self,
      input: """
        struct S { let a = 1; 1️⃣func f() {} }
        """,
      expected: """
        struct S { let a = 1;

        func f() {} }
        """,
      findings: [
        FindingSpec("1️⃣", message: "insert a blank line between members")
      ]
    )
  }

  func testSemicolonJoinedGuardPrologueGetsInsertedBlankLine() {
    assertFormatting(
      BlankLinePolicy.self,
      input: """
        func f(x: Int?) {
          guard let y = x else { return }; 1️⃣use(y)
        }
        """,
      expected: """
        func f(x: Int?) {
          guard let y = x else { return };

        use(y)
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "insert a blank line after guard statements")
      ]
    )
  }

  func testGetterOnlyAccessorScopeEdges() {
    var configuration = Configuration.forTesting(enabledRule: BlankLinePolicy.self.ruleName)
    configuration.blankLinePolicy.scopeEdges = .none
    assertFormatting(
      BlankLinePolicy.self,
      input: """
        struct S {
          var x: Int {1️⃣

            return 1

          2️⃣}
        }
        """,
      expected: """
        struct S {
          var x: Int {
            return 1
          }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove 1 blank line after '{'"),
        FindingSpec("2️⃣", message: "remove 1 blank line before '}'"),
      ],
      configuration: configuration
    )
  }

  func testClosureScopeEdges() {
    var configuration = Configuration.forTesting(enabledRule: BlankLinePolicy.self.ruleName)
    configuration.blankLinePolicy.scopeEdges = .none
    assertFormatting(
      BlankLinePolicy.self,
      input: """
        func f() {
          let c = {1️⃣

            print(1)

          2️⃣}
        }
        """,
      expected: """
        func f() {
          let c = {
            print(1)
          }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove 1 blank line after '{'"),
        FindingSpec("2️⃣", message: "remove 1 blank line before '}'"),
      ],
      configuration: configuration
    )
  }

  func testDictionaryElements() {
    assertFormatting(
      BlankLinePolicy.self,
      input: """
        let d = [
          "a": 1,1️⃣

          "b": 2,
        ]
        """,
      expected: """
        let d = [
          "a": 1,
          "b": 2,
        ]
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove 1 blank line between collection elements")
      ]
    )
  }

  func testBeforeCatch() {
    assertFormatting(
      BlankLinePolicy.self,
      input: """
        func f() {
          do {
            print(1)
          }

          1️⃣catch {
            print(2)
          }
        }
        """,
      expected: """
        func f() {
          do {
            print(1)
          }
          catch {
            print(2)
          }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove 1 blank line before 'catch'")
      ]
    )
  }

  func testElseClauseDirectiveEdge() {
    assertFormatting(
      BlankLinePolicy.self,
      input: """
        #if FOO
        func f() {}
        #else1️⃣

        func g() {}

        2️⃣#endif
        """,
      expected: """
        #if FOO
        func f() {}
        #else
        func g() {}
        #endif
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove 1 blank line after a conditional compilation directive"),
        FindingSpec("2️⃣", message: "remove 1 blank line before '#endif'"),
      ]
    )
  }

  func testDeclarationsInsideConditionalCompilationBlock() {
    assertFormatting(
      BlankLinePolicy.self,
      input: """
        #if FOO
        struct A {}1️⃣
        struct B {}
        #endif
        """,
      expected: """
        #if FOO
        struct A {}

        struct B {}
        #endif
        """,
      findings: [
        FindingSpec("1️⃣", message: "insert a blank line between declarations")
      ]
    )
  }

  func testKindTransitionBetweenListLikeMembers() {
    assertFormatting(
      BlankLinePolicy.self,
      input: """
        struct S {
          let a = 11️⃣
          typealias T = Int
        }
        """,
      expected: """
        struct S {
          let a = 1

          typealias T = Int
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "insert a blank line between members")
      ]
    )
  }

  func testImportsGroupAtTopLevel() {
    assertFormatting(
      BlankLinePolicy.self,
      input: """
        import Alpha
        import Beta1️⃣
        struct S {}
        """,
      expected: """
        import Alpha
        import Beta

        struct S {}
        """,
      findings: [
        FindingSpec("1️⃣", message: "insert a blank line between declarations")
      ]
    )
  }

  func testMarkDashVariant() {
    assertFormatting(
      BlankLinePolicy.self,
      input: """
        struct S {
          let a = 11️⃣
          // MARK: - Section

          2️⃣func f() {}
        }
        """,
      expected: """
        struct S {
          let a = 1

          // MARK: - Section
          func f() {}
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "insert a blank line before 'MARK:'"),
        FindingSpec("2️⃣", message: "remove 1 blank line after 'MARK:'"),
      ]
    )
  }

  func testMarkOnFirstMemberAppliesOnlyAfterPolicy() {
    assertFormatting(
      BlankLinePolicy.self,
      input: """
        struct S {
          // MARK: Only

          1️⃣func f() {}
        }
        """,
      expected: """
        struct S {
          // MARK: Only
          func f() {}
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove 1 blank line after 'MARK:'")
      ]
    )
  }

  func testIgnoreCommentIsRespected() {
    assertFormatting(
      BlankLinePolicy.self,
      input: """
        struct S {
          let a = 1
          // swift-format-ignore
          func f() {}
        }
        """,
      expected: """
        struct S {
          let a = 1
          // swift-format-ignore
          func f() {}
        }
        """,
      findings: []
    )
  }

  func testCRLFCompliantBoundaryIsLeftAlone() {
    assertFormatting(
      BlankLinePolicy.self,
      input: "struct A {}\r\n\r\nstruct B {}\r\n",
      expected: "struct A {}\r\n\r\nstruct B {}\r\n",
      findings: []
    )
  }

  func testPrecedenceGroupScopeEdges() {
    var configuration = Configuration.forTesting(enabledRule: BlankLinePolicy.self.ruleName)
    configuration.blankLinePolicy.scopeEdges = .none
    assertFormatting(
      BlankLinePolicy.self,
      input: """
        precedencegroup P {1️⃣

          associativity: left

          higherThan: Q

        2️⃣}
        """,
      expected: """
        precedencegroup P {
          associativity: left

          higherThan: Q
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove 1 blank line after '{'"),
        FindingSpec("2️⃣", message: "remove 1 blank line before '}'"),
      ],
      configuration: configuration
    )
  }

  func testGuardPrologueInClosure() {
    assertFormatting(
      BlankLinePolicy.self,
      input: """
        func f(x: Int?) {
          let c = { (y: Int?) in
            guard let z = y else { return }1️⃣
            return z
          }
          _ = c(x)
        }
        """,
      expected: """
        func f(x: Int?) {
          let c = { (y: Int?) in
            guard let z = y else { return }

            return z
          }
          _ = c(x)
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "insert a blank line after guard statements")
      ]
    )
  }

  func testWhitespaceOnlyBlankLinesAreRemoved() {
    var configuration = Configuration.forTesting(enabledRule: BlankLinePolicy.self.ruleName)
    configuration.blankLinePolicy.scopeEdges = .none
    assertFormatting(
      BlankLinePolicy.self,
      input: "func f() {1️⃣\n  \n  let x = 1\n  \n2️⃣}\n",
      expected: "func f() {\n  let x = 1\n}\n",
      findings: [
        FindingSpec("1️⃣", message: "remove 1 blank line after '{'"),
        FindingSpec("2️⃣", message: "remove 1 blank line before '}'"),
      ],
      configuration: configuration
    )
  }

  func testMembersPolicyAppliesInsideTypeLevelIfConfig() {
    var configuration = Configuration.forTesting(enabledRule: BlankLinePolicy.self.ruleName)
    configuration.blankLinePolicy.members = .none
    assertFormatting(
      BlankLinePolicy.self,
      input: """
        struct S {
        #if os(Linux)
          let a = 11️⃣

          func f() {}
        #endif
        }
        """,
      expected: """
        struct S {
        #if os(Linux)
          let a = 1
          func f() {}
        #endif
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove 1 blank line between members")
      ],
      configuration: configuration
    )
  }

  func testConditionalCompilationEdgesOptionalKeepsSiblingAxes() {
    var configuration = Configuration.forTesting(enabledRule: BlankLinePolicy.self.ruleName)
    configuration.blankLinePolicy.conditionalCompilationEdges = .optional
    assertFormatting(
      BlankLinePolicy.self,
      input: """
        #if FOO
        struct A {}1️⃣
        struct B {}
        #endif
        """,
      expected: """
        #if FOO
        struct A {}

        struct B {}
        #endif
        """,
      findings: [
        FindingSpec("1️⃣", message: "insert a blank line between declarations")
      ],
      configuration: configuration
    )
  }

  func testTopLevelStatementsGroup() {
    assertFormatting(
      BlankLinePolicy.self,
      input: """
        let x = 1
        x += 1
        print(x)
        """,
      expected: """
        let x = 1
        x += 1
        print(x)
        """,
      findings: []
    )
  }

  func testBetweenDeclarationsNoneConfiguration() {
    var configuration = Configuration.forTesting(enabledRule: BlankLinePolicy.self.ruleName)
    configuration.blankLinePolicy.betweenDeclarations = .none
    assertFormatting(
      BlankLinePolicy.self,
      input: """
        struct A {}1️⃣

        struct B {}
        """,
      expected: """
        struct A {}
        struct B {}
        """,
      findings: [
        FindingSpec("1️⃣", message: "remove 1 blank line between declarations")
      ],
      configuration: configuration
    )
  }

  func testMarksDisabledConfiguration() {
    var configuration = Configuration.forTesting(enabledRule: BlankLinePolicy.self.ruleName)
    configuration.blankLinePolicy.marks = MarkBlankLinePolicy(before: .none, after: .none)
    assertFormatting(
      BlankLinePolicy.self,
      input: """
        struct S {
          let a = 1
          // MARK: X
          func f() {}
        }
        """,
      expected: """
        struct S {
          let a = 1
          // MARK: X
          func f() {}
        }
        """,
      findings: [],
      configuration: configuration
    )
  }

  func testGuardPrologueOptionalConfiguration() {
    var configuration = Configuration.forTesting(enabledRule: BlankLinePolicy.self.ruleName)
    configuration.blankLinePolicy.guardPrologue = .optional
    assertFormatting(
      BlankLinePolicy.self,
      input: """
        func f(x: Int?) {
          guard let y = x else { return }
          use(y)
        }
        """,
      expected: """
        func f(x: Int?) {
          guard let y = x else { return }
          use(y)
        }
        """,
      findings: [],
      configuration: configuration
    )
  }

  func testLintPipelineEmitsEachFindingOnce() {
    var findings: [Finding] = []
    let linter = SwiftLinter(
      configuration: Configuration.forTesting(enabledRule: BlankLinePolicy.self.ruleName),
      findingConsumer: { findings.append($0) }
    )
    try! linter.lint(
      source: "struct A {}\nstruct B {}\n",
      assumingFileURL: URL(fileURLWithPath: "test.swift")
    )
    XCTAssertEqual(findings.count, 1)
    XCTAssertEqual("\(findings.first!.message)", "insert a blank line between declarations")
  }

  func testScopeEdgesDefaultsToOptional() {
    assertFormatting(
      BlankLinePolicy.self,
      input: """
        struct S {

          let x: Int

        }
        """,
      expected: """
        struct S {

          let x: Int

        }
        """,
      findings: []
    )
  }
}
