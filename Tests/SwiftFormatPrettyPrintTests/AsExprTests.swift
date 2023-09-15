import XCTest

final class AsExprTests: PrettyPrintTestCase {
  func testWithoutPunctuation() throws {
    let input =
      """
      func foo() {
        let a = b as Int
        a = b as Int
        let reallyLongVariableName = x as ReallyLongTypeName
        reallyLongVariableName = x as ReallyLongTypeName
      }
      """

    let expected =
      """
      func foo() {
        let a = b as Int
        a = b as Int
        let reallyLongVariableName =
          x as ReallyLongTypeName
        reallyLongVariableName =
          x as ReallyLongTypeName
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 40)
  }

  func testWithPunctuation() throws {
    let input =
      """
      func foo() {
        let a = b as? Int
        a = b as? Int
        let c = d as! Int
        c = d as! Int
        let reallyLongVariableName = x as? ReallyLongTypeName
        reallyLongVariableName = x as? ReallyLongTypeName
      }
      """

    let expected =
      """
      func foo() {
        let a = b as? Int
        a = b as? Int
        let c = d as! Int
        c = d as! Int
        let reallyLongVariableName =
          x as? ReallyLongTypeName
        reallyLongVariableName =
          x as? ReallyLongTypeName
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 40)
  }
}
