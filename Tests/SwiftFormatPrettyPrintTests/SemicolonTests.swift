public class SemiColonTypeTests: PrettyPrintTestCase {
  public func testSemicolon() {
    let input =
      """
      var foo = false
      guard !foo else { return }; defer { foo = true }

      struct Foo {
        var foo = false; var bar = true; var baz = false
      }
      """

    assertPrettyPrintEqual(input: input, expected: input + "\n", linelength: 50)
  }
    
  public func testNoSemicolon() {
    let input =
      """
       var foo = false
       guard !foo else { return }
       defer { foo = true }

       struct Foo {
         var foo = false
         var bar = true
         var baz = false
       }
       """

    assertPrettyPrintEqual(input: input, expected: input + "\n", linelength: 50)
  }
}
