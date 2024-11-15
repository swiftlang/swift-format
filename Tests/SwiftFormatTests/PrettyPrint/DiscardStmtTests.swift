final class DiscardStmtTests: PrettyPrintTestCase {
  func testDiscard() {
    assertPrettyPrintEqual(
      input: """
        discard self
        """,
      expected: """
        discard self

        """,
      linelength: 9
    )
  }
}
