import SwiftFormatRules

final class UseLetInEveryBoundCaseVariableTests: LintOrFormatRuleTestCase {
  override func setUp() {
    super.setUp()
    self.shouldCheckForUnassertedDiagnostics = true
  }

  func testSwitchCase() {
    let input =
      """
      switch DataPoint.labeled("hello", 100) {
      case let .labeled(label, value): break
      case .labeled(label, let value): break
      case .labeled(let label, let value): break
      case let .labeled(label, value)?: break
      case let .labeled(label, value)!: break
      case let .labeled(label, value)??: break
      case let (label, value): break
      case let x as SomeType: break
      }
      """
    performLint(UseLetInEveryBoundCaseVariable.self, input: input)

    XCTAssertDiagnosed(.useLetInBoundCaseVariables, line: 2, column: 6)
    XCTAssertDiagnosed(.useLetInBoundCaseVariables, line: 5, column: 6)
    XCTAssertDiagnosed(.useLetInBoundCaseVariables, line: 6, column: 6)
    XCTAssertDiagnosed(.useLetInBoundCaseVariables, line: 7, column: 6)
    XCTAssertDiagnosed(.useLetInBoundCaseVariables, line: 8, column: 6)
  }

  func testIfCase() {
    let input =
      """
      if case let .labeled(label, value) = DataPoint.labeled("hello", 100) {}
      if case .labeled(label, let value) = DataPoint.labeled("hello", 100) {}
      if case .labeled(let label, let value) = DataPoint.labeled("hello", 100) {}
      if case let .labeled(label, value)? = DataPoint.labeled("hello", 100) {}
      if case let .labeled(label, value)! = DataPoint.labeled("hello", 100) {}
      if case let .labeled(label, value)?? = DataPoint.labeled("hello", 100) {}
      if case let (label, value) = DataPoint.labeled("hello", 100) {}
      if case let x as SomeType = someValue {}
      """
    performLint(UseLetInEveryBoundCaseVariable.self, input: input)

    XCTAssertDiagnosed(.useLetInBoundCaseVariables, line: 1, column: 9)
    XCTAssertDiagnosed(.useLetInBoundCaseVariables, line: 4, column: 9)
    XCTAssertDiagnosed(.useLetInBoundCaseVariables, line: 5, column: 9)
    XCTAssertDiagnosed(.useLetInBoundCaseVariables, line: 6, column: 9)
    XCTAssertDiagnosed(.useLetInBoundCaseVariables, line: 7, column: 9)
  }

  func testGuardCase() {
    let input =
      """
      guard case let .labeled(label, value) = DataPoint.labeled("hello", 100) else {}
      guard case .labeled(label, let value) = DataPoint.labeled("hello", 100) else {}
      guard case .labeled(let label, let value) = DataPoint.labeled("hello", 100) else {}
      guard case let .labeled(label, value)? = DataPoint.labeled("hello", 100) else {}
      guard case let .labeled(label, value)! = DataPoint.labeled("hello", 100) else {}
      guard case let .labeled(label, value)?? = DataPoint.labeled("hello", 100) else {}
      guard case let (label, value) = DataPoint.labeled("hello", 100) else {}
      guard case let x as SomeType = someValue else {}
      """
    performLint(UseLetInEveryBoundCaseVariable.self, input: input)

    XCTAssertDiagnosed(.useLetInBoundCaseVariables, line: 1, column: 12)
    XCTAssertDiagnosed(.useLetInBoundCaseVariables, line: 4, column: 12)
    XCTAssertDiagnosed(.useLetInBoundCaseVariables, line: 5, column: 12)
    XCTAssertDiagnosed(.useLetInBoundCaseVariables, line: 6, column: 12)
    XCTAssertDiagnosed(.useLetInBoundCaseVariables, line: 7, column: 12)
  }

  func testForCase() {
    let input =
      """
      for case let .labeled(label, value) in dataPoints {}
      for case .labeled(label, let value) in dataPoints {}
      for case .labeled(let label, let value) in dataPoints {}
      for case let .labeled(label, value)? in dataPoints {}
      for case let .labeled(label, value)! in dataPoints {}
      for case let .labeled(label, value)?? in dataPoints {}
      for case let (label, value) in dataPoints {}
      for case let x as SomeType in {}
      """
    performLint(UseLetInEveryBoundCaseVariable.self, input: input)

    XCTAssertDiagnosed(.useLetInBoundCaseVariables, line: 1, column: 10)
    XCTAssertDiagnosed(.useLetInBoundCaseVariables, line: 4, column: 10)
    XCTAssertDiagnosed(.useLetInBoundCaseVariables, line: 5, column: 10)
    XCTAssertDiagnosed(.useLetInBoundCaseVariables, line: 6, column: 10)
    XCTAssertDiagnosed(.useLetInBoundCaseVariables, line: 7, column: 10)
  }

  func testWhileCase() {
    let input =
      """
      while case let .labeled(label, value) = iter.next() {}
      while case .labeled(label, let value) = iter.next() {}
      while case .labeled(let label, let value) = iter.next() {}
      while case let .labeled(label, value)? = iter.next() {}
      while case let .labeled(label, value)! = iter.next() {}
      while case let .labeled(label, value)?? = iter.next() {}
      while case let (label, value) = iter.next() {}
      while case let x as SomeType = iter.next() {}
      """
    performLint(UseLetInEveryBoundCaseVariable.self, input: input)

    XCTAssertDiagnosed(.useLetInBoundCaseVariables, line: 1, column: 12)
    XCTAssertDiagnosed(.useLetInBoundCaseVariables, line: 4, column: 12)
    XCTAssertDiagnosed(.useLetInBoundCaseVariables, line: 5, column: 12)
    XCTAssertDiagnosed(.useLetInBoundCaseVariables, line: 6, column: 12)
    XCTAssertDiagnosed(.useLetInBoundCaseVariables, line: 7, column: 12)
  }
}
