import SwiftSyntax
import XCTest

@testable import SwiftFormatRules

final class UseShorthandTypeNamesTests: DiagnosingTestCase {
  func testNamesInTypeContextsAreShortened() {
    XCTAssertFormatting(
      UseShorthandTypeNames.self,
      input:
        """
        var a: Array<Int>
        var b: Dictionary<String, Int>
        var c: Optional<Foo>
        """,
      expected:
        """
        var a: [Int]
        var b: [String: Int]
        var c: Foo?
        """)

    XCTAssertDiagnosed(.useTypeShorthand(type: "Array"))
    XCTAssertDiagnosed(.useTypeShorthand(type: "Dictionary"))
    XCTAssertDiagnosed(.useTypeShorthand(type: "Optional"))
  }

  func testNestedNamesInTypeContextsAreShortened() {
    XCTAssertFormatting(
      UseShorthandTypeNames.self,
      input:
        """
        var a: Array<Array<Int>>
        var b: Array<[Int]>
        var c: [Array<Int>]

        var a: Dictionary<Dictionary<String, Int>, Int>
        var b: Dictionary<String, Dictionary<String, Int>>
        var c: Dictionary<Dictionary<String, Int>, Dictionary<String, Int>>
        var d: Dictionary<[String: Int], Int>
        var e: Dictionary<String, [String: Int]>
        var f: Dictionary<[String: Int], [String: Int]>
        var g: [Dictionary<String, Int>: Int]
        var h: [String: Dictionary<String, Int>]
        var i: [Dictionary<String, Int>: Dictionary<String, Int>]

        var a: Optional<Array<Int>>
        var b: Optional<Dictionary<String, Int>>
        var c: Optional<Optional<Int>>
        var d: Array<Int>?
        var e: Dictionary<String, Int>?
        var f: Optional<Int>?
        var g: Optional<Int?>

        var a: Array<Optional<Int>>
        var b: Dictionary<Optional<String>, Optional<Int>>
        var c: Array<Int?>
        var d: Dictionary<String?, Int?>
        """,
      expected:
        """
        var a: [[Int]]
        var b: [[Int]]
        var c: [[Int]]

        var a: [[String: Int]: Int]
        var b: [String: [String: Int]]
        var c: [[String: Int]: [String: Int]]
        var d: [[String: Int]: Int]
        var e: [String: [String: Int]]
        var f: [[String: Int]: [String: Int]]
        var g: [[String: Int]: Int]
        var h: [String: [String: Int]]
        var i: [[String: Int]: [String: Int]]

        var a: [Int]?
        var b: [String: Int]?
        var c: Int??
        var d: [Int]?
        var e: [String: Int]?
        var f: Int??
        var g: Int??

        var a: [Int?]
        var b: [String?: Int?]
        var c: [Int?]
        var d: [String?: Int?]
        """)
  }

  func testNamesInNonMemberAccessExpressionContextsAreShortened() {
    XCTAssertFormatting(
      UseShorthandTypeNames.self,
      input:
        """
        var a = Array<Int>()
        var b = Dictionary<String, Int>()
        var c = Optional<String>(from: decoder)
        """,
      expected:
        """
        var a = [Int]()
        var b = [String: Int]()
        var c = String?(from: decoder)
        """)

    XCTAssertDiagnosed(.useTypeShorthand(type: "Array"))
    XCTAssertDiagnosed(.useTypeShorthand(type: "Dictionary"))
    XCTAssertDiagnosed(.useTypeShorthand(type: "Optional"))
  }

  func testNestedNamesInNonMemberAccessExpressionContextsAreShortened() {
    XCTAssertFormatting(
      UseShorthandTypeNames.self,
      input:
        """
        var a = Array<Array<Int>>()
        var b = Array<[Int]>()
        var c = [Array<Int>]()

        var a = Dictionary<Dictionary<String, Int>, Int>()
        var b = Dictionary<String, Dictionary<String, Int>>()
        var c = Dictionary<Dictionary<String, Int>, Dictionary<String, Int>>()
        var d = Dictionary<[String: Int], Int>()
        var e = Dictionary<String, [String: Int]>()
        var f = Dictionary<[String: Int], [String: Int]>()
        var g = [Dictionary<String, Int>: Int]()
        var h = [String: Dictionary<String, Int>]()
        var i = [Dictionary<String, Int>: Dictionary<String, Int>]()

        var a = Optional<Array<Int>>(from: decoder)
        var b = Optional<Dictionary<String, Int>>(from: decoder)
        var c = Optional<Optional<Int>>(from: decoder)
        var d = Array<Int>?(from: decoder)
        var e = Dictionary<String, Int>?(from: decoder)
        var f = Optional<Int>?(from: decoder)
        var g = Optional<Int?>(from: decoder)

        var a = Array<Optional<Int>>()
        var b = Dictionary<Optional<String>, Optional<Int>>()
        var c = Array<Int?>()
        var d = Dictionary<String?, Int?>()
        """,
      expected:
        """
        var a = [[Int]]()
        var b = [[Int]]()
        var c = [[Int]]()

        var a = [[String: Int]: Int]()
        var b = [String: [String: Int]]()
        var c = [[String: Int]: [String: Int]]()
        var d = [[String: Int]: Int]()
        var e = [String: [String: Int]]()
        var f = [[String: Int]: [String: Int]]()
        var g = [[String: Int]: Int]()
        var h = [String: [String: Int]]()
        var i = [[String: Int]: [String: Int]]()

        var a = [Int]?(from: decoder)
        var b = [String: Int]?(from: decoder)
        var c = Int??(from: decoder)
        var d = [Int]?(from: decoder)
        var e = [String: Int]?(from: decoder)
        var f = Int??(from: decoder)
        var g = Int??(from: decoder)

        var a = [Int?]()
        var b = [String?: Int?]()
        var c = [Int?]()
        var d = [String?: Int?]()
        """)
  }

