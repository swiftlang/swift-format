@_spi(Rules) import SwiftFormat
import _SwiftFormatTestSupport

final class UseLetInEveryBoundCaseVariableTests: LintOrFormatRuleTestCase {
  func testSwitchCase() {
    assertLint(
      UseLetInEveryBoundCaseVariable.self,
      """
      switch DataPoint.labeled("hello", 100) {
      case 1️⃣let .labeled(label, value): break
      case .labeled(label, let value): break
      case .labeled(let label, let value): break
      case 2️⃣let .labeled(label, value)?: break
      case 3️⃣let .labeled(label, value)!: break
      case 4️⃣let .labeled(label, value)??: break
      case 5️⃣let (label, value): break
      case let x as SomeType: break
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
      ]
    )
  }

  func testIfCase() {
    assertLint(
      UseLetInEveryBoundCaseVariable.self,
      """
      if case 1️⃣let .labeled(label, value) = DataPoint.labeled("hello", 100) {}
      if case .labeled(label, let value) = DataPoint.labeled("hello", 100) {}
      if case .labeled(let label, let value) = DataPoint.labeled("hello", 100) {}
      if case 2️⃣let .labeled(label, value)? = DataPoint.labeled("hello", 100) {}
      if case 3️⃣let .labeled(label, value)! = DataPoint.labeled("hello", 100) {}
      if case 4️⃣let .labeled(label, value)?? = DataPoint.labeled("hello", 100) {}
      if case 5️⃣let (label, value) = DataPoint.labeled("hello", 100) {}
      if case let x as SomeType = someValue {}
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
      ]
    )
  }

  func testGuardCase() {
    assertLint(
      UseLetInEveryBoundCaseVariable.self,
      """
      guard case 1️⃣let .labeled(label, value) = DataPoint.labeled("hello", 100) else {}
      guard case .labeled(label, let value) = DataPoint.labeled("hello", 100) else {}
      guard case .labeled(let label, let value) = DataPoint.labeled("hello", 100) else {}
      guard case 2️⃣let .labeled(label, value)? = DataPoint.labeled("hello", 100) else {}
      guard case 3️⃣let .labeled(label, value)! = DataPoint.labeled("hello", 100) else {}
      guard case 4️⃣let .labeled(label, value)?? = DataPoint.labeled("hello", 100) else {}
      guard case 5️⃣let (label, value) = DataPoint.labeled("hello", 100) else {}
      guard case let x as SomeType = someValue else {}
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
      ]
    )
  }

  func testForCase() {
    assertLint(
      UseLetInEveryBoundCaseVariable.self,
      """
      for case 1️⃣let .labeled(label, value) in dataPoints {}
      for case .labeled(label, let value) in dataPoints {}
      for case .labeled(let label, let value) in dataPoints {}
      for case 2️⃣let .labeled(label, value)? in dataPoints {}
      for case 3️⃣let .labeled(label, value)! in dataPoints {}
      for case 4️⃣let .labeled(label, value)?? in dataPoints {}
      for case 5️⃣let (label, value) in dataPoints {}
      for case let x as SomeType in {}
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
      ]
    )
  }

  func testWhileCase() {
    assertLint(
      UseLetInEveryBoundCaseVariable.self,
      """
      while case 1️⃣let .labeled(label, value) = iter.next() {}
      while case .labeled(label, let value) = iter.next() {}
      while case .labeled(let label, let value) = iter.next() {}
      while case 2️⃣let .labeled(label, value)? = iter.next() {}
      while case 3️⃣let .labeled(label, value)! = iter.next() {}
      while case 4️⃣let .labeled(label, value)?? = iter.next() {}
      while case 5️⃣let (label, value) = iter.next() {}
      while case let x as SomeType = iter.next() {}
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
      ]
    )
  }
}
