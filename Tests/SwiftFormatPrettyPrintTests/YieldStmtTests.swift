final class YieldStmtTests: PrettyPrintTestCase {
  func testBasic() {
    let input =
      """
      var foo: Int {
        _read{
          yield 1234567890
        }
        _modify{
          var someLongVariable = 0
          yield &someLongVariable
        }
      }
      """

    let expected =
      """
      var foo: Int {
        _read {
          yield
            1234567890
        }
        _modify {
          var someLongVariable =
            0
          yield
            &someLongVariable
        }
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 19)
  }
}
