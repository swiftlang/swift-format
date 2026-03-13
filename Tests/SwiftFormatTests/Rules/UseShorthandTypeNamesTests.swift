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

final class UseShorthandTypeNamesTests: LintOrFormatRuleTestCase {
  func testNamesInTypeContextsAreShortened() {
    assertFormatting(
      UseShorthandTypeNames.self,
      input: """
        var a: 1️⃣Array<Int> = []
        var b: 2️⃣Dictionary<String, Int> = [:]
        var c: 3️⃣Optional<Foo> = nil
        """,
      expected: """
        var a: [Int] = []
        var b: [String: Int] = [:]
        var c: Foo? = nil
        """,
      findings: [
        FindingSpec("1️⃣", message: "use shorthand syntax for this 'Array' type"),
        FindingSpec("2️⃣", message: "use shorthand syntax for this 'Dictionary' type"),
        FindingSpec("3️⃣", message: "use shorthand syntax for this 'Optional' type"),
      ]
    )
  }

  func testNestedNamesInTypeContextsAreShortened() {
    assertFormatting(
      UseShorthandTypeNames.self,
      input: """
        var a: 1️⃣Array<2️⃣Array<Int>>
        var b: 3️⃣Array<[Int]>
        var c: [4️⃣Array<Int>]
        """,
      expected: """
        var a: [[Int]]
        var b: [[Int]]
        var c: [[Int]]
        """,
      findings: [
        FindingSpec("1️⃣", message: "use shorthand syntax for this 'Array' type"),
        FindingSpec("2️⃣", message: "use shorthand syntax for this 'Array' type"),
        FindingSpec("3️⃣", message: "use shorthand syntax for this 'Array' type"),
        FindingSpec("4️⃣", message: "use shorthand syntax for this 'Array' type"),
      ]
    )

    assertFormatting(
      UseShorthandTypeNames.self,
      input: """
        var a: 1️⃣Dictionary<2️⃣Dictionary<String, Int>, Int>
        var b: 3️⃣Dictionary<String, 4️⃣Dictionary<String, Int>>
        var c: 5️⃣Dictionary<6️⃣Dictionary<String, Int>, 7️⃣Dictionary<String, Int>>
        var d: 8️⃣Dictionary<[String: Int], Int>
        var e: 9️⃣Dictionary<String, [String: Int]>
        """,
      expected: """
        var a: [[String: Int]: Int]
        var b: [String: [String: Int]]
        var c: [[String: Int]: [String: Int]]
        var d: [[String: Int]: Int]
        var e: [String: [String: Int]]
        """,
      findings: [
        FindingSpec("1️⃣", message: "use shorthand syntax for this 'Dictionary' type"),
        FindingSpec("2️⃣", message: "use shorthand syntax for this 'Dictionary' type"),
        FindingSpec("3️⃣", message: "use shorthand syntax for this 'Dictionary' type"),
        FindingSpec("4️⃣", message: "use shorthand syntax for this 'Dictionary' type"),
        FindingSpec("5️⃣", message: "use shorthand syntax for this 'Dictionary' type"),
        FindingSpec("6️⃣", message: "use shorthand syntax for this 'Dictionary' type"),
        FindingSpec("7️⃣", message: "use shorthand syntax for this 'Dictionary' type"),
        FindingSpec("8️⃣", message: "use shorthand syntax for this 'Dictionary' type"),
        FindingSpec("9️⃣", message: "use shorthand syntax for this 'Dictionary' type"),
      ]
    )

    assertFormatting(
      UseShorthandTypeNames.self,
      input: """
        var f: 1️⃣Dictionary<[String: Int], [String: Int]>
        var g: [2️⃣Dictionary<String, Int>: Int]
        var h: [String: 3️⃣Dictionary<String, Int>]
        var i: [4️⃣Dictionary<String, Int>: 5️⃣Dictionary<String, Int>]
        """,
      expected: """
        var f: [[String: Int]: [String: Int]]
        var g: [[String: Int]: Int]
        var h: [String: [String: Int]]
        var i: [[String: Int]: [String: Int]]
        """,
      findings: [
        FindingSpec("1️⃣", message: "use shorthand syntax for this 'Dictionary' type"),
        FindingSpec("2️⃣", message: "use shorthand syntax for this 'Dictionary' type"),
        FindingSpec("3️⃣", message: "use shorthand syntax for this 'Dictionary' type"),
        FindingSpec("4️⃣", message: "use shorthand syntax for this 'Dictionary' type"),
        FindingSpec("5️⃣", message: "use shorthand syntax for this 'Dictionary' type"),
      ]
    )

    assertFormatting(
      UseShorthandTypeNames.self,
      input: """
        let a: 1️⃣Optional<2️⃣Array<Int>>
        let b: 3️⃣Optional<4️⃣Dictionary<String, Int>>
        let c: 5️⃣Optional<6️⃣Optional<Int>>
        let d: 7️⃣Array<Int>?
        let e: 8️⃣Dictionary<String, Int>?
        let f: 9️⃣Optional<Int>?
        let g: 🔟Optional<Int?>
        """,
      expected: """
        let a: [Int]?
        let b: [String: Int]?
        let c: Int??
        let d: [Int]?
        let e: [String: Int]?
        let f: Int??
        let g: Int??
        """,
      findings: [
        FindingSpec("1️⃣", message: "use shorthand syntax for this 'Optional' type"),
        FindingSpec("2️⃣", message: "use shorthand syntax for this 'Array' type"),
        FindingSpec("3️⃣", message: "use shorthand syntax for this 'Optional' type"),
        FindingSpec("4️⃣", message: "use shorthand syntax for this 'Dictionary' type"),
        FindingSpec("5️⃣", message: "use shorthand syntax for this 'Optional' type"),
        FindingSpec("6️⃣", message: "use shorthand syntax for this 'Optional' type"),
        FindingSpec("7️⃣", message: "use shorthand syntax for this 'Array' type"),
        FindingSpec("8️⃣", message: "use shorthand syntax for this 'Dictionary' type"),
        FindingSpec("9️⃣", message: "use shorthand syntax for this 'Optional' type"),
        FindingSpec("🔟", message: "use shorthand syntax for this 'Optional' type"),
      ]
    )

    assertFormatting(
      UseShorthandTypeNames.self,
      input: """
        var a: 1️⃣Array<2️⃣Optional<Int>>
        var b: 3️⃣Dictionary<4️⃣Optional<String>, 5️⃣Optional<Int>>
        var c: 6️⃣Array<Int?>
        var d: 7️⃣Dictionary<String?, Int?>
        """,
      expected: """
        var a: [Int?]
        var b: [String?: Int?]
        var c: [Int?]
        var d: [String?: Int?]
        """,
      findings: [
        FindingSpec("1️⃣", message: "use shorthand syntax for this 'Array' type"),
        FindingSpec("2️⃣", message: "use shorthand syntax for this 'Optional' type"),
        FindingSpec("3️⃣", message: "use shorthand syntax for this 'Dictionary' type"),
        FindingSpec("4️⃣", message: "use shorthand syntax for this 'Optional' type"),
        FindingSpec("5️⃣", message: "use shorthand syntax for this 'Optional' type"),
        FindingSpec("6️⃣", message: "use shorthand syntax for this 'Array' type"),
        FindingSpec("7️⃣", message: "use shorthand syntax for this 'Dictionary' type"),
      ]
    )
  }

