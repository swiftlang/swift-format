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

final class AlwaysUseLiteralForEmptyCollectionInitTests: LintOrFormatRuleTestCase {
  func testArray() {
    assertFormatting(
      AlwaysUseLiteralForEmptyCollectionInit.self,
      input: """
        public struct Test {
          var value1 = 1️⃣[Int]()

          func test(v: [Double] = 2️⃣[Double]()) {
            let _ = 3️⃣[String]()
          }
        }

        var _: [Category<Int>] = 4️⃣[Category<Int>]()
        let _ = 5️⃣[(Int, Array<String>)]()
        let _: [(String, Int, Float)] = 6️⃣[(String, Int, Float)]()

        let _ = [(1, 2, String)]()

        class TestSubscript {
          subscript(_: [A] = 7️⃣[A](), x: [(Int, B)] = 8️⃣[(Int, B)]()) {
          }
        }

        // All of the examples in this block could be re-written to use leading-dot syntax: `.init(...)`
        do {
          let _ = [Int](repeating: 0, count: 10)
          let _: [Int] = [Int](repeating: 0, count: 10)

          func testDefault(_ x: [String] = [String](repeating: "a", count: 42)) {
          }

          class TestSubscript {
            subscript(_: Int = 42, x: [(Int, B)] = [(Int, B)](repeating: (0, B()), count: 1)) {
            }
          }
        }
        """,
      expected: """
        public struct Test {
          var value1: [Int] = []

          func test(v: [Double] = []) {
            let _: [String] = []
          }
        }

        var _: [Category<Int>] = []
        let _: [(Int, Array<String>)] = []
        let _: [(String, Int, Float)] = []

        let _ = [(1, 2, String)]()

        class TestSubscript {
          subscript(_: [A] = [], x: [(Int, B)] = []) {
          }
        }

        // All of the examples in this block could be re-written to use leading-dot syntax: `.init(...)`
        do {
          let _ = [Int](repeating: 0, count: 10)
          let _: [Int] = [Int](repeating: 0, count: 10)

          func testDefault(_ x: [String] = [String](repeating: "a", count: 42)) {
          }

          class TestSubscript {
            subscript(_: Int = 42, x: [(Int, B)] = [(Int, B)](repeating: (0, B()), count: 1)) {
            }
          }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "replace '[Int]()' with ': [Int] = []'"),
        FindingSpec("2️⃣", message: "replace '[Double]()' with '[]'"),
        FindingSpec("3️⃣", message: "replace '[String]()' with ': [String] = []'"),
        FindingSpec("4️⃣", message: "replace '[Category<Int>]()' with '[]'"),
        FindingSpec("5️⃣", message: "replace '[(Int, Array<String>)]()' with ': [(Int, Array<String>)] = []'"),
        FindingSpec("6️⃣", message: "replace '[(String, Int, Float)]()' with '[]'"),
        FindingSpec("7️⃣", message: "replace '[A]()' with '[]'"),
        FindingSpec("8️⃣", message: "replace '[(Int, B)]()' with '[]'"),
      ]
    )
  }

  func testDictionary() {
    assertFormatting(
      AlwaysUseLiteralForEmptyCollectionInit.self,
      input: """
        public struct Test {
          var value1 = 1️⃣[Int: String]()

          func test(v: [Double: Int] = 2️⃣[Double: Int]()) {
            let _ = 3️⃣[String: Int]()
          }
        }

        var _: [Category<Int>: String] = 4️⃣[Category<Int>: String]()
        let _ = 5️⃣[(Int, Array<String>): Int]()
        let _: [String: (String, Int, Float)] = 6️⃣[String: (String, Int, Float)]()

        let _ = [String: (1, 2, String)]()

        class TestSubscript {
          subscript(_: [A: Int] = 7️⃣[A: Int](), x: [(Int, B): String] = 8️⃣[(Int, B): String]()) {
          }
        }

        // All of the examples in this block could be re-written to use leading-dot syntax: `.init(...)`
        do {
          let _ = [String: Int](minimumCapacity: 42)
          let _: [String: Int] = [String: Int](minimumCapacity: 42)

          func testDefault(_ x: [Int: String] = [String](minimumCapacity: 1)) {
          }

          class TestSubscript {
            subscript(_: Int = 42, x: [String: (Int, B)] = [String: (Int, B)](minimumCapacity: 2)) {
            }
          }
        }
        """,
      expected: """
        public struct Test {
          var value1: [Int: String] = [:]

          func test(v: [Double: Int] = [:]) {
            let _: [String: Int] = [:]
          }
        }

        var _: [Category<Int>: String] = [:]
        let _: [(Int, Array<String>): Int] = [:]
        let _: [String: (String, Int, Float)] = [:]

        let _ = [String: (1, 2, String)]()

        class TestSubscript {
          subscript(_: [A: Int] = [:], x: [(Int, B): String] = [:]) {
          }
        }

        // All of the examples in this block could be re-written to use leading-dot syntax: `.init(...)`
        do {
          let _ = [String: Int](minimumCapacity: 42)
          let _: [String: Int] = [String: Int](minimumCapacity: 42)

          func testDefault(_ x: [Int: String] = [String](minimumCapacity: 1)) {
          }

          class TestSubscript {
            subscript(_: Int = 42, x: [String: (Int, B)] = [String: (Int, B)](minimumCapacity: 2)) {
            }
          }
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "replace '[Int: String]()' with ': [Int: String] = [:]'"),
        FindingSpec("2️⃣", message: "replace '[Double: Int]()' with '[:]'"),
        FindingSpec("3️⃣", message: "replace '[String: Int]()' with ': [String: Int] = [:]'"),
        FindingSpec("4️⃣", message: "replace '[Category<Int>: String]()' with '[:]'"),
        FindingSpec("5️⃣", message: "replace '[(Int, Array<String>): Int]()' with ': [(Int, Array<String>): Int] = [:]'"),
        FindingSpec("6️⃣", message: "replace '[String: (String, Int, Float)]()' with '[:]'"),
        FindingSpec("7️⃣", message: "replace '[A: Int]()' with '[:]'"),
        FindingSpec("8️⃣", message: "replace '[(Int, B): String]()' with '[:]'"),
      ]
    )
  }
}
