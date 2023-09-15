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