  func testNamesInNonMemberAccessExpressionContextsAreShortened() {
    assertFormatting(
      UseShorthandTypeNames.self,
      input: """
        var a = 1️⃣Array<Int>()
        var b = 2️⃣Dictionary<String, Int>()
        var c = 3️⃣Optional<String>(from: decoder)
        """,
      expected: """
        var a = [Int]()
        var b = [String: Int]()
        var c = String?(from: decoder)
        """,
      findings: [
        FindingSpec("1️⃣", message: "use shorthand syntax for this 'Array' type"),
        FindingSpec("2️⃣", message: "use shorthand syntax for this 'Dictionary' type"),
        FindingSpec("3️⃣", message: "use shorthand syntax for this 'Optional' type"),
      ]
    )
  }

  func testNestedNamesInNonMemberAccessExpressionContextsAreShortened() {
    assertFormatting(
      UseShorthandTypeNames.self,
      input: """
        var a = 1️⃣Array<2️⃣Array<Int>>()
        var b = 3️⃣Array<[Int]>()
        var c = [4️⃣Array<Int>]()
        """,
      expected: """
        var a = [[Int]]()
        var b = [[Int]]()
        var c = [[Int]]()
        """,
      findings: [
        FindingSpec("1️⃣", message: "use shorthand syntax for this 'Array' type"),
        FindingSpec("2️⃣", message: "use shorthand syntax for this 'Array' type"),
        FindingSpec("3️⃣", message: "use shorthand syntax for this 'Array' type"),
        FindingSpec("4️⃣", message: "use shorthand syntax for this 'Array' type"),
      ]
    )

    assertFormatting(
      UseShorthandTypeNames.self,
      input: """
        var a = 1️⃣Dictionary<2️⃣Dictionary<String, Int>, Int>()
        var b = 3️⃣Dictionary<String, 4️⃣Dictionary<String, Int>>()
        var c = 5️⃣Dictionary<6️⃣Dictionary<String, Int>, 7️⃣Dictionary<String, Int>>()
        var d = 8️⃣Dictionary<[String: Int], Int>()
        var e = 9️⃣Dictionary<String, [String: Int]>()
        """,
      expected: """
        var a = [[String: Int]: Int]()
        var b = [String: [String: Int]]()
        var c = [[String: Int]: [String: Int]]()
        var d = [[String: Int]: Int]()
        var e = [String: [String: Int]]()
        """,
      findings: [
        FindingSpec("1️⃣", message: "use shorthand syntax for this 'Dictionary' type"),
        FindingSpec("2️⃣", message: "use shorthand syntax for this 'Dictionary' type"),
        FindingSpec("3️⃣", message: "use shorthand syntax for this 'Dictionary' type"),
        FindingSpec("4️⃣", message: "use shorthand syntax for this 'Dictionary' type"),
        FindingSpec("5️⃣", message: "use shorthand syntax for this 'Dictionary' type"),
        FindingSpec("6️⃣", message: "use shorthand syntax for this 'Dictionary' type"),
        FindingSpec("7️⃣", message: "use shorthand syntax for this 'Dictionary' type"),
        FindingSpec("8️⃣", message: "use shorthand syntax for this 'Dictionary' type"),
        FindingSpec("9️⃣", message: "use shorthand syntax for this 'Dictionary' type"),
      ]
    )

    assertFormatting(
      UseShorthandTypeNames.self,
      input: """
        var f = 1️⃣Dictionary<[String: Int], [String: Int]>()
        var g = [2️⃣Dictionary<String, Int>: Int]()
        var h = [String: 3️⃣Dictionary<String, Int>]()
        var i = [4️⃣Dictionary<String, Int>: 5️⃣Dictionary<String, Int>]()
        """,
      expected: """
        var f = [[String: Int]: [String: Int]]()
        var g = [[String: Int]: Int]()
        var h = [String: [String: Int]]()
        var i = [[String: Int]: [String: Int]]()
        """,
      findings: [
        FindingSpec("1️⃣", message: "use shorthand syntax for this 'Dictionary' type"),
        FindingSpec("2️⃣", message: "use shorthand syntax for this 'Dictionary' type"),
        FindingSpec("3️⃣", message: "use shorthand syntax for this 'Dictionary' type"),
        FindingSpec("4️⃣", message: "use shorthand syntax for this 'Dictionary' type"),
        FindingSpec("5️⃣", message: "use shorthand syntax for this 'Dictionary' type"),
      ]
    )

    assertFormatting(
      UseShorthandTypeNames.self,
      input: """
        var a = 1️⃣Optional<2️⃣Array<Int>>(from: decoder)
        var b = 3️⃣Optional<4️⃣Dictionary<String, Int>>(from: decoder)
        var c = 5️⃣Optional<6️⃣Optional<Int>>(from: decoder)
        var d = 7️⃣Array<Int>?(from: decoder)
        var e = 8️⃣Dictionary<String, Int>?(from: decoder)
        var f = 9️⃣Optional<Int>?(from: decoder)
        var g = 🔟Optional<Int?>(from: decoder)
        """,
      expected: """
        var a = [Int]?(from: decoder)
        var b = [String: Int]?(from: decoder)
        var c = Int??(from: decoder)
        var d = [Int]?(from: decoder)
        var e = [String: Int]?(from: decoder)
        var f = Int??(from: decoder)
        var g = Int??(from: decoder)
        """,
      findings: [
        FindingSpec("1️⃣", message: "use shorthand syntax for this 'Optional' type"),
        FindingSpec("2️⃣", message: "use shorthand syntax for this 'Array' type"),
        FindingSpec("3️⃣", message: "use shorthand syntax for this 'Optional' type"),
        FindingSpec("4️⃣", message: "use shorthand syntax for this 'Dictionary' type"),
        FindingSpec("5️⃣", message: "use shorthand syntax for this 'Optional' type"),
        FindingSpec("6️⃣", message: "use shorthand syntax for this 'Optional' type"),
        FindingSpec("7️⃣", message: "use shorthand syntax for this 'Array' type"),
        FindingSpec("8️⃣", message: "use shorthand syntax for this 'Dictionary' type"),
        FindingSpec("9️⃣", message: "use shorthand syntax for this 'Optional' type"),
        FindingSpec("🔟", message: "use shorthand syntax for this 'Optional' type"),
      ]
    )

    assertFormatting(
      UseShorthandTypeNames.self,
      input: """
        var a = 1️⃣Array<2️⃣Optional<Int>>()
        var b = 3️⃣Dictionary<4️⃣Optional<String>, 5️⃣Optional<Int>>()
        var c = 6️⃣Array<Int?>()
        var d = 7️⃣Dictionary<String?, Int?>()
        """,
      expected: """
        var a = [Int?]()
        var b = [String?: Int?]()
        var c = [Int?]()
        var d = [String?: Int?]()
        """,
      findings: [
        FindingSpec("1️⃣", message: "use shorthand syntax for this 'Array' type"),
        FindingSpec("2️⃣", message: "use shorthand syntax for this 'Optional' type"),
        FindingSpec("3️⃣", message: "use shorthand syntax for this 'Dictionary' type"),
        FindingSpec("4️⃣", message: "use shorthand syntax for this 'Optional' type"),
        FindingSpec("5️⃣", message: "use shorthand syntax for this 'Optional' type"),
        FindingSpec("6️⃣", message: "use shorthand syntax for this 'Array' type"),
        FindingSpec("7️⃣", message: "use shorthand syntax for this 'Dictionary' type"),
      ]
    )
  }

