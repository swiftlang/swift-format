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
