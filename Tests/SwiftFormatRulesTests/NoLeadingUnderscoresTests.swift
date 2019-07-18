import Foundation
import SwiftSyntax
import XCTest

@testable import SwiftFormatRules

public class NoLeadingUnderscoresTests: DiagnosingTestCase {

  public func testVars() {
    let input = """
      let _foo = foo
      var good_name = 20
      var _badName, okayName, _wor_sEName = 20
      """
    performLint(NoLeadingUnderscores.self, input: input)

    XCTAssertDiagnosed(.doNotStartWithUnderscore(identifier: "_foo"))
    XCTAssertNotDiagnosed(.doNotStartWithUnderscore(identifier: "good_name"))
    XCTAssertDiagnosed(.doNotStartWithUnderscore(identifier: "_badName"))
    XCTAssertNotDiagnosed(.doNotStartWithUnderscore(identifier: "okayName"))
    XCTAssertDiagnosed(.doNotStartWithUnderscore(identifier: "_wor_sEName"))
  }

  public func testClasses() {
    let input = """
      class Foo { let _foo = foo }
      class _Bar {}
      """
    performLint(NoLeadingUnderscores.self, input: input)

    XCTAssertNotDiagnosed(.doNotStartWithUnderscore(identifier: "Foo"))
    XCTAssertDiagnosed(.doNotStartWithUnderscore(identifier: "_foo"))
    XCTAssertDiagnosed(.doNotStartWithUnderscore(identifier: "_Bar"))
  }

  public func testEnums() {
    let input = """
      enum Foo {
        case _case1
        case case2, _case3
        case caseWithAssociatedValues(_value: Int, otherValue: String)
        let _foo = foo
      }
      enum _Bar {}
      """
    performLint(NoLeadingUnderscores.self, input: input)

    XCTAssertNotDiagnosed(.doNotStartWithUnderscore(identifier: "Foo"))
    XCTAssertDiagnosed(.doNotStartWithUnderscore(identifier: "_case1"))
    XCTAssertNotDiagnosed(.doNotStartWithUnderscore(identifier: "case2"))
    XCTAssertDiagnosed(.doNotStartWithUnderscore(identifier: "_case3"))
    XCTAssertNotDiagnosed(.doNotStartWithUnderscore(identifier: "caseWithAssociatedValues"))
    XCTAssertDiagnosed(.doNotStartWithUnderscore(identifier: "_value"))
    XCTAssertNotDiagnosed(.doNotStartWithUnderscore(identifier: "otherValue"))
    XCTAssertDiagnosed(.doNotStartWithUnderscore(identifier: "_foo"))
    XCTAssertDiagnosed(.doNotStartWithUnderscore(identifier: "_Bar"))
  }

  public func testProtocols() {
    let input = """
      protocol Foo {
        associatedtype _Quux
        associatedtype Florb
        var _foo: Int { get set }
      }
      protocol _Bar {}
      """
    performLint(NoLeadingUnderscores.self, input: input)

    XCTAssertNotDiagnosed(.doNotStartWithUnderscore(identifier: "Foo"))
    XCTAssertDiagnosed(.doNotStartWithUnderscore(identifier: "_foo"))
    XCTAssertDiagnosed(.doNotStartWithUnderscore(identifier: "_Bar"))
    XCTAssertDiagnosed(.doNotStartWithUnderscore(identifier: "_Quux"))
    XCTAssertNotDiagnosed(.doNotStartWithUnderscore(identifier: "Florb"))
  }

  public func testStructs() {
    let input = """
      struct Foo { let _foo = foo }
      struct _Bar {}
      """
    performLint(NoLeadingUnderscores.self, input: input)

    XCTAssertNotDiagnosed(.doNotStartWithUnderscore(identifier: "Foo"))
    XCTAssertDiagnosed(.doNotStartWithUnderscore(identifier: "_foo"))
    XCTAssertDiagnosed(.doNotStartWithUnderscore(identifier: "_Bar"))
  }