  func testTypesWithMemberAccessesAreNotShortened() {
    assertFormatting(
      UseShorthandTypeNames.self,
      input: """
        var a: Array<Int>.Index = Array<Int>.Index()
        var b: Dictionary<String, Int>.Index = Dictionary<String, Int>.Index()
        var c: Array<1️⃣Optional<Int>>.Index = Array<2️⃣Optional<Int>>.Index()
        var d: Dictionary<3️⃣Optional<String>, 4️⃣Array<Int>>.Index = Dictionary<5️⃣Optional<String>, 6️⃣Array<Int>>.Index()
        var e: 7️⃣Array<Array<Int>.Index> = 8️⃣Array<Array<Int>.Index>()
        """,
      expected: """
        var a: Array<Int>.Index = Array<Int>.Index()
        var b: Dictionary<String, Int>.Index = Dictionary<String, Int>.Index()
        var c: Array<Int?>.Index = Array<Int?>.Index()
        var d: Dictionary<String?, [Int]>.Index = Dictionary<String?, [Int]>.Index()
        var e: [Array<Int>.Index] = [Array<Int>.Index]()
        """,
      findings: [
        FindingSpec("1️⃣", message: "use shorthand syntax for this 'Optional' type"),
        FindingSpec("2️⃣", message: "use shorthand syntax for this 'Optional' type"),
        FindingSpec("3️⃣", message: "use shorthand syntax for this 'Optional' type"),
        FindingSpec("4️⃣", message: "use shorthand syntax for this 'Array' type"),
        FindingSpec("5️⃣", message: "use shorthand syntax for this 'Optional' type"),
        FindingSpec("6️⃣", message: "use shorthand syntax for this 'Array' type"),
        FindingSpec("7️⃣", message: "use shorthand syntax for this 'Array' type"),
        FindingSpec("8️⃣", message: "use shorthand syntax for this 'Array' type"),
      ]
    )

    assertFormatting(
      UseShorthandTypeNames.self,
      input: """
        var f: Foo<1️⃣Array<Int>>.Bar = Foo<2️⃣Array<Int>>.Bar()
        var g: Foo<Array<Int>.Index>.Bar = Foo<Array<Int>.Index>.Bar()
        var h: Foo.Bar<3️⃣Array<Int>> = Foo.Bar<4️⃣Array<Int>>()
        var i: Foo.Bar<Array<Int>.Index> = Foo.Bar<Array<Int>.Index>()
        """,
      expected: """
        var f: Foo<[Int]>.Bar = Foo<[Int]>.Bar()
        var g: Foo<Array<Int>.Index>.Bar = Foo<Array<Int>.Index>.Bar()
        var h: Foo.Bar<[Int]> = Foo.Bar<[Int]>()
        var i: Foo.Bar<Array<Int>.Index> = Foo.Bar<Array<Int>.Index>()
        """,
      findings: [
        FindingSpec("1️⃣", message: "use shorthand syntax for this 'Array' type"),
        FindingSpec("2️⃣", message: "use shorthand syntax for this 'Array' type"),
        FindingSpec("3️⃣", message: "use shorthand syntax for this 'Array' type"),
        FindingSpec("4️⃣", message: "use shorthand syntax for this 'Array' type"),
      ]
    )

    assertFormatting(
      UseShorthandTypeNames.self,
      input: """
        var j: Optional<1️⃣Array<Int>>.Publisher = Optional<2️⃣Array<Int>>.Publisher()
        var k: Optional<3️⃣Dictionary<String, Int>>.Publisher = Optional<4️⃣Dictionary<String, Int>>.Publisher()
        var l: Optional<5️⃣Optional<Int>>.Publisher = Optional<6️⃣Optional<Int>>.Publisher()
        """,
      expected: """
        var j: Optional<[Int]>.Publisher = Optional<[Int]>.Publisher()
        var k: Optional<[String: Int]>.Publisher = Optional<[String: Int]>.Publisher()
        var l: Optional<Int?>.Publisher = Optional<Int?>.Publisher()
        """,
      findings: [
        FindingSpec("1️⃣", message: "use shorthand syntax for this 'Array' type"),
        FindingSpec("2️⃣", message: "use shorthand syntax for this 'Array' type"),
        FindingSpec("3️⃣", message: "use shorthand syntax for this 'Dictionary' type"),
        FindingSpec("4️⃣", message: "use shorthand syntax for this 'Dictionary' type"),
        FindingSpec("5️⃣", message: "use shorthand syntax for this 'Optional' type"),
        FindingSpec("6️⃣", message: "use shorthand syntax for this 'Optional' type"),
      ]
    )
  }

