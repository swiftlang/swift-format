@_spi(Rules) import SwiftFormat
import _SwiftFormatTestSupport

final class ReplaceForEachWithForLoopTests: LintOrFormatRuleTestCase {
  func test() {
    assertLint(
      ReplaceForEachWithForLoop.self,
      """
      values.1️⃣forEach { $0 * 2 }
      values.map { $0 }.2️⃣forEach { print($0) }
      values.forEach(callback)
      values.forEach { $0 }.chained()
      values.forEach({ $0 }).chained()
      values.3️⃣forEach {
        let arg = $0
        return arg + 1
      }
      values.forEach {
        let arg = $0
        return arg + 1
      } other: {
        42
      }
      """,
      findings: [
        FindingSpec("1️⃣", message: "replace use of '.forEach { ... }' with for-in loop"),
        FindingSpec("2️⃣", message: "replace use of '.forEach { ... }' with for-in loop"),
        FindingSpec("3️⃣", message: "replace use of '.forEach { ... }' with for-in loop"),
      ]
    )
  }
}
