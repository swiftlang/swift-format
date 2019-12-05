public class SwitchStmtTests: PrettyPrintTestCase {
  public func testBasicSwitch() {
    let input =
      """
      switch someCharacter {
      case "a":
        print("The first letter")
        let a = 1 + 2
      case "b":
        print("The second letter")
      default:
        print("Some other character")
      }
      switch value1 + value2 + value3 + value4 {
      case "a":
        print("The first letter")
        let a = 1 + 2
      case "b":
        print("The second letter")
      default:
        print("Some other character")
      }
      """

    let expected =
      """
      switch someCharacter {
      case "a":
        print("The first letter")
        let a = 1 + 2
      case "b":
        print("The second letter")
      default:
        print("Some other character")
      }
      switch value1 + value2 + value3
        + value4
      {
      case "a":
        print("The first letter")
        let a = 1 + 2
      case "b":
        print("The second letter")
      default:
        print("Some other character")
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 35)
  }

  public func testSwitchCases() {
    let input =
      """
      switch someCharacter {
      case value1 + value2 + value3 + value4:
        let a = 1 + 2
      default:
        print("Some other character")
      }
      """

    let expected =
      """
      switch someCharacter {
      case value1 + value2 + value3
        + value4:
        let a = 1 + 2
      default:
        print("Some other character")
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 35)
  }

  public func testSwitchCompoundCases() {
    let input =
      """
      switch someChar {
      case "a": print("a")
      case "b", "c": print("bc")
      case "d", "e", "f", "g", "h": print("defgh")
      default: print("default")
      }
      """

    let expected =
      """
      switch someChar {
      case "a": print("a")
      case "b", "c":
        print("bc")
      case "d", "e", "f",
        "g", "h":
        print("defgh")
      default:
        print("default")
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 20)
  }

  public func testNestedSwitch() {
    let input =
      """
      myloop: while a != b {
        switch a + b {
        case firstValue: break myloop
        case secondVale:
          let c = 123
          var d = 456
        default: a += b
        }
      }
      """

    let expected =
      """
      myloop: while a != b {
        switch a + b {
        case firstValue: break myloop
        case secondVale:
          let c = 123
          var d = 456
        default: a += b
        }
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 35)
  }

  public func testSwitchValueBinding() {
    let input =
      """
      switch someValue {
      case let thisval:
        let c = 123
        var d = 456 + thisval
      }
      switch somePoint {
      case (let x, 0): print(x)
      case (0, let y): print(y)
      case let (x, y): print(x + y)
      }
      switch anotherPoint {
      case (let distance, 0), (0, let distance): print(distance)
      case (let distance, 0), (0, let distance), (let distance, 10): print(distance)
      default: print("A message")
      }
      switch pointy {
      case let (x, y) where x == y: print("Equal")
      case let (x, y) where x == -y: print("Opposite sign")
      case let (reallyLongName, anotherLongName) where reallyLongName == -anotherLongName: print("Opposite sign")
      case let (x, y): print("Arbitrary value")
      }
      """

    let expected =
      """
      switch someValue {
      case let thisval:
        let c = 123
        var d = 456 + thisval
      }
      switch somePoint {
      case (let x, 0): print(x)
      case (0, let y): print(y)
      case let (x, y): print(x + y)
      }
      switch anotherPoint {
      case (let distance, 0), (0, let distance):
        print(distance)
      case (let distance, 0), (0, let distance),
        (let distance, 10):
        print(distance)
      default: print("A message")
      }
      switch pointy {
      case let (x, y) where x == y: print("Equal")
      case let (x, y) where x == -y:
        print("Opposite sign")
      case let (reallyLongName, anotherLongName)
      where reallyLongName == -anotherLongName:
        print("Opposite sign")
      case let (x, y): print("Arbitrary value")
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 45)
  }

  public func testUnknownDefault() {
    let input =
      """
      switch foo {
      @unknown default: bar()
      }
      """

    let expected =
      """
      switch foo {
      @unknown default:
        bar()
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 20)
  }

  public func testNewlinesDisambiguatingWhereClauses() {
    let input =
      """
      switch foo {
      case 1, 2, 3:
        break
      case 4 where bar(), 5, 6:
        break
      case 7, 8, 9 where bar():
        break
      case 10 where bar(), 11 where bar(), 12 where bar():
        break
      case 13, 14 where bar(), 15, 16 where bar():
        break
      }
      """

    let expected =
      """
      switch foo {
      case 1, 2, 3:
        break
      case 4 where bar(), 5, 6:
        break
      case 7, 8,
        9 where bar():
        break
      case 10 where bar(), 11 where bar(), 12 where bar():
        break
      case 13,
        14 where bar(), 15,
        16 where bar():
        break
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 80)
  }
}