  func testFunctionTypesAreOnlyWrappedWhenShortenedAsOptionals() {
    // Some of these examples are questionable since function types aren't hashable and thus not
    // valid dictionary keys, nor are they codable, but syntactically they're fine.
    assertFormatting(
      UseShorthandTypeNames.self,
      input: """
        var a: 1️⃣Array<(Foo) -> Bar> = 2️⃣Array<(Foo) -> Bar>()
        var b: 3️⃣Dictionary<(Foo) -> Bar, (Foo) -> Bar> = 4️⃣Dictionary<(Foo) -> Bar, (Foo) -> Bar>()
        var c: 5️⃣Optional<(Foo) -> Bar> = 6️⃣Optional<(Foo) -> Bar>(from: decoder)
        var d: 7️⃣Optional<((Foo) -> Bar)> = 8️⃣Optional<((Foo) -> Bar)>(from: decoder)
        """,
      expected: """
        var a: [(Foo) -> Bar] = [(Foo) -> Bar]()
        var b: [(Foo) -> Bar: (Foo) -> Bar] = [(Foo) -> Bar: (Foo) -> Bar]()
        var c: ((Foo) -> Bar)? = ((Foo) -> Bar)?(from: decoder)
        var d: ((Foo) -> Bar)? = ((Foo) -> Bar)?(from: decoder)
        """,
      findings: [
        FindingSpec("1️⃣", message: "use shorthand syntax for this 'Array' type"),
        FindingSpec("2️⃣", message: "use shorthand syntax for this 'Array' type"),
        FindingSpec("3️⃣", message: "use shorthand syntax for this 'Dictionary' type"),
        FindingSpec("4️⃣", message: "use shorthand syntax for this 'Dictionary' type"),
        FindingSpec("5️⃣", message: "use shorthand syntax for this 'Optional' type"),
        FindingSpec("6️⃣", message: "use shorthand syntax for this 'Optional' type"),
        FindingSpec("7️⃣", message: "use shorthand syntax for this 'Optional' type"),
        FindingSpec("8️⃣", message: "use shorthand syntax for this 'Optional' type"),
      ]
    )
  }