  public func testFunctions() {
    let input = """
      func _foo<T1, _T2: Equatable>(_ ok: Int, _notOK: Int, _ok _butNotThisOne: Int) {}
      func bar() {}
      """
    performLint(NoLeadingUnderscores.self, input: input)

    XCTAssertDiagnosed(.doNotStartWithUnderscore(identifier: "_foo"))
    XCTAssertNotDiagnosed(.doNotStartWithUnderscore(identifier: "T1"))
    XCTAssertDiagnosed(.doNotStartWithUnderscore(identifier: "_T2"))
    XCTAssertNotDiagnosed(.doNotStartWithUnderscore(identifier: "_"))
    XCTAssertNotDiagnosed(.doNotStartWithUnderscore(identifier: "ok"))
    XCTAssertDiagnosed(.doNotStartWithUnderscore(identifier: "_notOK"))
    XCTAssertNotDiagnosed(.doNotStartWithUnderscore(identifier: "_ok"))
    XCTAssertDiagnosed(.doNotStartWithUnderscore(identifier: "_butNotThisOne"))
    XCTAssertNotDiagnosed(.doNotStartWithUnderscore(identifier: "bar"))
  }

  public func testInitializerArguments() {
    let input = """
      struct X {
        init<T1, _T2: Equatable>(_ ok: Int, _notOK: Int, _ok _butNotThisOne: Int) {}
      }
      """
    performLint(NoLeadingUnderscores.self, input: input)

    XCTAssertNotDiagnosed(.doNotStartWithUnderscore(identifier: "T1"))
    XCTAssertDiagnosed(.doNotStartWithUnderscore(identifier: "_T2"))
    XCTAssertNotDiagnosed(.doNotStartWithUnderscore(identifier: "_"))
    XCTAssertNotDiagnosed(.doNotStartWithUnderscore(identifier: "ok"))
    XCTAssertDiagnosed(.doNotStartWithUnderscore(identifier: "_notOK"))
    XCTAssertNotDiagnosed(.doNotStartWithUnderscore(identifier: "_ok"))
    XCTAssertDiagnosed(.doNotStartWithUnderscore(identifier: "_butNotThisOne"))
  }

  public func testPrecedenceGroups() {
    let input = """
      precedencegroup FooPrecedence {
        associativity: left
        higherThan: BarPrecedence
      }
      precedencegroup _FooPrecedence {
        associativity: left
        higherThan: BarPrecedence
      }
      infix operator <> : _BazPrecedence
      """
    performLint(NoLeadingUnderscores.self, input: input)

    XCTAssertNotDiagnosed(.doNotStartWithUnderscore(identifier: "FooPrecedence"))
    XCTAssertNotDiagnosed(.doNotStartWithUnderscore(identifier: "BarPrecedence"))
    XCTAssertDiagnosed(.doNotStartWithUnderscore(identifier: "_FooPrecedence"))
    XCTAssertNotDiagnosed(.doNotStartWithUnderscore(identifier: "_BazPrecedence"))
  }

  public func testTypealiases() {
    let input = """
      typealias Foo = _Foo
      typealias _Bar = Bar
      """
    performLint(NoLeadingUnderscores.self, input: input)

    XCTAssertNotDiagnosed(.doNotStartWithUnderscore(identifier: "Foo"))
    XCTAssertNotDiagnosed(.doNotStartWithUnderscore(identifier: "_Foo"))
    XCTAssertDiagnosed(.doNotStartWithUnderscore(identifier: "_Bar"))
    XCTAssertNotDiagnosed(.doNotStartWithUnderscore(identifier: "Bar"))
  }

  public func testIdentifiersAreIgnoredAtUsage() {
    let input = """
      let x = _y + _z
      _foo(_bar)
      """
    performLint(NoLeadingUnderscores.self, input: input)

    XCTAssertNotDiagnosed(.doNotStartWithUnderscore(identifier: "_y"))
    XCTAssertNotDiagnosed(.doNotStartWithUnderscore(identifier: "_z"))
    XCTAssertNotDiagnosed(.doNotStartWithUnderscore(identifier: "_foo"))
    XCTAssertNotDiagnosed(.doNotStartWithUnderscore(identifier: "_bar"))
  }
}
