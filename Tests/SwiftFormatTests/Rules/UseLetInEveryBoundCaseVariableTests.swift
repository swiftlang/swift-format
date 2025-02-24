@_spi(Rules) import SwiftFormat
import _SwiftFormatTestSupport

final class UseLetInEveryBoundCaseVariableTests: LintOrFormatRuleTestCase {
  func testSwitchCase() {
    assertFormatting(
      UseLetInEveryBoundCaseVariable.self,
      input: """
        switch DataPoint.labeled("hello", 100) {
        case 1️⃣let .labeled(label, value): break
        case .labeled(label, let value): break
        case .labeled(let label, let value): break
        case 2️⃣let .labeled(label, value)?: break
        case 3️⃣let .labeled(label, value)!: break
        case 4️⃣let .labeled(label, value)??: break
        case 5️⃣let (label, value): break
        case let x as SomeType: break
        case 6️⃣var .labeled(label, value): break
        case 7️⃣var (label, value): break
        }
        """,
      expected: """
        switch DataPoint.labeled("hello", 100) {
        case .labeled(let label, let value): break
        case .labeled(label, let value): break
        case .labeled(let label, let value): break
        case .labeled(let label, let value)?: break
        case .labeled(let label, let value)!: break
        case .labeled(let label, let value)??: break
        case (let label, let value): break
        case let x as SomeType: break
        case .labeled(var label, var value): break
        case (var label, var value): break
        }
        """,
      findings: [
        FindingSpec(
          "1️⃣",
          message: "move this 'let' keyword inside the 'case' pattern, before each of the bound variables"
        ),
        FindingSpec(
          "2️⃣",
          message: "move this 'let' keyword inside the 'case' pattern, before each of the bound variables"
        ),
        FindingSpec(
          "3️⃣",
          message: "move this 'let' keyword inside the 'case' pattern, before each of the bound variables"
        ),
        FindingSpec(
          "4️⃣",
          message: "move this 'let' keyword inside the 'case' pattern, before each of the bound variables"
        ),
        FindingSpec(
          "5️⃣",
          message: "move this 'let' keyword inside the 'case' pattern, before each of the bound variables"
        ),
        FindingSpec(
          "6️⃣",
          message: "move this 'var' keyword inside the 'case' pattern, before each of the bound variables"
        ),
        FindingSpec(
          "7️⃣",
          message: "move this 'var' keyword inside the 'case' pattern, before each of the bound variables"
        ),
      ]
    )
  }

  func testSwitchMultipleCases() {
    assertFormatting(
      UseLetInEveryBoundCaseVariable.self,
      input: """
        switch (start.representation, end.representation) {
        case 1️⃣let (.element(element), .separator(next: separator)):
          return 2 * base.distance(from: element, to: separator) - 1
        case 2️⃣let (.separator(next: separator), .element(element)):
          return 2 * base.distance(from: separator, to: element) + 1
        case 3️⃣let (.element(start), .element(end)),
             4️⃣let (.separator(start), .separator(end)):
          return 2 * base.distance(from: start, to: end)
        }
        """,
      expected: """
        switch (start.representation, end.representation) {
        case (.element(let element), .separator(next: let separator)):
          return 2 * base.distance(from: element, to: separator) - 1
        case (.separator(next: let separator), .element(let element)):
          return 2 * base.distance(from: separator, to: element) + 1
        case (.element(let start), .element(let end)),
             (.separator(let start), .separator(let end)):
          return 2 * base.distance(from: start, to: end)
        }
        """,
      findings: [
        FindingSpec(
          "1️⃣",
          message: "move this 'let' keyword inside the 'case' pattern, before each of the bound variables"
        ),
        FindingSpec(
          "2️⃣",
          message: "move this 'let' keyword inside the 'case' pattern, before each of the bound variables"
        ),
        FindingSpec(
          "3️⃣",
          message: "move this 'let' keyword inside the 'case' pattern, before each of the bound variables"
        ),
        FindingSpec(
          "4️⃣",
          message: "move this 'let' keyword inside the 'case' pattern, before each of the bound variables"
        ),
      ]
    )
  }