  func testTypesWithEmptyTupleAsGenericArgumentAreNotShortenedInExpressionContexts() {
    // The Swift parser will treat `()` encountered in an expression context as the void *value*,
    // not the type. This extends outwards to shorthand syntax, where `()?` would be treated as an
    // attempt to optional-unwrap the tuple (which is not valid), `[()]` would be an array literal
    // containing the empty tuple, and `[(): ()]` would be a dictionary literal mapping the empty
    // tuple to the empty tuple. Because of this, we cannot permit the empty tuple type to appear
    // directly inside an expression context. In type contexts, however, it's fine.
    assertFormatting(
      UseShorthandTypeNames.self,
      input: """
        var a: 4️⃣Optional<()> = Optional<()>(from: decoder)
        var b: 1️⃣Array<()> = Array<()>()
        var c: 3️⃣Dictionary<(), ()> = Dictionary<(), ()>()
        var d: 2️⃣Array<(5️⃣Optional<()>) -> 6️⃣Optional<()>> = Array<(7️⃣Optional<()>) -> 8️⃣Optional<()>>()
        """,
      expected: """
        var a: ()? = Optional<()>(from: decoder)
        var b: [()] = Array<()>()
        var c: [(): ()] = Dictionary<(), ()>()
        var d: [(()?) -> ()?] = Array<(()?) -> ()?>()
        """,
      findings: [
        FindingSpec("1️⃣", message: "use shorthand syntax for this 'Array' type"),
        FindingSpec("2️⃣", message: "use shorthand syntax for this 'Array' type"),
        FindingSpec("3️⃣", message: "use shorthand syntax for this 'Dictionary' type"),
        FindingSpec("4️⃣", message: "use shorthand syntax for this 'Optional' type"),
        FindingSpec("5️⃣", message: "use shorthand syntax for this 'Optional' type"),
        FindingSpec("6️⃣", message: "use shorthand syntax for this 'Optional' type"),
        FindingSpec("7️⃣", message: "use shorthand syntax for this 'Optional' type"),
        FindingSpec("8️⃣", message: "use shorthand syntax for this 'Optional' type"),
      ]
    )
  }

