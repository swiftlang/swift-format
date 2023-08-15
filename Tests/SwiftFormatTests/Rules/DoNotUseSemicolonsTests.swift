import SwiftFormatRules

final class DoNotUseSemicolonsTests: LintOrFormatRuleTestCase {
  func testSemicolonUse() {
    XCTAssertFormatting(
      DoNotUseSemicolons.self,
      input: """
             print("hello"); print("goodbye");
             print("3")
             """,
      expected: """
                print("hello")
                print("goodbye")
                print("3")
                """)
  }

  func testSemicolonsInNestedStatements() {
    XCTAssertFormatting(
      DoNotUseSemicolons.self,
      input: """
             guard let someVar = Optional(items.filter ({ a in foo(a); return true; })) else {
               items.forEach { a in foo(a); }; return;
             }
             """,
      // The formatting in the expected output is unappealing, but that is fixed by the pretty
      // printer and isn't a concern for the format rule.
      expected: """
                guard let someVar = Optional(items.filter ({ a in foo(a)
                return true})) else {
                  items.forEach { a in foo(a)}
                return
                }
                """)
  }

  func testSemicolonsInMemberLists() {
    XCTAssertFormatting(
      DoNotUseSemicolons.self,
      input: """
             struct Foo {
               func foo() {
                 code()
               };

               let someVar = 5;let someOtherVar = 6;
             }
             """,
      expected: """
                struct Foo {
                  func foo() {
                    code()
                  }

                  let someVar = 5
                let someOtherVar = 6
                }
                """)
  }

  func testNewlinesAfterSemicolons() {
    XCTAssertFormatting(
      DoNotUseSemicolons.self,
      input: """
             print("hello");
             /// This is a doc comment for printing "goodbye".
             print("goodbye");

             /// This is a doc comment for printing "3".
             print("3");

             print("4"); /** Inline comment. */ print("5");

             print("6");  // This is an important statement.
             print("7");
             """,
      expected: """
                print("hello")
                /// This is a doc comment for printing "goodbye".
                print("goodbye")

                /// This is a doc comment for printing "3".
                print("3")

                print("4")
                /** Inline comment. */ print("5")

                print("6")// This is an important statement.
                print("7")
                """)
  }
  
  func testSemicolonsSeparatingDoWhile() {
    XCTAssertFormatting(
      DoNotUseSemicolons.self,
      input: """
             do { f() };
             while someCondition { g() }

             do {
               f()
             };

             // Comment and whitespace separating blocks.
             while someCondition {
               g()
             }

             do { f() };
             for _ in 0..<10 { g() }
             """,
      expected: """
                do { f() };
                while someCondition { g() }

                do {
                  f()
                };

                // Comment and whitespace separating blocks.
                while someCondition {
                  g()
                }

                do { f() }
                for _ in 0..<10 { g() }
                """)
  }
}
