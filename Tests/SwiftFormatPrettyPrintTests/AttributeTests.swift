public class AttributeTests: PrettyPrintTestCase {
  public func testAttributeParamSpacing() {
    let input =
      """
      @available(iOS 9.0, *)
      func f() {}
      @available(*, unavailable, renamed: "MyRenamedProtocol")
      func f() {}
      @available(iOS 10.0, macOS 10.12, *)
      func f() {}
      """

    let expected =
      """
      @available(iOS 9.0, *)
      func f() {}
      @available(*, unavailable, renamed: "MyRenamedProtocol")
      func f() {}
      @available(iOS 10.0, macOS 10.12, *)
      func f() {}

      """

    // Attributes should not wrap.
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 15)
  }
}