  func testIfCase() {
    assertFormatting(
      UseLetInEveryBoundCaseVariable.self,
      input: """
        if case 1️⃣let .labeled(label, value) = DataPoint.labeled("hello", 100) {}
        if case .labeled(label, let value) = DataPoint.labeled("hello", 100) {}
        if case .labeled(let label, let value) = DataPoint.labeled("hello", 100) {}
        if case 2️⃣let .labeled(label, value)? = DataPoint.labeled("hello", 100) {}
        if case 3️⃣let .labeled(label, value)! = DataPoint.labeled("hello", 100) {}
        if case 4️⃣let .labeled(label, value)?? = DataPoint.labeled("hello", 100) {}
        if case 5️⃣let (label, value) = DataPoint.labeled("hello", 100) {}
        if case let x as SomeType = someValue {}
        if case 6️⃣var .labeled(label, value) = DataPoint.labeled("hello", 100) {}
        if case 7️⃣var (label, value) = DataPoint.labeled("hello", 100) {}
        """,
      expected: """
        if case .labeled(let label, let value) = DataPoint.labeled("hello", 100) {}
        if case .labeled(label, let value) = DataPoint.labeled("hello", 100) {}
        if case .labeled(let label, let value) = DataPoint.labeled("hello", 100) {}
        if case .labeled(let label, let value)? = DataPoint.labeled("hello", 100) {}
        if case .labeled(let label, let value)! = DataPoint.labeled("hello", 100) {}
        if case .labeled(let label, let value)?? = DataPoint.labeled("hello", 100) {}
        if case (let label, let value) = DataPoint.labeled("hello", 100) {}
        if case let x as SomeType = someValue {}
        if case .labeled(var label, var value) = DataPoint.labeled("hello", 100) {}
        if case (var label, var value) = DataPoint.labeled("hello", 100) {}
        """,
      findings: [
        FindingSpec(
          "1️⃣",
          message: "move this 'let' keyword inside the 'case' pattern, before each of the bound variables"
        ),
        FindingSpec(
          "2️⃣",
          message: "move this 'let' keyword inside the 'case' pattern, before each of the bound variables"
        ),
        FindingSpec(
          "3️⃣",
          message: "move this 'let' keyword inside the 'case' pattern, before each of the bound variables"
        ),
        FindingSpec(
          "4️⃣",
          message: "move this 'let' keyword inside the 'case' pattern, before each of the bound variables"
        ),
        FindingSpec(
          "5️⃣",
          message: "move this 'let' keyword inside the 'case' pattern, before each of the bound variables"
        ),
        FindingSpec(
          "6️⃣",
          message: "move this 'var' keyword inside the 'case' pattern, before each of the bound variables"
        ),
        FindingSpec(
          "7️⃣",
          message: "move this 'var' keyword inside the 'case' pattern, before each of the bound variables"
        ),
      ]
    )
  }

  func testGuardCase() {
    assertFormatting(
      UseLetInEveryBoundCaseVariable.self,
      input: """
        guard case 1️⃣let .labeled(label, value) = DataPoint.labeled("hello", 100) else {}
        guard case .labeled(label, let value) = DataPoint.labeled("hello", 100) else {}
        guard case .labeled(let label, let value) = DataPoint.labeled("hello", 100) else {}
        guard case 2️⃣let .labeled(label, value)? = DataPoint.labeled("hello", 100) else {}
        guard case 3️⃣let .labeled(label, value)! = DataPoint.labeled("hello", 100) else {}
        guard case 4️⃣let .labeled(label, value)?? = DataPoint.labeled("hello", 100) else {}
        guard case 5️⃣let (label, value) = DataPoint.labeled("hello", 100) else {}
        guard case let x as SomeType = someValue else {}
        guard case 6️⃣var .labeled(label, value) = DataPoint.labeled("hello", 100) else {}
        guard case 7️⃣var (label, value) = DataPoint.labeled("hello", 100) else {}
        """,
      expected: """
        guard case .labeled(let label, let value) = DataPoint.labeled("hello", 100) else {}
        guard case .labeled(label, let value) = DataPoint.labeled("hello", 100) else {}
        guard case .labeled(let label, let value) = DataPoint.labeled("hello", 100) else {}
        guard case .labeled(let label, let value)? = DataPoint.labeled("hello", 100) else {}
        guard case .labeled(let label, let value)! = DataPoint.labeled("hello", 100) else {}
        guard case .labeled(let label, let value)?? = DataPoint.labeled("hello", 100) else {}
        guard case (let label, let value) = DataPoint.labeled("hello", 100) else {}
        guard case let x as SomeType = someValue else {}
        guard case .labeled(var label, var value) = DataPoint.labeled("hello", 100) else {}
        guard case (var label, var value) = DataPoint.labeled("hello", 100) else {}
        """,
      findings: [
        FindingSpec(
          "1️⃣",
          message: "move this 'let' keyword inside the 'case' pattern, before each of the bound variables"
        ),
        FindingSpec(
          "2️⃣",
          message: "move this 'let' keyword inside the 'case' pattern, before each of the bound variables"
        ),
        FindingSpec(
          "3️⃣",
          message: "move this 'let' keyword inside the 'case' pattern, before each of the bound variables"
        ),
        FindingSpec(
          "4️⃣",
          message: "move this 'let' keyword inside the 'case' pattern, before each of the bound variables"
        ),
        FindingSpec(
          "5️⃣",
          message: "move this 'let' keyword inside the 'case' pattern, before each of the bound variables"
        ),
        FindingSpec(
          "6️⃣",
          message: "move this 'var' keyword inside the 'case' pattern, before each of the bound variables"
        ),
        FindingSpec(
          "7️⃣",
          message: "move this 'var' keyword inside the 'case' pattern, before each of the bound variables"
        ),
      ]
    )
  }

