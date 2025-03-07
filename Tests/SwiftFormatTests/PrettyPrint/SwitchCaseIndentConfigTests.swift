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

/// Tests the `indentSwitchCaseLabels` config option
final class SwitchCaseIndentConfigTests: PrettyPrintTestCase {

  /// Tests that setting `indentSwitchCaseLabels` to `false` and not indenting `case` statements
  /// does not change the input.
  func testIndentationNotConfiguredNotInput() {
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
      switch value1 + value2 + value3 {
      case "a":
        print("The first letter")
        let a = 1 + 2
      case "b":
        print("The second letter")
      default:
        print("Some other character")
      }

      """

    let expected = input

    var config = Configuration.forTesting
    config.indentSwitchCaseLabels = false

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 35, configuration: config)
  }

  /// Tests that setting `indentSwitchCaseLabels` to `false` and indenting `case` statements
  /// removes that indentation.
  func testIndentationNotConfiguredButInput() {
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
      switch value1 + value2 + value3 {
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
      switch value1 + value2 + value3 {
      case "a":
        print("The first letter")
        let a = 1 + 2
      case "b":
        print("The second letter")
      default:
        print("Some other character")
      }

      """

    var config = Configuration.forTesting
    config.indentSwitchCaseLabels = false

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 35, configuration: config)
  }

  /// Tests that setting `indentSwitchCaseLabels` to `true` and not indenting `case` statements
  /// adds the configured indentation.
  func testIndentationConfiguredNotInput() {
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
      switch value1 + value2 + value3 {
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
      switch value1 + value2 + value3 {
        case "a":
          print("The first letter")
          let a = 1 + 2
        case "b":
          print("The second letter")
        default:
          print("Some other character")
      }

      """

    var config = Configuration.forTesting
    config.indentSwitchCaseLabels = true

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 35, configuration: config)
  }

  /// Tests that setting `indentSwitchCaseLabels` to `true` and indenting `case` statements does
  /// not change the input.
  func testIndentationConfiguredAndInput() {
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
      switch value1 + value2 + value3 {
        case "a":
          print("The first letter")
          let a = 1 + 2
        case "b":
          print("The second letter")
        default:
          print("Some other character")
      }

      """

    let expected = input

    var config = Configuration.forTesting
    config.indentSwitchCaseLabels = true

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 35, configuration: config)
  }

  /// Tests that setting `indentSwitchCaseLabels` to `false` and not indenting the `case` body
  /// indents the body but leaves the `case` statement unindented.
  func testIndentationNotConfiguredCaseBodyNotIndented() {
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
      switch value1 + value2 + value3 {
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
      switch value1 + value2 + value3 {
      case "a":
        print("The first letter")
        let a = 1 + 2
      case "b":
        print("The second letter")
      default:
        print("Some other character")
      }

      """

    var config = Configuration.forTesting
    config.indentSwitchCaseLabels = false

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 35, configuration: config)
  }

  /// Tests that setting `indentSwitchCaseLabels` to `true` and indenting the `case` statement but
  /// not the `case` body indents the body but leaves the `case` statement as input.
  func testIndentationConfiguredCaseBodyNotIndented() {
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
      switch value1 + value2 + value3 {
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
      switch value1 + value2 + value3 {
        case "a":
          print("The first letter")
          let a = 1 + 2
        case "b":
          print("The second letter")
        default:
          print("Some other character")
      }

      """

    var config = Configuration.forTesting
    config.indentSwitchCaseLabels = true

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 35, configuration: config)
  }

  /// Tests that setting `indentSwitchCaseLabels` to `true` and indenting neither the `case` body
  /// nor the `case` statement itself indents the body twice and the `case` statement once.
  func testIndentationConfiguredCaseBodyAndStatementNotIndented() {
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
      switch value1 + value2 + value3 {
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
      switch value1 + value2 + value3 {
        case "a":
          print("The first letter")
          let a = 1 + 2
        case "b":
          print("The second letter")
        default:
          print("Some other character")
      }

      """

    var config = Configuration.forTesting
    config.indentSwitchCaseLabels = true

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 35, configuration: config)
  }

  /// Tests that setting `indentSwitchCaseLabels` to `true` and providing the `case` body on the
  /// same line as the statement (with the whole line indented) does not change the input.
  func testIndentationConfiguredCaseBodySameLine() {
    let input =
      """
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
        case let (x, y): print("Arbitrary value")
      }

      """

    let expected = input

    var config = Configuration.forTesting
    config.indentSwitchCaseLabels = true

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 80, configuration: config)
  }
}
