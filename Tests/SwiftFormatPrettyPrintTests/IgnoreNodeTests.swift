public class IgnoreNodeTests: PrettyPrintTestCase {
  public func atestIgnoreCodeBlockListItems() {
    let input =
      """
            x      = 4       + 5 // This comment stays here.

            // swift-format-ignore
            x   =
      4 + 5 +
       6

      // swift-format-ignore
      let foo = bar( a, b,
      c)
      let baz = bar( a, b,
       c)

              /// some other unrelated comment

      // swift-format-ignore
      func foo()
        throws ->
          (Bool, Bool, Bool) {
            var a
            =                                                4 + another + very + long + argument

            var b =        5
      }

      // swift-format-ignore
      if someExtremelyLongCondition && anotherVeryLongCondition && thisOneOverflowsTheLineLength
             + foo + bar + baz {
          var a = b // comment
          // comment 2
          var c
           = d
      }

      if someExtremelyLongCondition && anotherVeryLongCondition && thisOneOverflowsTheLineLength
             + foo + bar + baz {
          // swift-format-ignore
          var a = b // comment
          // comment 2
          var c
           = d
      }
      """

    let expected =
      """
      x = 4 + 5  // This comment stays here.

      // swift-format-ignore
      x   =
      4 + 5 +
       6

      // swift-format-ignore
      let foo = bar( a, b,
      c)
      let baz = bar(
        a, b,
        c)

      /// some other unrelated comment

      // swift-format-ignore
      func foo()
        throws ->
          (Bool, Bool, Bool) {
            var a
            =                                                4 + another + very + long + argument

            var b =        5
      }

      // swift-format-ignore
      if someExtremelyLongCondition && anotherVeryLongCondition && thisOneOverflowsTheLineLength
             + foo + bar + baz {
          var a = b // comment
          // comment 2
          var c
           = d
      }

      if someExtremelyLongCondition
        && anotherVeryLongCondition
        && thisOneOverflowsTheLineLength
          + foo + bar + baz
      {
        // swift-format-ignore
        var a = b // comment
        // comment 2
        var c = d
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 50)
  }

  public func testIgnoreMemberDeclListItems() {
    let input =
      """
          struct Foo {
            // swift-format-ignore
            private var baz: Bool {
                return foo +
                 bar + // poorly placed comment
                  false
            }

            // swift-format-ignore
            var a = true    // line comment
                            // aligned line comment
            var b = false  // correct trailing comment

      // swift-format-ignore
      var c = 0 +
          1
          + (2 + 3)
      }
      """

    let expected =
      """
      struct Foo {
        // swift-format-ignore
        private var baz: Bool {
                return foo +
                 bar + // poorly placed comment
                  false
            }

        // swift-format-ignore
        var a = true    // line comment
        // aligned line comment
        var b = false  // correct trailing comment

        // swift-format-ignore
        var c = 0 +
          1
          + (2 + 3)
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 50)
  }

  public func testIgnoresNestedMembers() {
    let input =
      """
      // swift-format-ignore
          struct Foo {
            private var baz: Bool {
                return foo +
                 bar + // poorly placed comment
                  false
            }

            var a = true    // line comment
                            // aligned line comment
            var b = false  // correct trailing comment

      var c = 0 +
          1
          + (2 + 3)
      }
      """

    let expected =
      """
      // swift-format-ignore
      struct Foo {
            private var baz: Bool {
                return foo +
                 bar + // poorly placed comment
                  false
            }

            var a = true    // line comment
                            // aligned line comment
            var b = false  // correct trailing comment

      var c = 0 +
          1
          + (2 + 3)
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 50)
  }

  public func testInvalidComment() {
    let input =
      """
      // swift-format-ignore: RuleName
      x        =                  1 +
      2

      /// swift-format-ignore
      x      =    a+1+2+3+4

      /** swift-format-ignore */
      x      =    foo -
      bar

      // I could use swift-format-ignore here if I wanted my code to look bad.
      x     = foo+bar+baz
      """

    let expected =
      """
      // swift-format-ignore: RuleName
      x = 1 + 2

      /// swift-format-ignore
      x = a + 1 + 2 + 3 + 4

      /** swift-format-ignore */
      x = foo - bar

      // I could use swift-format-ignore here if I wanted my code to look bad.
      x = foo + bar + baz

      """

       assertPrettyPrintEqual(input: input, expected: expected, linelength: 50)
  }

  public func testValidComment() {
    let input =
      """
      // swift-format-ignore
      x=y+b+c

      /// Pragma mark: - Special Region

      // swift-format-ignore
      // x is important
      x        =                  1 +
      2

      /* swift-format-ignore */
      x      =    a+1+2+3+4
      """

       let expected =
         """
         // swift-format-ignore
         x=y+b+c

         /// Pragma mark: - Special Region

         // swift-format-ignore
         // x is important
         x        =                  1 +
         2

         /* swift-format-ignore */
         x      =    a+1+2+3+4

         """

       assertPrettyPrintEqual(input: input, expected: expected, linelength: 50)
  }

  public func testIgnoreInvalidAfterFirstToken() {
    let input =
      """
      public  // swift-format-ignore
        struct MyStruct {
          var a:Foo=3
        }

      """

    let expected =
      """
      public  // swift-format-ignore
        struct MyStruct
      {
        var a: Foo = 3
      }

      """

       assertPrettyPrintEqual(input: input, expected: expected, linelength: 50)
  }
}