  func testForCase() {
    assertFormatting(
      UseLetInEveryBoundCaseVariable.self,
      input: """
        for case 1️⃣let .labeled(label, value) in dataPoints {}
        for case .labeled(label, let value) in dataPoints {}
        for case .labeled(let label, let value) in dataPoints {}
        for case 2️⃣let .labeled(label, value)? in dataPoints {}
        for case 3️⃣let .labeled(label, value)! in dataPoints {}
        for case 4️⃣let .labeled(label, value)?? in dataPoints {}
        for case 5️⃣let (label, value) in dataPoints {}
        for case let x as SomeType in {}
        for case 6️⃣var .labeled(label, value) in dataPoints {}
        for case 7️⃣var (label, value) in dataPoints {}
        """,
      expected: """
        for case .labeled(let label, let value) in dataPoints {}
        for case .labeled(label, let value) in dataPoints {}
        for case .labeled(let label, let value) in dataPoints {}
        for case .labeled(let label, let value)? in dataPoints {}
        for case .labeled(let label, let value)! in dataPoints {}
        for case .labeled(let label, let value)?? in dataPoints {}
        for case (let label, let value) in dataPoints {}
        for case let x as SomeType in {}
        for case .labeled(var label, var value) in dataPoints {}
        for case (var label, var value) in dataPoints {}
        """,
      findings: [
        FindingSpec(
          "1️⃣",
          message: "move this 'let' keyword inside the 'case' pattern, before each of the bound variables"
        ),
        FindingSpec(
          "2️⃣",
          message: "move this 'let' keyword inside the 'case' pattern, before each of the bound variables"
        ),
        FindingSpec(
          "3️⃣",
          message: "move this 'let' keyword inside the 'case' pattern, before each of the bound variables"
        ),
        FindingSpec(
          "4️⃣",
          message: "move this 'let' keyword inside the 'case' pattern, before each of the bound variables"
        ),
        FindingSpec(
          "5️⃣",
          message: "move this 'let' keyword inside the 'case' pattern, before each of the bound variables"
        ),
        FindingSpec(
          "6️⃣",
          message: "move this 'var' keyword inside the 'case' pattern, before each of the bound variables"
        ),
        FindingSpec(
          "7️⃣",
          message: "move this 'var' keyword inside the 'case' pattern, before each of the bound variables"
        ),
      ]
    )
  }

  func testWhileCase() {
    assertFormatting(
      UseLetInEveryBoundCaseVariable.self,
      input: """
        while case 1️⃣let .labeled(label, value) = iter.next() {}
        while case .labeled(label, let value) = iter.next() {}
        while case .labeled(let label, let value) = iter.next() {}
        while case 2️⃣let .labeled(label, value)? = iter.next() {}
        while case 3️⃣let .labeled(label, value)! = iter.next() {}
        while case 4️⃣let .labeled(label, value)?? = iter.next() {}
        while case 5️⃣let (label, value) = iter.next() {}
        while case let x as SomeType = iter.next() {}
        while case 6️⃣var .labeled(label, value) = iter.next()
        while case 7️⃣var (label, value) = iter.next()
        """,
      expected: """
        while case .labeled(let label, let value) = iter.next() {}
        while case .labeled(label, let value) = iter.next() {}
        while case .labeled(let label, let value) = iter.next() {}
        while case .labeled(let label, let value)? = iter.next() {}
        while case .labeled(let label, let value)! = iter.next() {}
        while case .labeled(let label, let value)?? = iter.next() {}
        while case (let label, let value) = iter.next() {}
        while case let x as SomeType = iter.next() {}
        while case .labeled(var label, var value) = iter.next()
        while case (var label, var value) = iter.next()
        """,
      findings: [
        FindingSpec(
          "1️⃣",
          message: "move this 'let' keyword inside the 'case' pattern, before each of the bound variables"
        ),
        FindingSpec(
          "2️⃣",
          message: "move this 'let' keyword inside the 'case' pattern, before each of the bound variables"
        ),
        FindingSpec(
          "3️⃣",
          message: "move this 'let' keyword inside the 'case' pattern, before each of the bound variables"
        ),
        FindingSpec(
          "4️⃣",
          message: "move this 'let' keyword inside the 'case' pattern, before each of the bound variables"
        ),
        FindingSpec(
          "5️⃣",
          message: "move this 'let' keyword inside the 'case' pattern, before each of the bound variables"
        ),
        FindingSpec(
          "6️⃣",
          message: "move this 'var' keyword inside the 'case' pattern, before each of the bound variables"
        ),
        FindingSpec(
          "7️⃣",
          message: "move this 'var' keyword inside the 'case' pattern, before each of the bound variables"
        ),
      ]
    )
  }
}
