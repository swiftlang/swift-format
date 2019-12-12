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
      let x =
        firstVariable
        + secondVariable
        / thirdVariable
        + fourthVariable
      let y: Int =
        anotherVar + moreVar
      let (w, z, s):
        (Int, Double, Bool) =
          firstTuple + secondTuple

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
      @NSCopying let areallylongvarname: Int =
        123
      @NSCopying @NSManaged
      let areallylongvarname: Int = 123

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 40)
  }

  public func testMultipleBindings() {
    let input =
      """
      let a = 100, b = 200, c = 300, d = 400, e = 500, f = 600
      let a = 5, anotherReallyLongVariableName = something, longVariableName = longFunctionCall()
      let a = letsForceTheFirstOneToWrapAsWell, longVariableName = longFunctionCall()
      let a = firstThing + secondThing + thirdThing, b = firstThing + secondThing + thirdThing
      """

    let expected =
      """
      let a = 100, b = 200, c = 300, d = 400,
        e = 500, f = 600
      let a = 5,
        anotherReallyLongVariableName =
          something,
        longVariableName = longFunctionCall()
      let
        a = letsForceTheFirstOneToWrapAsWell,
        longVariableName = longFunctionCall()
      let
        a =
          firstThing + secondThing
          + thirdThing,
        b =
          firstThing + secondThing
          + thirdThing

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 40)
  }

  public func testMultipleBindingsWithTypeAnnotations() {
    let input =
      """
      let a: Int = 100, b: ReallyLongTypeName = 200, c: (AnotherLongTypeName, AnotherOne) = 300
      """

    let expected =
      """
      let a: Int = 100,
        b: ReallyLongTypeName = 200,
        c: (AnotherLongTypeName, AnotherOne) =
          300

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 40)
  }
}