  func testTypesWithMemberAccessesAreNotShortened() {
    XCTAssertFormatting(
      UseShorthandTypeNames.self,
      input:
        """
        var a: Array<Int>.Index = Array<Int>.Index()
        var b: Dictionary<String, Int>.Index = Dictionary<String, Int>.Index()
        var c: Array<Optional<Int>>.Index = Array<Optional<Int>>.Index()
        var d: Dictionary<Optional<String>, Array<Int>>.Index = Dictionary<Optional<String>, Array<Int>>.Index()
        var e: Array<Array<Int>.Index> = Array<Array<Int>.Index>()

        var f: Foo<Array<Int>>.Bar = Foo<Array<Int>>.Bar()
        var g: Foo<Array<Int>.Index>.Bar = Foo<Array<Int>.Index>.Bar()
        var h: Foo.Bar<Array<Int>> = Foo.Bar<Array<Int>>()
        var i: Foo.Bar<Array<Int>.Index> = Foo.Bar<Array<Int>.Index>()

        var j: Optional<Array<Int>>.Publisher = Optional<Array<Int>>.Publisher()
        var k: Optional<Dictionary<String, Int>>.Publisher = Optional<Dictionary<String, Int>>.Publisher()
        var l: Optional<Optional<Int>>.Publisher = Optional<Optional<Int>>.Publisher()
        """,
      expected:
        """
        var a: Array<Int>.Index = Array<Int>.Index()
        var b: Dictionary<String, Int>.Index = Dictionary<String, Int>.Index()
        var c: Array<Int?>.Index = Array<Int?>.Index()
        var d: Dictionary<String?, [Int]>.Index = Dictionary<String?, [Int]>.Index()
        var e: [Array<Int>.Index] = [Array<Int>.Index]()

        var f: Foo<[Int]>.Bar = Foo<[Int]>.Bar()
        var g: Foo<Array<Int>.Index>.Bar = Foo<Array<Int>.Index>.Bar()
        var h: Foo.Bar<[Int]> = Foo.Bar<[Int]>()
        var i: Foo.Bar<Array<Int>.Index> = Foo.Bar<Array<Int>.Index>()

        var j: Optional<[Int]>.Publisher = Optional<[Int]>.Publisher()
        var k: Optional<[String: Int]>.Publisher = Optional<[String: Int]>.Publisher()
        var l: Optional<Int?>.Publisher = Optional<Int?>.Publisher()
        """)
  }

  func testFunctionTypesAreOnlyWrappedWhenShortenedAsOptionals() {
    // Some of these examples are questionable since function types aren't hashable and thus not
    // valid dictionary keys, nor are they codable, but syntactically they're fine.
    XCTAssertFormatting(
      UseShorthandTypeNames.self,
      input:
        """
        var a: Array<(Foo) -> Bar> = Array<(Foo) -> Bar>()
        var b: Dictionary<(Foo) -> Bar, (Foo) -> Bar> = Dictionary<(Foo) -> Bar, (Foo) -> Bar>()
        var c: Optional<(Foo) -> Bar> = Optional<(Foo) -> Bar>(from: decoder)
        var d: Optional<((Foo) -> Bar)> = Optional<((Foo) -> Bar)>(from: decoder)
        """,
      expected:
        """
        var a: [(Foo) -> Bar] = [(Foo) -> Bar]()
        var b: [(Foo) -> Bar: (Foo) -> Bar] = [(Foo) -> Bar: (Foo) -> Bar]()
        var c: ((Foo) -> Bar)? = ((Foo) -> Bar)?(from: decoder)
        var d: ((Foo) -> Bar)? = ((Foo) -> Bar)?(from: decoder)
        """)
  }

