public class VariableDeclarationTests: PrettyPrintTestCase {
  public func testBasicVariableDecl() {
    let input =
      """
      let x = firstVariable + secondVariable / thirdVariable + fourthVariable
      let y: Int = anotherVar + moreVar
      let (w, z, s): (Int, Double, Bool) = firstTuple + secondTuple
      """

    let expected =
      """
      let x = firstVariable
        + secondVariable
        / thirdVariable
        + fourthVariable
      let y: Int = anotherVar
        + moreVar
      let (w, z, s):
        (Int, Double, Bool)
        = firstTuple + secondTuple

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 30)
  }

  public func testVariableDeclWithAttributes() {
    let input =
      """
      @NSCopying let a: Int = 123
      @NSCopying @NSManaged let a: Int = 123
      @NSCopying let areallylongvarname: Int = 123
      @NSCopying @NSManaged let areallylongvarname: Int = 123
      """

    let expected =
      """
      @NSCopying let a: Int = 123
      @NSCopying @NSManaged let a: Int = 123
      @NSCopying let areallylongvarname: Int
        = 123
      @NSCopying @NSManaged
      let areallylongvarname: Int = 123

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 40)
  }
}
