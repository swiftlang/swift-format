final class TypeAliasTests: PrettyPrintTestCase {
  func testTypealias() {
    let input =
      """
      typealias MyAlias = Int
      public typealias MyAlias = Array<Double>
      typealias MyAlias = (Bool, Int)
      typealias MyAlias = (SomeType?) -> Bool
      typealias MyAlias = (_ a: Int, _ b: Double) -> Bool
      typealias MyAlias = (_ a: Int, _ b: Double, _ c: Bool, _ d: String) -> Bool
      """

    let expected =
      """
      typealias MyAlias = Int
      public typealias MyAlias = Array<Double>
      typealias MyAlias = (Bool, Int)
      typealias MyAlias = (SomeType?) -> Bool
      typealias MyAlias = (_ a: Int, _ b: Double) -> Bool
      typealias MyAlias = (
        _ a: Int, _ b: Double, _ c: Bool, _ d: String
      ) -> Bool

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 60)
  }

  func testTypealiasAttributes() {
    let input =
      """
      @objc typealias MyAlias = Int
      @objc @available(swift 4.0) typealias MyAlias = Int
      """

    let expected =
      """
      @objc typealias MyAlias = Int
      @objc @available(swift 4.0) typealias MyAlias = Int

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 60)
  }

  func testTypealiasGenericTests() {
    let input =
      """
      typealias MyDict<Key: Hashable> = Dictionary<Key, Int>
      typealias MyType<T> = AnotherType<String, Int>
      """

    let expected =
      """
      typealias MyDict<Key: Hashable> = Dictionary<Key, Int>
      typealias MyType<T> = AnotherType<String, Int>

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 60)
  }
}
