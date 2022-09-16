import SwiftFormatConfiguration

final class OperatorDeclTests: PrettyPrintTestCase {
  func testOperatorDecl() {
    let input =
      """
      prefix operator ^*^
      postfix operator !**!
      infix operator *%*
      infix operator *%*: PrecedenceGroup
      """

    let expected =
      """
      prefix operator ^*^
      postfix operator !**!
      infix operator *%*
      infix operator *%* :
        PrecedenceGroup

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 25)

    let expectedShorter =
      """
      prefix
        operator
        ^*^
      postfix
        operator
        !**!
      infix
        operator
        *%*
      infix
        operator
        *%* :
          PrecedenceGroup

      """

    assertPrettyPrintEqual(input: input, expected: expectedShorter, linelength: 10)
  }

  func testPrecedenceGroups() {
    let input =
      """
      precedencegroup FooGroup{higherThan:Group1,Group2 lowerThan:Group3,Group4 associativity:left assignment:false}
      """

    let expected =
      """
      precedencegroup FooGroup {
        higherThan: Group1, Group2
        lowerThan: Group3, Group4
        associativity: left
        assignment: false
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 30)

    let expectedShorter =
      """
      precedencegroup
        FooGroup
      {
        higherThan:
          Group1,
          Group2
        lowerThan:
          Group3,
          Group4
        associativity:
          left
        assignment:
          false
      }

      """

    assertPrettyPrintEqual(input: input, expected: expectedShorter, linelength: 10)
  }

  func testDesignatedTypes() {
    let input =
      """
      infix operator *%*: PrecedenceGroup, Bool, Int, String
      """

    let expected =
      """
      infix operator *%* :
        PrecedenceGroup, Bool,
        Int, String

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 25)

    let expectedShorter =
      """
      infix
        operator
        *%* :
          PrecedenceGroup,
          Bool,
          Int,
          String

      """

    assertPrettyPrintEqual(input: input, expected: expectedShorter, linelength: 10)
  }
}
