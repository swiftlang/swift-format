import SwiftFormatConfiguration

final class SwitchStmtTests: PrettyPrintTestCase {
  func testBasicSwitch() {
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

  func testSwitchCases() {
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

  func testSwitchCompoundCases() {
    let input =
      """
      switch someChar {
      case "a": print("a")
      case "b", "c": print("bc")
      case "d", "e", "f", "g", "h": print("defgh")
      case someVeryLongVarName, someOtherLongVarName: foo(a: [1, 2, 3, 4, 5])
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
      case someVeryLongVarName,
        someOtherLongVarName:
        foo(a: [
          1, 2, 3, 4, 5,
        ])
      default:
        print("default")
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 20)
  }

  func testNestedSwitch() {
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

  func testSwitchValueBinding() {
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

  func testUnknownDefault() {
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

  func testNewlinesDisambiguatingWhereClauses() {
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

  func testSwitchSequenceExprCases() {
    let input =
      """
      switch foo {
      case bar && baz
        + quxxe:
        break
      case baz where bar && (quxxe
        + 10000):
        break
      }
      """

    let expected =
      """
      switch foo {
      case bar
        && baz
          + quxxe:
        break
      case baz
      where bar
        && (quxxe
          + 10000):
        break
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 40)
  }

  func testLabeledSwitchStmt() {
    let input =
      """
      label:switch foo {
      case bar:
        callForBar()
      case baz:
        callForBaz()
      }
      someVeryExtremelyLongLabel: switch foo {
      case bar:
        callForBar()
      case baz:
        callForBaz()
      }
      """

    let expected =
      """
      label: switch foo {
      case bar:
        callForBar()
      case baz:
        callForBaz()
      }
      someVeryExtremelyLongLabel: switch foo
      {
      case bar:
        callForBar()
      case baz:
        callForBaz()
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 20)
  }

  func testConditionalCases() {
    let input =
      """
      switch foo {
      #if CONDITION_A
      case bar:
        callForBar()
      #endif
      case baz:
        callForBaz()
      }
      switch foo2 {
      case bar2:
        callForBar()
      #if CONDITION_B
      case baz2:
        callForBaz()
      #endif
      }
      """

    let expected =
      """
      switch foo {
      #if CONDITION_A
        case bar:
          callForBar()
      #endif
      case baz:
        callForBaz()
      }
      switch foo2 {
      case bar2:
        callForBar()
      #if CONDITION_B
        case baz2:
          callForBaz()
      #endif
      }

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 40)
  }

  func testConditionalCasesIndenting() {
    let input =
      """
      switch foo {
      #if CONDITION_A
      case bar:
        callForBar()
      #endif
      case baz:
        callForBaz()
      }
      switch foo2 {
      case bar2:
        callForBar()
      #if CONDITION_B
      case baz2:
        callForBaz()
      #endif
      }
      """

    let expected =
      """
      switch foo {
        #if CONDITION_A
          case bar:
            callForBar()
        #endif
        case baz:
          callForBaz()
      }
      switch foo2 {
        case bar2:
          callForBar()
        #if CONDITION_B
          case baz2:
            callForBaz()
        #endif
      }

      """

    var configuration = Configuration()
    configuration.indentSwitchCaseLabels = true
    assertPrettyPrintEqual(
      input: input, expected: expected, linelength: 40, configuration: configuration)
  }
}
