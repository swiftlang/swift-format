final class ConsumeExprTests: PrettyPrintTestCase {
  func testConsume() {
    assertPrettyPrintEqual(
      input: """
        let x = consume y
        """,
      expected: """
        let x =
          consume y

        """,
      linelength: 16
    )
  }
}