  func testPreservesNestedGenericsForUnshortenedTypes() {
    // Regression test for a bug that discarded the generic argument list of a nested type when
    // shortening something like `Array<Range<Foo>>` to `[Range]` (instead of `[Range<Foo>]`.
    assertFormatting(
      UseShorthandTypeNames.self,
      input: """
        var a: 1️⃣Array<Range<Foo>> = 2️⃣Array<Range<Foo>>()
        var b: 3️⃣Dictionary<Range<Foo>, Range<Foo>> = 4️⃣Dictionary<Range<Foo>, Range<Foo>>()
        var c: 5️⃣Optional<Range<Foo>> = 6️⃣Optional<Range<Foo>>(from: decoder)
        """,
      expected: """
        var a: [Range<Foo>] = [Range<Foo>]()
        var b: [Range<Foo>: Range<Foo>] = [Range<Foo>: Range<Foo>]()
        var c: Range<Foo>? = Range<Foo>?(from: decoder)
        """,
      findings: [
        FindingSpec("1️⃣", message: "use shorthand syntax for this 'Array' type"),
        FindingSpec("2️⃣", message: "use shorthand syntax for this 'Array' type"),
        FindingSpec("3️⃣", message: "use shorthand syntax for this 'Dictionary' type"),
        FindingSpec("4️⃣", message: "use shorthand syntax for this 'Dictionary' type"),
        FindingSpec("5️⃣", message: "use shorthand syntax for this 'Optional' type"),
        FindingSpec("6️⃣", message: "use shorthand syntax for this 'Optional' type"),
      ]
    )
  }

  func testTypesWithIncorrectNumbersOfGenericArgumentsAreNotChanged() {
    assertFormatting(
      UseShorthandTypeNames.self,
      input: """
        var a: Array<1️⃣Array<Foo>, Bar> = Array<2️⃣Array<Foo>, Bar>()
        var b: Dictionary<3️⃣Dictionary<Foo, Bar>> = Dictionary<4️⃣Dictionary<Foo, Bar>>()
        var c: Optional<5️⃣Optional<Foo>, Bar> = Optional<6️⃣Optional<Foo>, Bar>(from: decoder)
        """,
      expected: """
        var a: Array<[Foo], Bar> = Array<[Foo], Bar>()
        var b: Dictionary<[Foo: Bar]> = Dictionary<[Foo: Bar]>()
        var c: Optional<Foo?, Bar> = Optional<Foo?, Bar>(from: decoder)
        """,
      findings: [
        FindingSpec("1️⃣", message: "use shorthand syntax for this 'Array' type"),
        FindingSpec("2️⃣", message: "use shorthand syntax for this 'Array' type"),
        FindingSpec("3️⃣", message: "use shorthand syntax for this 'Dictionary' type"),
        FindingSpec("4️⃣", message: "use shorthand syntax for this 'Dictionary' type"),
        FindingSpec("5️⃣", message: "use shorthand syntax for this 'Optional' type"),
        FindingSpec("6️⃣", message: "use shorthand syntax for this 'Optional' type"),
      ]
    )
  }

  func testModuleQualifiedNamesAreNotShortened() {
    assertFormatting(
      UseShorthandTypeNames.self,
      input: """
        var a: Swift.Array<1️⃣Array<Foo>> = Swift.Array<2️⃣Array<Foo>>()
        var b: Swift.Dictionary<3️⃣Dictionary<Foo, Bar>, 4️⃣Dictionary<Foo, Bar>> = Swift.Dictionary<5️⃣Dictionary<Foo, Bar>, 6️⃣Dictionary<Foo, Bar>>()
        var c: Swift.Optional<7️⃣Optional<Foo>> = Swift.Optional<8️⃣Optional<Foo>>(from: decoder)
        """,
      expected: """
        var a: Swift.Array<[Foo]> = Swift.Array<[Foo]>()
        var b: Swift.Dictionary<[Foo: Bar], [Foo: Bar]> = Swift.Dictionary<[Foo: Bar], [Foo: Bar]>()
        var c: Swift.Optional<Foo?> = Swift.Optional<Foo?>(from: decoder)
        """,
      findings: [
        FindingSpec("1️⃣", message: "use shorthand syntax for this 'Array' type"),
        FindingSpec("2️⃣", message: "use shorthand syntax for this 'Array' type"),
        FindingSpec("3️⃣", message: "use shorthand syntax for this 'Dictionary' type"),
        FindingSpec("4️⃣", message: "use shorthand syntax for this 'Dictionary' type"),
        FindingSpec("5️⃣", message: "use shorthand syntax for this 'Dictionary' type"),
        FindingSpec("6️⃣", message: "use shorthand syntax for this 'Dictionary' type"),
        FindingSpec("7️⃣", message: "use shorthand syntax for this 'Optional' type"),
        FindingSpec("8️⃣", message: "use shorthand syntax for this 'Optional' type"),
      ]
    )
  }

