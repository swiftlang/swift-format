final class CopyExprTests: PrettyPrintTestCase {
  func testCopy() {
    assertPrettyPrintEqual(
      input: """
        let x = copy y
        """,
      expected: """
        let x =
          copy y

        """,
      linelength: 13
    )
  }
}
