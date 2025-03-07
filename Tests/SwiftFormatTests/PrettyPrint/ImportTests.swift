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

final class ImportTests: PrettyPrintTestCase {
  func testImports() {
    let input =
      """
      import someModule
      import someLongerModule.withSubmodules
      import class MyModule.MyClass
      import struct MyModule.MyStruct
      @testable import testModule

      @_spi(
        STP
      )
      @testable
      import testModule
      """

    let expected =
      """
      import someModule
      import someLongerModule.withSubmodules
      import class MyModule.MyClass
      import struct MyModule.MyStruct
      @testable import testModule

      @_spi(STP) @testable import testModule

      """

    // Imports should not wrap
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 5)
  }
}
