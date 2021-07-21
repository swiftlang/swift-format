import SwiftFormatConfiguration

final class AwaitExprTests: PrettyPrintTestCase {
  func testBasicAwaits() {
    let input =
      """
      let a = await asynchronousFunction()
      let b = await longerAsynchronousFunction()
      let c = await evenLongerAndLongerAsynchronousFunction()
      """

    let expected =
      """
      let a = await asynchronousFunction()
      let b =
        await longerAsynchronousFunction()
      let c =
        await
        evenLongerAndLongerAsynchronousFunction()

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 36)
  }

  func testAwaitKeywordBreaking() {
    let input =
      """
      let aVeryLongArgumentName = await foo.bar()
      let aVeryLongArgumentName = await
        foo.bar()
      let abc = await foo.baz().quxxe(a, b, c).bar()
      let abc = await foo
        .baz().quxxe(a, b, c).bar()
      let abc = await [1, 2, 3, 4, 5, 6, 7].baz().quxxe(a, b, c).bar()
      let abc = await [1, 2, 3, 4, 5, 6, 7]
        .baz().quxxe(a, b, c).bar()
      let abc = await foo.baz().quxxe(a, b, c).bar[0]
      let abc = await foo
        .baz().quxxe(a, b, c).bar[0]
      let abc = await
        foo
        .baz().quxxe(a, b, c).bar[0]
      """

    let expected =
      """
      let aVeryLongArgumentName =
        await foo.bar()
      let aVeryLongArgumentName =
        await foo.bar()
      let abc = await foo.baz().quxxe(a, b, c)
        .bar()
      let abc =
        await foo
        .baz().quxxe(a, b, c).bar()
      let abc = await [1, 2, 3, 4, 5, 6, 7]
        .baz().quxxe(a, b, c).bar()
      let abc = await [1, 2, 3, 4, 5, 6, 7]
        .baz().quxxe(a, b, c).bar()
      let abc = await foo.baz().quxxe(a, b, c)
        .bar[0]
      let abc =
        await foo
        .baz().quxxe(a, b, c).bar[0]
      let abc =
        await foo
        .baz().quxxe(a, b, c).bar[0]

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 42)
  }

  func testTryAwaitKeywordBreaking() {
    let input =
      """
      let aVeryLongArgumentName = try await foo.bar()
      let aVeryLongArgumentName = try await
        foo.bar()
      let abc = try await foo.baz().quxxe(a, b, c).bar()
      let abc = try await foo
        .baz().quxxe(a, b, c).bar()
      let abc = try await [1, 2, 3, 4, 5, 6, 7].baz().quxxe(a, b, c).bar()
      let abc = try await [1, 2, 3, 4, 5, 6, 7]
        .baz().quxxe(a, b, c).bar()
      let abc = try await foo.baz().quxxe(a, b, c).bar[0]
      let abc = try await foo
        .baz().quxxe(a, b, c).bar[0]
      let abc = try await
        foo
        .baz().quxxe(a, b, c).bar[0]
      let abc = try await thisIsASuperblyExtremelyVeryLongFunctionName()
      """

    let expected =
      """
      let aVeryLongArgumentName =
        try await foo.bar()
      let aVeryLongArgumentName =
        try await foo.bar()
      let abc = try await foo.baz().quxxe(a, b, c)
        .bar()
      let abc =
        try await foo
        .baz().quxxe(a, b, c).bar()
      let abc = try await [1, 2, 3, 4, 5, 6, 7]
        .baz().quxxe(a, b, c).bar()
      let abc = try await [1, 2, 3, 4, 5, 6, 7]
        .baz().quxxe(a, b, c).bar()
      let abc = try await foo.baz().quxxe(a, b, c)
        .bar[0]
      let abc =
        try await foo
        .baz().quxxe(a, b, c).bar[0]
      let abc =
        try await foo
        .baz().quxxe(a, b, c).bar[0]
      let abc =
        try await
        thisIsASuperblyExtremelyVeryLongFunctionName()

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 46)
  }
}