  func testTypesWithEmptyTupleAsGenericArgumentAreNotShortenedInExpressionContexts() {
    // The Swift parser will treat `()` encountered in an expression context as the void *value*,
    // not the type. This extends outwards to shorthand syntax, where `()?` would be treated as an
    // attempt to optional-unwrap the tuple (which is not valid), `[()]` would be an array literal
    // containing the empty tuple, and `[(): ()]` would be a dictionary literal mapping the empty
    // tuple to the empty tuple. Because of this, we cannot permit the empty tuple type to appear
    // directly inside an expression context. In type contexts, however, it's fine.
    XCTAssertFormatting(
      UseShorthandTypeNames.self,
      input:
        """
        var a: Optional<()> = Optional<()>(from: decoder)
        var b: Array<()> = Array<()>()
        var c: Dictionary<(), ()> = Dictionary<(), ()>()
        var d: Array<(Optional<()>) -> Optional<()>> = Array<(Optional<()>) -> Optional<()>>()
        """,
      expected:
        """
        var a: ()? = Optional<()>(from: decoder)
        var b: [()] = Array<()>()
        var c: [(): ()] = Dictionary<(), ()>()
        var d: [(()?) -> ()?] = Array<(()?) -> ()?>()
        """)
  }

  func testPreservesNestedGenericsForUnshortenedTypes() {
    // Regression test for a bug that discarded the generic argument list of a nested type when
    // shortening something like `Array<Range<Foo>>` to `[Range]` (instead of `[Range<Foo>]`.
    XCTAssertFormatting(
      UseShorthandTypeNames.self,
      input:
        """
        var a: Array<Range<Foo>> = Array<Range<Foo>>()
        var b: Dictionary<Range<Foo>, Range<Foo>> = Dictionary<Range<Foo>, Range<Foo>>()
        var c: Optional<Range<Foo>> = Optional<Range<Foo>>(from: decoder)
        """,
      expected:
        """
        var a: [Range<Foo>] = [Range<Foo>]()
        var b: [Range<Foo>: Range<Foo>] = [Range<Foo>: Range<Foo>]()
        var c: Range<Foo>? = Range<Foo>?(from: decoder)
        """)
  }

  func testTypesWithIncorrectNumbersOfGenericArgumentsAreNotChanged() {
    XCTAssertFormatting(
      UseShorthandTypeNames.self,
      input:
        """
        var a: Array<Array<Foo>, Bar> = Array<Array<Foo>, Bar>()
        var b: Dictionary<Dictionary<Foo, Bar>> = Dictionary<Dictionary<Foo, Bar>>()
        var c: Optional<Optional<Foo>, Bar> = Optional<Optional<Foo>, Bar>(from: decoder)
        """,
      expected:
        """
        var a: Array<[Foo], Bar> = Array<[Foo], Bar>()
        var b: Dictionary<[Foo: Bar]> = Dictionary<[Foo: Bar]>()
        var c: Optional<Foo?, Bar> = Optional<Foo?, Bar>(from: decoder)
        """)
  }

  func testModuleQualifiedNamesAreNotShortened() {
    XCTAssertFormatting(
      UseShorthandTypeNames.self,
      input:
        """
        var a: Swift.Array<Array<Foo>> = Swift.Array<Array<Foo>>()
        var b: Swift.Dictionary<Dictionary<Foo, Bar>, Dictionary<Foo, Bar>> = Swift.Dictionary<Dictionary<Foo, Bar>, Dictionary<Foo, Bar>>()
        var c: Swift.Optional<Optional<Foo>> = Swift.Optional<Optional<Foo>>(from: decoder)
        """,
      expected:
        """
        var a: Swift.Array<[Foo]> = Swift.Array<[Foo]>()
        var b: Swift.Dictionary<[Foo: Bar], [Foo: Bar]> = Swift.Dictionary<[Foo: Bar], [Foo: Bar]>()
        var c: Swift.Optional<Foo?> = Swift.Optional<Foo?>(from: decoder)
        """)
  }

  func testTypesWeDoNotCareAboutAreUnchanged() {
    XCTAssertFormatting(
      UseShorthandTypeNames.self,
      input:
        """
        var a: Larry<Int> = Larry<Int>()
        var b: Pictionary<String, Int> = Pictionary<String, Int>()
        var c: Sectional<Couch> = Sectional<Couch>(from: warehouse)
        """,
      expected:
        """
        var a: Larry<Int> = Larry<Int>()
        var b: Pictionary<String, Int> = Pictionary<String, Int>()
        var c: Sectional<Couch> = Sectional<Couch>(from: warehouse)
        """)
  }
}
