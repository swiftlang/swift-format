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

@_spi(Rules) import SwiftFormat
import _SwiftFormatTestSupport

final class NoEmptyTrailingClosureParenthesesTests: LintOrFormatRuleTestCase {
  func testInvalidEmptyParenTrailingClosure() {
    assertFormatting(
      NoEmptyTrailingClosureParentheses.self,
      input: """
        func greetEnthusiastically(_ nameProvider: () -> String) {
          // ...
        }
        func greetApathetically(_ nameProvider: () -> String) {
          // ...
        }
        greetEnthusiastically0️⃣() { "John" }
        greetApathetically { "not John" }
        func myfunc(cls: MyClass) {
          cls.myClosure { $0 }
        }
        func myfunc(cls: MyClass) {
          cls.myBadClosure1️⃣() { $0 }
        }
        DispatchQueue.main.async2️⃣() {
          greetEnthusiastically3️⃣() { "John" }
          DispatchQueue.main.async4️⃣() {
            greetEnthusiastically5️⃣() { "Willis" }
          }
        }
        DispatchQueue.global.async(inGroup: blah) {
          DispatchQueue.main.async6️⃣() {
            greetEnthusiastically7️⃣() { "Willis" }
          }
          DispatchQueue.main.async {
            greetEnthusiastically8️⃣() { "Willis" }
          }
        }
        foo(bar9️⃣() { baz }) { blah }
        """,
      expected: """
        func greetEnthusiastically(_ nameProvider: () -> String) {
          // ...
        }
        func greetApathetically(_ nameProvider: () -> String) {
          // ...
        }
        greetEnthusiastically { "John" }
        greetApathetically { "not John" }
        func myfunc(cls: MyClass) {
          cls.myClosure { $0 }
        }
        func myfunc(cls: MyClass) {
          cls.myBadClosure { $0 }
        }
        DispatchQueue.main.async {
          greetEnthusiastically { "John" }
          DispatchQueue.main.async {
            greetEnthusiastically { "Willis" }
          }
        }
        DispatchQueue.global.async(inGroup: blah) {
          DispatchQueue.main.async {
            greetEnthusiastically { "Willis" }
          }
          DispatchQueue.main.async {
            greetEnthusiastically { "Willis" }
          }
        }
        foo(bar { baz }) { blah }
        """,
      findings: [
        FindingSpec("0️⃣", message: "remove the empty parentheses following 'greetEnthusiastically'"),
        FindingSpec("1️⃣", message: "remove the empty parentheses following 'myBadClosure'"),
        FindingSpec("2️⃣", message: "remove the empty parentheses following 'async'"),
        FindingSpec("3️⃣", message: "remove the empty parentheses following 'greetEnthusiastically'"),
        FindingSpec("4️⃣", message: "remove the empty parentheses following 'async'"),
        FindingSpec("5️⃣", message: "remove the empty parentheses following 'greetEnthusiastically'"),
        FindingSpec("6️⃣", message: "remove the empty parentheses following 'async'"),
        FindingSpec("7️⃣", message: "remove the empty parentheses following 'greetEnthusiastically'"),
        FindingSpec("8️⃣", message: "remove the empty parentheses following 'greetEnthusiastically'"),
        FindingSpec("9️⃣", message: "remove the empty parentheses following 'bar'"),
      ]
    )
  }

  func testDoNotRemoveParensContainingOnlyComments() {
    assertFormatting(
      NoEmptyTrailingClosureParentheses.self,
      input: """
        greetEnthusiastically(/*oldArg: x*/) { "John" }
        greetEnthusiastically(
          /*oldArg: x*/
        ) { "John" }
        greetEnthusiastically(
          // oldArg: x
        ) { "John" }
        """,
      expected: """
        greetEnthusiastically(/*oldArg: x*/) { "John" }
        greetEnthusiastically(
          /*oldArg: x*/
        ) { "John" }
        greetEnthusiastically(
          // oldArg: x
        ) { "John" }
        """,
      findings: []
    )
  }

  func testDoNotRemoveParensInCurriedCalls() {
    assertFormatting(
      NoEmptyTrailingClosureParentheses.self,
      input: """
        perform()() { foo }
        Executor.execute(executor)() { bar }
        withSubscript[baz]() { blah }
        """,
      expected: """
        perform()() { foo }
        Executor.execute(executor)() { bar }
        withSubscript[baz]() { blah }
        """,
      findings: []
    )
  }
}
