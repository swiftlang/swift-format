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
import _SwiftFormatTestSupport

final class LineNumbersTests: PrettyPrintTestCase {
  func testLineNumbers() {
    let input =
      """
      final class A {
        @Test func b() throws {
          doSomethingInAFunctionWithAVeryLongName()  1️⃣// Here we have a very long comment that should not be here because it is far too long
        }
      }
      """

    let expected =
      """
      final class A {
        @Test func b() throws {
          doSomethingInAFunctionWithAVeryLongName()  // Here we have a very long comment that should not be here because it is far too long
        }
      }

      """

    assertPrettyPrintEqual(
      input: input,
      expected: expected,
      linelength: 120,
      whitespaceOnly: true,
      findings: [
        FindingSpec("1️⃣", message: "move end-of-line comment that exceeds the line length")
      ]
    )
  }

  func testLineNumbersWithComments() {
    let input =
      """
      // Copyright (C) 2024 My Coorp. All rights reserved.
      //
      // This document is the property of My Coorp.
      // It is considered confidential and proprietary.
      //
      // This document may not be reproduced or transmitted in any form,
      // in whole or in part, without the express written permission of
      // My Coorp.

      final class A {
        @Test func b() throws {
          doSomethingInAFunctionWithAVeryLongName()  1️⃣// Here we have a very long comment that should not be here because it is far too long
        }
      }
      """

    let expected =
      """
      // Copyright (C) 2024 My Coorp. All rights reserved.
      //
      // This document is the property of My Coorp.
      // It is considered confidential and proprietary.
      //
      // This document may not be reproduced or transmitted in any form,
      // in whole or in part, without the express written permission of
      // My Coorp.

      final class A {
        @Test func b() throws {
          doSomethingInAFunctionWithAVeryLongName()  // Here we have a very long comment that should not be here because it is far too long
        }
      }

      """

    assertPrettyPrintEqual(
      input: input,
      expected: expected,
      linelength: 120,
      whitespaceOnly: true,
      findings: [
        FindingSpec("1️⃣", message: "move end-of-line comment that exceeds the line length")
      ]
    )
  }

  func testCharacterVsCodepoint() {
    let input =
      """
      let fo = 1  // 🤥

      """

    assertPrettyPrintEqual(
      input: input,
      expected: input,
      linelength: 16,
      whitespaceOnly: true,
      findings: []
    )
  }

  func testCharacterVsCodepointMultiline() {
    let input =
      #"""
      /// This is a multiline
      /// comment that is in 🤥
      /// fact perfectly sized

      """#

    assertPrettyPrintEqual(
      input: input,
      expected: input,
      linelength: 25,
      whitespaceOnly: true,
      findings: []
    )
  }

  func testFindingsAfterRemovedLines() {
    var config = Configuration.forTesting
    config.reflowComments.docComments = .always

    let input =
      """

      let x = 1 1️⃣// This end-of-line comment is too long



      func foo() {
          2️⃣/// Short doc line 1
          /// and doc line 2.
        let y = 2
      }

      let singleLine = [1, 2 3️⃣,]
      let multiLine = [
        1,
        24️⃣
      ]
      """

    let expected =
      """
      let x = 1  // This end-of-line comment is too long

      func foo() {
        /// Short doc line 1
        /// and doc line 2.
        let y = 2
      }

      let singleLine = [1, 2,]
      let multiLine = [
        1,
        2
      ]

      """

    assertPrettyPrintEqual(
      input: input,
      expected: expected,
      linelength: 40,
      configuration: config,
      whitespaceOnly: true,
      findings: [
        FindingSpec("1️⃣", message: "move end-of-line comment that exceeds the line length"),
        FindingSpec("2️⃣", message: "reflow comment"),
        FindingSpec(
          "3️⃣",
          message: "remove trailing comma from the last element in single line collection literal"
        ),
        FindingSpec(
          "4️⃣",
          message: "add trailing comma to the last element in multiline collection literal"
        ),
      ]
    )
  }

  func testFindingsAfterInsertedLines() {
    var config = Configuration.forTesting
    config.lineBreakBeforeEachArgument = true
    config.reflowComments.docComments = .always

    let input =
      """
      let a = myFunc(var1: 123, var2: "abc", var3: 456)
      let x = 1  1️⃣// This end-of-line comment is too long

      2️⃣/// Short doc line 1
      /// and doc line 2.
      let singleLine = [1, 23️⃣,]
      let multiLine = [
        1,
        24️⃣
      ]
      """

    let expected =
      """
      let a = myFunc(
        var1: 123,
        var2: "abc",
        var3: 456
      )
      let x = 1  // This end-of-line comment is too long

      /// Short doc line 1
      /// and doc line 2.
      let singleLine = [1, 2,]
      let multiLine = [
        1,
        2
      ]

      """

    assertPrettyPrintEqual(
      input: input,
      expected: expected,
      linelength: 40,
      configuration: config,
      whitespaceOnly: true,
      findings: [
        FindingSpec("1️⃣", message: "move end-of-line comment that exceeds the line length"),
        FindingSpec("2️⃣", message: "reflow comment"),
        FindingSpec(
          "3️⃣",
          message: "remove trailing comma from the last element in single line collection literal"
        ),
        FindingSpec(
          "4️⃣",
          message: "add trailing comma to the last element in multiline collection literal"
        ),
      ]
    )
  }
}
