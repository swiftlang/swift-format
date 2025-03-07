//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2025 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import SwiftFormat

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
