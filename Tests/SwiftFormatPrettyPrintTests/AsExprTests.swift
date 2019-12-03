public class AsExprTests: PrettyPrintTestCase {
  public func testWithoutPunctuation() {
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

  public func testWithPunctuation() {
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
