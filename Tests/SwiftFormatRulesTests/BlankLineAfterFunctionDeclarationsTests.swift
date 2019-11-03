import Foundation
import XCTest
import SwiftSyntax

@testable import SwiftFormatRules
@testable import SwiftFormatConfiguration

public class BlankLineAfterFunctionDeclarationsTests: DiagnosingTestCase {
  public func testMissingBlankLineAfterFunction() {
    XCTAssertFormatting(
      BlankLineAfterFunctionDeclarations.self,
      input: """
        func foo() {
          code()
        }

        struct Bar

          func bar() {
            /// Doc comment
            code()
          }
        }

        class Baz {

          func baz() {

            // comment
            code()
          }
        }
        """,
      expected: """
        func foo() {

          code()
        }

        struct Bar

          func bar() {

            /// Doc comment
            code()
          }
        }

        class Baz {

          func baz() {

            // comment
            code()
          }
        }
        """
    )
  }

  public func testIgnoreSingleLineFunction() {
    XCTAssertFormatting(
      BlankLineAfterFunctionDeclarations.self,
      input: """
        func foo() { code() }

        struct Bar

          func bar() { code() }
        }

        class Baz {

          func baz() { code() }
        }
        """,
      expected: """
        func foo() { code() }

        struct Bar

          func bar() { code() }
        }

        class Baz {

          func baz() { code() }
        }
        """
    )
  }

  public func testDontIgnoreSingleLineFunction() {
    XCTAssertFormatting(
      BlankLineAfterFunctionDeclarations.self,
      configure: { $0.blankLineAfterFunctionDeclarations.ignoreSingleLineFunctions = false },
      input: """
        func foo() { code() }

        struct Bar

          func bar() { code() }
        }

        class Baz {

          func baz() { code() }
        }
        """,
      expected: """
        func foo() {

          code()
        }

        struct Bar

          func bar() {

            code()
          }
        }

        class Baz {

          func baz() {

            code()
          }
        }
        """
    )
  }

  public func testIgnoreSuperCallsOnFirstLineFunction() {
    XCTAssertFormatting(
      BlankLineAfterFunctionDeclarations.self,
      input: """
        class Foo {

          func foo() {
            code()
          }

          func bar(_ bar: Bar, baz: Baz) {
            super.bar(bar, baz: baz)
            code()
          }
        }
        """,
      expected: """
        class Foo {

          func foo() {

            code()
          }

          func bar(_ bar: Bar, baz: Baz) {
            super.bar(bar, baz: baz)
            code()
          }
        }
        """
    )
  }

  public func testDontIgnoreSuperCallsOnFirstLineFunction() {
    XCTAssertFormatting(
      BlankLineAfterFunctionDeclarations.self,
      configure: { $0.blankLineAfterFunctionDeclarations.ignoreSuperCallsOnFirstLine = false },
      input: """
        class Foo {

          func foo() {
            code()
          }

          func bar(_ bar: Bar, baz: Baz) {
            super.bar(bar, baz: baz)
            code()
          }
        }
        """,
      expected: """
        class Foo {

          func foo() {

            code()
          }

          func bar(_ bar: Bar, baz: Baz) {

            super.bar(bar, baz: baz)
            code()
          }
        }
        """
    )
  }

  public func testInvalidBlankLineAfterFunction() {
    XCTAssertFormatting(
      BlankLineAfterFunctionDeclarations.self,
      input: """
        func foo() {



          code()
        }

        struct Bar

          func bar() {


            /// Doc comment
            code()
          }
        }

        class Baz {

          func baz() {



            // comment
            code()
          }
        }
        """,
      expected: """
        func foo() {

          code()
        }

        struct Bar

          func bar() {

            /// Doc comment
            code()
          }
        }

        class Baz {

          func baz() {

            // comment
            code()
          }
        }
        """)
  }

  public func testNestedFunctions() {
    XCTAssertFormatting(
      BlankLineAfterFunctionDeclarations.self,
      input: """
        func foo() {
          code()

          func foo2() {
            code()
          }

          struct Foo {

            func nestedFoo() {
              code()
            }

            func inlineFoo() { code() }
          }
        }

        struct Bar

          func bar() {
            /// Doc comment
            code()

            class Baz {

              func baz() {
                // comment
                code()

                enum Qux {

                  func qux() {
                    code()
                  }
                }
              }

              func foo(foo: Foo) {
                super.foo(foo: foo)
                code()
              }
            }
          }
        }
        """,
      expected: """
        func foo() {

          code()

          func foo2() {

            code()
          }

          struct Foo {

            func nestedFoo() {

              code()
            }

            func inlineFoo() { code() }
          }
        }

        struct Bar

          func bar() {

            /// Doc comment
            code()

            class Baz {

              func baz() {

                // comment
                code()

                enum Qux {

                  func qux() {

                    code()
                  }
                }
              }

              func foo(foo: Foo) {
                super.foo(foo: foo)
                code()
              }
            }
          }
        }
        """
    )
  }

  public func testDontIgnoreSingleLineFunctionsAndDontIgnoreSuperCallsOnFirstLineInNestedFunctions() {
    XCTAssertFormatting(
      BlankLineAfterFunctionDeclarations.self,
      configure: {
        $0.blankLineAfterFunctionDeclarations.ignoreSingleLineFunctions = false
        $0.blankLineAfterFunctionDeclarations.ignoreSuperCallsOnFirstLine = false
      },
      input: """
        func foo() {
          code()

          func foo2() {
            code()
          }

          struct Foo {

            func nestedFoo() {
              code()
            }

            func inlineFoo() { code() }
          }
        }

        struct Bar

          func bar() {
            /// Doc comment
            code()

            class Baz {

              func baz() {
                // comment
                code()

                enum Qux {

                  func qux() {
                    code()
                  }
                }
              }

              func foo(foo: Foo) {
                super.foo(foo: foo)
                code()
              }
            }
          }
        }
        """,
      expected: """
        func foo() {

          code()

          func foo2() {

            code()
          }

          struct Foo {

            func nestedFoo() {

              code()
            }

            func inlineFoo() {

              code()
            }
          }
        }

        struct Bar

          func bar() {

            /// Doc comment
            code()

            class Baz {

              func baz() {

                // comment
                code()

                enum Qux {

                  func qux() {

                    code()
                  }
                }
              }

              func foo(foo: Foo) {

                super.foo(foo: foo)
                code()
              }
            }
          }
        }
        """
    )
  }
}
