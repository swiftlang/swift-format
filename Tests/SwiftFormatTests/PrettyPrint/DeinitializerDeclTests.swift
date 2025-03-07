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

final class DeinitializerDeclTests: PrettyPrintTestCase {
  func testBasicDeinitializerDeclarations() {
    let input =
      """
      struct Struct {
        deinit {
            print("Hello World")
            let a = 23
        }
        deinit { let a = 23 }
        deinit { let a = "AAAA BBBB CCCC DDDD EEEE FFFF" }
      }
      """

    let expected =
      """
      struct Struct {
        deinit {
          print("Hello World")
          let a = 23
        }
        deinit { let a = 23 }
        deinit {
          let a = "AAAA BBBB CCCC DDDD EEEE FFFF"
        }
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 50)
  }

  func testDeinitializerAttributes() {
    let input =
      """
      struct Struct {
        @objc deinit {
          let a = 123
          let b = "abc"
        }
        @objc @inlinable deinit {
          let a = 123
          let b = "abc"
        }
        @objc @available(swift 4.0) deinit {
          let a = 123
          let b = "abc"
        }
      }
      """

    let expected =
      """
      struct Struct {
        @objc deinit {
          let a = 123
          let b = "abc"
        }
        @objc @inlinable deinit
        {
          let a = 123
          let b = "abc"
        }
        @objc
        @available(swift 4.0)
        deinit {
          let a = 123
          let b = "abc"
        }
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 26)
  }

  func testEmptyDeinitializer() {
    // The comment inside the class prevents it from *also* being collapsed onto a single line.
    let input = """
      class X {
        //
        deinit {}
      }
      """
    assertPrettyPrintEqual(input: input, expected: input + "\n", linelength: 50)

    let wrapped = """
      class X {
        //
        deinit {
        }
      }

      """
    assertPrettyPrintEqual(input: input, expected: wrapped, linelength: 10)
  }
}