  func testTypesWeDoNotCareAboutAreUnchanged() {
    assertFormatting(
      UseShorthandTypeNames.self,
      input: """
        var a: Larry<Int> = Larry<Int>()
        var b: Pictionary<String, Int> = Pictionary<String, Int>()
        var c: Sectional<Couch> = Sectional<Couch>(from: warehouse)
        """,
      expected: """
        var a: Larry<Int> = Larry<Int>()
        var b: Pictionary<String, Int> = Pictionary<String, Int>()
        var c: Sectional<Couch> = Sectional<Couch>(from: warehouse)
        """,
      findings: []
    )
  }

  func testOptionalStoredVarsWithoutInitializersAreNotChangedUnlessImmutable() {
    assertFormatting(
      UseShorthandTypeNames.self,
      input: """
        var a: Optional<Int>
        var b: Optional<Int> {
          didSet {}
        }
        let c: 1️⃣Optional<Int>
        """,
      expected: """
        var a: Optional<Int>
        var b: Optional<Int> {
          didSet {}
        }
        let c: Int?
        """,
      findings: [
        FindingSpec("1️⃣", message: "use shorthand syntax for this 'Optional' type")
      ]
    )
  }

  func testOptionalComputedVarsAreChanged() {
    assertFormatting(
      UseShorthandTypeNames.self,
      input: """
        var a: 1️⃣Optional<Int> { nil }
        var b: 2️⃣Optional<Int> {
          get { 0 }
        }
        var c: 3️⃣Optional<Int> {
          _read {}
        }
        var d: 4️⃣Optional<Int> {
          unsafeAddress {}
        }
        """,
      expected: """
        var a: Int? { nil }
        var b: Int? {
          get { 0 }
        }
        var c: Int? {
          _read {}
        }
        var d: Int? {
          unsafeAddress {}
        }
        """,
      findings: [
        FindingSpec("1️⃣", message: "use shorthand syntax for this 'Optional' type"),
        FindingSpec("2️⃣", message: "use shorthand syntax for this 'Optional' type"),
        FindingSpec("3️⃣", message: "use shorthand syntax for this 'Optional' type"),
        FindingSpec("4️⃣", message: "use shorthand syntax for this 'Optional' type"),
      ]
    )
  }

  func testOptionalStoredVarsWithInitializersAreChanged() {
    assertFormatting(
      UseShorthandTypeNames.self,
      input: """
        var a: 1️⃣Optional<Int> = nil
        var b: 2️⃣Optional<Int> = nil {
          didSet {}
        }
        let c: 3️⃣Optional<Int> = nil
        """,
      expected: """
        var a: Int? = nil
        var b: Int? = nil {
          didSet {}
        }
        let c: Int? = nil
        """,
      findings: [
        FindingSpec("1️⃣", message: "use shorthand syntax for this 'Optional' type"),
        FindingSpec("2️⃣", message: "use shorthand syntax for this 'Optional' type"),
        FindingSpec("3️⃣", message: "use shorthand syntax for this 'Optional' type"),
      ]
    )
  }

  func testOptionalsNestedInOtherTypesInStoredVarsAreStillChanged() {
    assertFormatting(
      UseShorthandTypeNames.self,
      input: """
        var c: Generic<1️⃣Optional<Int>>
        var d: [2️⃣Optional<Int>]
        var e: [String: 3️⃣Optional<Int>]
        """,
      expected: """
        var c: Generic<Int?>
        var d: [Int?]
        var e: [String: Int?]
        """,
      findings: [
        FindingSpec("1️⃣", message: "use shorthand syntax for this 'Optional' type"),
        FindingSpec("2️⃣", message: "use shorthand syntax for this 'Optional' type"),
        FindingSpec("3️⃣", message: "use shorthand syntax for this 'Optional' type"),
      ]
    )
  }

