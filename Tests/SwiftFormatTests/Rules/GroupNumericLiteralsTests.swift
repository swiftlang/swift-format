import SwiftFormatRules

final class GroupNumericLiteralsTests: LintOrFormatRuleTestCase {
  func testNumericGrouping() {
    XCTAssertFormatting(
      GroupNumericLiterals.self,
      input: """
             let a = 9876543210
             let b = 1234
             let c = 0x34950309233
             let d = -0x34242
             let e = 0b10010010101
             let f = 0b101
             let g = 11_15_1999
             let h = 0o21743
             let i = -53096828347
             let j = 0000123
             let k = 0x00000012
             let l = 0x0000012
             let m = 0b00010010101
             let n = [
               0xff00ff00,  // comment
               0x00ff00ff,  // comment
             ]
             """,
      expected: """
                let a = 9_876_543_210
                let b = 1234
                let c = 0x349_5030_9233
                let d = -0x34242
                let e = 0b100_10010101
                let f = 0b101
                let g = 11_15_1999
                let h = 0o21743
                let i = -53_096_828_347
                let j = 0_000_123
                let k = 0x0000_0012
                let l = 0x0000012
                let m = 0b000_10010101
                let n = [
                  0xff00_ff00,  // comment
                  0x00ff_00ff,  // comment
                ]
                """)
    XCTAssertDiagnosed(.groupNumericLiteral(every: 3))
    XCTAssertDiagnosed(.groupNumericLiteral(every: 3))
    XCTAssertDiagnosed(.groupNumericLiteral(every: 3))
    XCTAssertNotDiagnosed(.groupNumericLiteral(every: 3))
    XCTAssertDiagnosed(.groupNumericLiteral(every: 4))
    XCTAssertDiagnosed(.groupNumericLiteral(every: 4))
    XCTAssertDiagnosed(.groupNumericLiteral(every: 8))
    XCTAssertDiagnosed(.groupNumericLiteral(every: 8))
    XCTAssertNotDiagnosed(.groupNumericLiteral(every: 8))
    XCTAssertDiagnosed(.groupNumericLiteral(every: 4))
    XCTAssertDiagnosed(.groupNumericLiteral(every: 4))
  }
}
