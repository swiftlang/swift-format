final class ParameterPackTests: PrettyPrintTestCase {
  func testGenericPackArgument() {
    assertPrettyPrintEqual(
      input: """
        func someFunction<each P>() {}
        struct SomeStruct<each P> {}
        """,
      expected: """
        func someFunction<
          each P
        >() {}
        struct SomeStruct<
          each P
        > {}

        """,
      linelength: 22
    )
  }

  func testPackExpansionsAndElements() {
    assertPrettyPrintEqual(
      input: """
        repeat checkNilness(of: each value)
        """,
      expected: """
        repeat checkNilness(
          of: each value)

        """,
      linelength: 25
    )

    assertPrettyPrintEqual(
      input: """
        repeat f(of: each v)
        """,
      expected: """
        repeat
          f(
            of:
              each v
          )

        """,
      linelength: 7
    )
  }
}
