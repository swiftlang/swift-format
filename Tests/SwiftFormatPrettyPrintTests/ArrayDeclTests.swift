public class ArrayDeclTests: PrettyPrintTestCase {
  public func testBasicArrays() {
    let input =
      """
      let a = [1, 2, 3,]
      let a: [Bool] = [false, true, true, false]
      let a = [11111111, 2222222, 33333333, 444444]
      let a = [11111111, 2222222, 33333333, 4444444]
      let a: [String] = ["One", "Two", "Three", "Four"]
      let a: [String] = ["One", "Two", "Three", "Four", "Five", "Six", "Seven"]
      let a: [String] = ["One", "Two", "Three", "Four", "Five", "Six", "Seven",]
      let a: [String] = [
        "One", "Two", "Three", "Four", "Five",
        "Six", "Seven", "Eight",
      ]
      """

    let expected =
      """
      let a = [1, 2, 3]
      let a: [Bool] = [false, true, true, false]
      let a = [11111111, 2222222, 33333333, 444444]
      let a = [
        11111111, 2222222, 33333333, 4444444,
      ]
      let a: [String] = [
        "One", "Two", "Three", "Four",
      ]
      let a: [String] = [
        "One", "Two", "Three", "Four", "Five",
        "Six", "Seven",
      ]
      let a: [String] = [
        "One", "Two", "Three", "Four", "Five",
        "Six", "Seven",
      ]
      let a: [String] = [
        "One", "Two", "Three", "Four", "Five",
        "Six", "Seven", "Eight",
      ]

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 45)
  }

  public func testArrayOfFunctions() {
    let input =
      """
      let A = [(Int, Double) -> Bool]()
      let A = [(Int, Double) throws -> Bool]()
      """

    let expected =
      """
      let A = [(Int, Double) -> Bool]()
      let A = [(Int, Double) throws -> Bool]()

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 45)
  }
}
