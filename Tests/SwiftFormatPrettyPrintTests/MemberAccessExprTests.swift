public class MemberAccessExprTests: PrettyPrintTestCase {
  public func testMemberAccess() {
    let input =
      """
      let a = one.two.three.four.five
      let b = (c as TypeD).one.two.three.four
      """

    let expected =
      """
      let a = one.two
        .three.four
        .five
      let b = (
        c as TypeD
      ).one.two.three
        .four

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 15)
  }

  public func testImplicitMemberAccess() {
    let input =
      """
      let array = [.first, .second, .third]
      """

    let expected =
      """
      let array = [
        .first,
        .second,
        .third
      ]

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 15)
  }

  public func testMethodChainingWithClosures() {
    let input =
      """
      let result = [1, 2, 3, 4, 5]
          .filter{$0 % 2 == 0}
          .map{$0 * $0}
      """

    let expected =
      """
      let result = [1, 2, 3, 4, 5]
        .filter { $0 % 2 == 0 }
        .map { $0 * $0 }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 30)
  }

  public func testMethodChainingWithClosuresFullWrap() {
    let input =
      """
      let result = [1, 2, 3, 4, 5].filter { $0 % 2 == 0 }.map { $0 * $0 }
      """

    let expected =
      """
      let result = [
        1, 2, 3, 4, 5
      ].filter {
        $0 % 2 == 0
      }.map { $0 * $0 }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 20)
  }
}
