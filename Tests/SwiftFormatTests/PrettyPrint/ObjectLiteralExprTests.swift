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

final class ObjectLiteralExprTests: PrettyPrintTestCase {
  func testColorLiteral_noPackArguments() {
    let input =
      """
      #colorLiteral()
      #colorLiteral(red: 1.0)
      #colorLiteral(red: 1.0, green: 1.0)
      #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
      """

    let expected =
      """
      #colorLiteral()
      #colorLiteral(red: 1.0)
      #colorLiteral(
        red: 1.0,
        green: 1.0
      )
      #colorLiteral(
        red: 1.0,
        green: 1.0,
        blue: 1.0,
        alpha: 1.0
      )

      """

    var config = Configuration.forTesting
    config.lineBreakBeforeEachArgument = true
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 25, configuration: config)
  }

  func testColorLiteral_packArguments() {
    let input =
      """
      #colorLiteral()
      #colorLiteral(red: 1.0)
      #colorLiteral(red: 1.0, green: 1.0)
      #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
      """

    let expected =
      """
      #colorLiteral()
      #colorLiteral(red: 1.0)
      #colorLiteral(
        red: 1.0, green: 1.0)
      #colorLiteral(
        red: 1.0, green: 1.0,
        blue: 1.0, alpha: 1.0)

      """

    var config = Configuration.forTesting
    config.lineBreakBeforeEachArgument = false
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 25, configuration: config)
  }

  func testImageLiteral_noPackArguments() {
    let input =
      """
      #imageLiteral()
      #imageLiteral(resourceName: "foo.png")
      #imageLiteral(resourceName: "foo/bar/baz/qux.png")
      #imageLiteral(resourceName: "foo/bar/baz/quux.png")
      """

    let expected =
      """
      #imageLiteral()
      #imageLiteral(resourceName: "foo.png")
      #imageLiteral(
        resourceName: "foo/bar/baz/qux.png"
      )
      #imageLiteral(
        resourceName: "foo/bar/baz/quux.png"
      )

      """

    var config = Configuration.forTesting
    config.lineBreakBeforeEachArgument = true
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 38, configuration: config)
  }

  func testImageLiteral_packArguments() {
    let input =
      """
      #imageLiteral()
      #imageLiteral(resourceName: "foo.png")
      #imageLiteral(resourceName: "foo/bar/baz/qux.png")
      #imageLiteral(resourceName: "foo/bar/baz/quux.png")
      """

    let expected =
      """
      #imageLiteral()
      #imageLiteral(resourceName: "foo.png")
      #imageLiteral(
        resourceName: "foo/bar/baz/qux.png")
      #imageLiteral(
        resourceName: "foo/bar/baz/quux.png"
      )

      """

    var config = Configuration.forTesting
    config.lineBreakBeforeEachArgument = false
    assertPrettyPrintEqual(input: input, expected: expected, linelength: 38, configuration: config)
  }

  func testGroupsTrailingComma() {
    let input =
      """
      #imageLiteral(
        image: useLongName ? image(named: .longNameImage) : image(named: .veryLongNameImageZ),
        bar: bar)
      """

    let expected =
      """
      #imageLiteral(
        image: useLongName
          ? image(named: .longNameImage)
          : image(named: .veryLongNameImageZ),
        bar: bar)

      """

    assertPrettyPrintEqual(input: input, expected: expected, linelength: 70)
  }
}
