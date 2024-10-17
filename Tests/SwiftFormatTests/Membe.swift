final class MemberTypeIdentifierTests: PrettyPrintTestCase {
  func testMemberTypes() {
    let input =
      """
      let a: One.Two.Three.Four.Five
      let b: One.Two.Three<Four, Five>
      """

    let expected =
      """
      let a:
        One.Two.Three
          .Four.Five
      let b:
        One.Two
          .Three<
            Four,
            Five
          >

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 15)
  }
}