  func testSomeAnyTypesInOptionalsAreParenthesized() {
    // If we need to insert parentheses, verify that we do, but also verify that we don't insert
    // them unnecessarily.
    assertFormatting(
      UseShorthandTypeNames.self,
      input: """
        func f(_: 1️⃣Optional<some P>) {}
        func g(_: 2️⃣Optional<any P>) {}
        var x: 3️⃣Optional<some P> = S()
        var y: 4️⃣Optional<any P> = S()
        var z = [5️⃣Optional<any P>]([S()])

        func f(_: 6️⃣Optional<(some P)>) {}
        func g(_: 7️⃣Optional<(any P)>) {}
        var x: 8️⃣Optional<(some P)> = S()
        var y: 9️⃣Optional<(any P)> = S()
        var z = [🔟Optional<(any P)>]([S()])
        """,
      expected: """
        func f(_: (some P)?) {}
        func g(_: (any P)?) {}
        var x: (some P)? = S()
        var y: (any P)? = S()
        var z = [(any P)?]([S()])

        func f(_: (some P)?) {}
        func g(_: (any P)?) {}
        var x: (some P)? = S()
        var y: (any P)? = S()
        var z = [(any P)?]([S()])
        """,
      findings: [
        FindingSpec("1️⃣", message: "use shorthand syntax for this 'Optional' type"),
        FindingSpec("2️⃣", message: "use shorthand syntax for this 'Optional' type"),
        FindingSpec("3️⃣", message: "use shorthand syntax for this 'Optional' type"),
        FindingSpec("4️⃣", message: "use shorthand syntax for this 'Optional' type"),
        FindingSpec("5️⃣", message: "use shorthand syntax for this 'Optional' type"),
        FindingSpec("6️⃣", message: "use shorthand syntax for this 'Optional' type"),
        FindingSpec("7️⃣", message: "use shorthand syntax for this 'Optional' type"),
        FindingSpec("8️⃣", message: "use shorthand syntax for this 'Optional' type"),
        FindingSpec("9️⃣", message: "use shorthand syntax for this 'Optional' type"),
        FindingSpec("🔟", message: "use shorthand syntax for this 'Optional' type"),
      ]
    )
  }

  func testAttributedTypesInOptionalsAreParenthesized() {
    // If we need to insert parentheses, verify that we do, but also verify that we don't insert
    // them unnecessarily.
    assertFormatting(
      UseShorthandTypeNames.self,
      input: """
        var x: 1️⃣Optional<consuming P> = S()
        var y: 2️⃣Optional<@Sendable (Int) -> Void> = S()
        var z = [3️⃣Optional<consuming P>]([S()])
        var a = [4️⃣Optional<@Sendable (Int) -> Void>]([S()])

        var x: 5️⃣Optional<(consuming P)> = S()
        var y: 6️⃣Optional<(@Sendable (Int) -> Void)> = S()
        var z = [7️⃣Optional<(consuming P)>]([S()])
        var a = [8️⃣Optional<(@Sendable (Int) -> Void)>]([S()])
        """,
      expected: """
        var x: (consuming P)? = S()
        var y: (@Sendable (Int) -> Void)? = S()
        var z = [(consuming P)?]([S()])
        var a = [(@Sendable (Int) -> Void)?]([S()])

        var x: (consuming P)? = S()
        var y: (@Sendable (Int) -> Void)? = S()
        var z = [(consuming P)?]([S()])
        var a = [(@Sendable (Int) -> Void)?]([S()])
        """,
      findings: [
        FindingSpec("1️⃣", message: "use shorthand syntax for this 'Optional' type"),
        FindingSpec("2️⃣", message: "use shorthand syntax for this 'Optional' type"),
        FindingSpec("3️⃣", message: "use shorthand syntax for this 'Optional' type"),
        FindingSpec("4️⃣", message: "use shorthand syntax for this 'Optional' type"),
        FindingSpec("5️⃣", message: "use shorthand syntax for this 'Optional' type"),
        FindingSpec("6️⃣", message: "use shorthand syntax for this 'Optional' type"),
        FindingSpec("7️⃣", message: "use shorthand syntax for this 'Optional' type"),
        FindingSpec("8️⃣", message: "use shorthand syntax for this 'Optional' type"),
      ]
    )
  }

  func testPackElementTypesInOptionalsAreParenthesized() {
    // If we need to insert parentheses, verify that we do, but also verify that we don't insert
    // them unnecessarily.
    assertFormatting(
      UseShorthandTypeNames.self,
      input: """
        var x: (repeat 1️⃣Optional<each T>)
        var y = [(repeat 2️⃣Optional<each T>)]()

        var x: (repeat 3️⃣Optional<(each T)>)
        var y = [(repeat 4️⃣Optional<(each T)>)]()
        """,
      expected: """
        var x: (repeat (each T)?)
        var y = [(repeat (each T)?)]()

        var x: (repeat (each T)?)
        var y = [(repeat (each T)?)]()
        """,
      findings: [
        FindingSpec("1️⃣", message: "use shorthand syntax for this 'Optional' type"),
        FindingSpec("2️⃣", message: "use shorthand syntax for this 'Optional' type"),
        FindingSpec("3️⃣", message: "use shorthand syntax for this 'Optional' type"),
        FindingSpec("4️⃣", message: "use shorthand syntax for this 'Optional' type"),
      ]
    )
  }
}
