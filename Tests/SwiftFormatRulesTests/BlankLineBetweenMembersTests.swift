import Foundation
import SwiftFormatConfiguration
import SwiftSyntax
import XCTest

@testable import SwiftFormatRules

public class BlankLineBetweenMembersTests: DiagnosingTestCase {
  public func testBlankLineBeforeFirstChildOrNot() {
    XCTAssertFormatting(
      BlankLineBetweenMembers.self,
      input: """
        struct Foo {
          /// Doc comment
          func foo() {
            code()
          }
        }

        struct Bar {

          /// Doc comment
          func bar() {
            code()
          }
        }
        """,
      expected: """
        struct Foo {
          /// Doc comment
          func foo() {
            code()
          }
        }

        struct Bar {

          /// Doc comment
          func bar() {
            code()
          }
        }
        """
    )
  }

  public func testInvalidBlankLineBetweenMembers() {
    XCTAssertFormatting(
      BlankLineBetweenMembers.self,
      input: """
             struct foo1 {



               var test1 = 13
               // Multiline
               // comment for b
               var b = 12
               /*BlockComment*/


               var c = 11




               // Multiline comment
               // for d
               var d: Bool {
               return false
               }
               /// Comment for e
               var end1: Bool {
               return false
               }
             }
             """,
      expected: """
                struct foo1 {



                  var test1 = 13

                  // Multiline
                  // comment for b
                  var b = 12

                  /*BlockComment*/


                  var c = 11




                  // Multiline comment
                  // for d
                  var d: Bool {
                  return false
                  }

                  /// Comment for e
                  var end1: Bool {
                  return false
                  }
                }
                """)
  }

  public func testTwoMembers() {
    XCTAssertFormatting(
      BlankLineBetweenMembers.self,
      input: """
             struct foo2 {
               var test2 = 13

               var a = 10
             }

             struct secondFoo2 {
               var a = 1
               var end2: Bool {
               return false
               }
             }
             """,
      expected: """
                struct foo2 {
                  var test2 = 13

                  var a = 10
                }

                struct secondFoo2 {
                  var a = 1

                  var end2: Bool {
                  return false
                  }
                }
                """)
  }

  public func testNestedMembers() {
    XCTAssertFormatting(
      BlankLineBetweenMembers.self,
      input: """
             struct foo3 {
               // nested Rank enumeration
               enum Rank: Int {
                 case two = 2, three, four


                 case jack, queen, king, ace
               }

               struct secondFoo3 {
                 var a = 1
                 var e: Bool {
                 return false
                 }
               }
             }
             """,
      expected: """
                struct foo3 {
                  // nested Rank enumeration
                  enum Rank: Int {
                    case two = 2, three, four


                    case jack, queen, king, ace
                  }

                  struct secondFoo3 {
                    var a = 1

                    var e: Bool {
                    return false
                    }
                  }
                }
                """)
  }

  public func testNoBlankLineBetweenSingleLineMembers() {
    XCTAssertFormatting(
        BlankLineBetweenMembers.self,
        input: """
               enum Foo {
                 let bar = 1
                 let baz = 2
               }
               enum Foo {
                 // MARK: - This is an important region of the code.

                 let bar = 1
                 let baz = 2
               }
               enum Foo {
                 var quxxe = 0
                 // MARK: - This is an important region of the code.

                 let bar = 1
                 let baz = 2
               }
               enum Foo {
                 let bar = 1
                 let baz = 2

                 // MARK: - This is an important region of the code.
               }
               """,
        expected: """
                  enum Foo {
                    let bar = 1
                    let baz = 2
                  }
                  enum Foo {
                    // MARK: - This is an important region of the code.

                    let bar = 1
                    let baz = 2
                  }
                  enum Foo {
                    var quxxe = 0

                    // MARK: - This is an important region of the code.

                    let bar = 1
                    let baz = 2
                  }
                  enum Foo {
                    let bar = 1
                    let baz = 2

                    // MARK: - This is an important region of the code.
                  }
                  """)
  }

  public func testBlankLinesAroundDocumentedMembers() {
    XCTAssertFormatting(
           BlankLineBetweenMembers.self,
           input: """
                  enum Foo {

                    // This comment is describing bar.
                    let bar = 1
                    let baz = 2
                    let quxxe = 3
                  }
                  enum Foo {
                    var quxxe = 0

                    /// bar: A property that has a Bar.
                    let bar = 1
                    let baz = 2
                    var car = 3
                  }
                  """,
           expected: """
                     enum Foo {

                       // This comment is describing bar.
                       let bar = 1

                       let baz = 2
                       let quxxe = 3
                     }
                     enum Foo {
                       var quxxe = 0

                       /// bar: A property that has a Bar.
                       let bar = 1

                       let baz = 2
                       var car = 3
                     }
                     """)
  }

  public func testBlankLineBetweenMembersIgnoreSingleLineDisabled() {
    var config = Configuration()
    config.blankLineBetweenMembers =
      BlankLineBetweenMembersConfiguration(ignoreSingleLineProperties: false)

    let input = """
      enum Foo {
        let bar = 1
        let baz = 2
      }
      enum Foo {
        // MARK: - This is an important region of the code.

        let bar = 1
        let baz = 2
      }
      enum Foo {
        var quxxe = 0
        // MARK: - This is an important region of the code.

        let bar = 1
        let baz = 2
      }
      """
    let expected = """
      enum Foo {
        let bar = 1

        let baz = 2
      }
      enum Foo {
        // MARK: - This is an important region of the code.

        let bar = 1

        let baz = 2
      }
      enum Foo {
        var quxxe = 0

        // MARK: - This is an important region of the code.

        let bar = 1

        let baz = 2
      }
      """

    XCTAssertFormatting(
      BlankLineBetweenMembers.self,
      input: input,
      expected: expected,
      configuration: config)
  }

  func testTrailingCommentsAreKeptTrailing() {
    XCTAssertFormatting(
      BlankLineBetweenMembers.self,
      input:
        """
        enum Foo {
          static let foo = "foo"  // foo
          static let bar = "bar"  // bar
          // this should move down
          static let baz = "baz"  // baz
          static let andSo = "should"  // this
        }
        """,
      expected:
        """
        enum Foo {
          static let foo = "foo"  // foo
          static let bar = "bar"  // bar

          // this should move down
          static let baz = "baz"  // baz

          static let andSo = "should"  // this
        }
        """)
  }
}
