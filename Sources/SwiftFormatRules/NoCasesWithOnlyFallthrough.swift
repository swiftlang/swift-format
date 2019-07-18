//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2019 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import Foundation
import SwiftFormatCore
import SwiftSyntax

/// Cases that contain only the `fallthrough` statement are forbidden.
///
/// Lint: Cases containing only the `fallthrough` statement yield a lint error.
///
/// Format: The fallthrough `case` is added as a prefix to the next case unless the next case is
///         `default`; in that case, the fallthrough `case` is deleted.
///
/// - SeeAlso: https://google.github.io/swift#fallthrough-in-switch-statements
public final class NoCasesWithOnlyFallthrough: SyntaxFormatRule {

  public override func visit(_ node: SwitchStmtSyntax) -> StmtSyntax {
    var newCases: [SwitchCaseSyntax] = []
    var violations: [SwitchCaseLabelSyntax] = []

    for switchCase in node.cases {
      guard let switchCase = switchCase as? SwitchCaseSyntax else { continue }
      guard let label = switchCase.label as? SwitchCaseLabelSyntax else {
        newCases.append(switchCase)
        continue
      }

      if switchCase.statements.count == 1,
        let only = switchCase.statements.first,
        only.item is FallthroughStmtSyntax
      {
        diagnose(.collapseCase(name: "\(label)"), on: switchCase)
        violations.append(label)
      } else {
        guard violations.count > 0 else {
          newCases.append(switchCase)
          continue
        }

        if retrieveNumericCaseValue(caseLabel: label) != nil {
          let newCase = collapseIntegerCases(
            violations: violations,
            validCaseLabel: label,
            validCase: switchCase)
          newCases.append(newCase)
        } else {
          let newCase = collapseNonIntegerCases(
            violations: violations,
            validCaseLabel: label,
            validCase: switchCase)
          newCases.append(newCase)
        }
        violations = []
      }
    }
    return node.withCases(SyntaxFactory.makeSwitchCaseList(newCases))
  }

  // Puts all given cases on one line with range operator or commas
  func collapseIntegerCases(
    violations: [SwitchCaseLabelSyntax],
    validCaseLabel: SwitchCaseLabelSyntax, validCase: SwitchCaseSyntax
  ) -> SwitchCaseSyntax {
    var isConsecutive = true
    var index = 0
    var caseNums: [Int] = []

    for item in violations {
      guard let caseNum = retrieveNumericCaseValue(caseLabel: item) else { continue }
      caseNums.append(caseNum)
    }

    guard let validCaseNum = retrieveNumericCaseValue(caseLabel: validCaseLabel) else {
      return validCase
    }
    caseNums.append(validCaseNum)

    while index <= caseNums.count - 2, isConsecutive {
      isConsecutive = caseNums[index] + 1 == caseNums[index + 1]
      index += 1
    }

    var newCaseItems: [CaseItemSyntax] = []
    let first = caseNums[0]
    let last = caseNums[caseNums.count - 1]
    if isConsecutive {
      // Create a case with a sequence expression based on the new range
      let start = SyntaxFactory.makeIntegerLiteralExpr(
        digits: SyntaxFactory.makeIntegerLiteral("\(first)"))
      let end = SyntaxFactory.makeIntegerLiteralExpr(
        digits: SyntaxFactory.makeIntegerLiteral("\(last)"))
      let newExpList = SyntaxFactory.makeExprList(
        [
          start,
          SyntaxFactory.makeBinaryOperatorExpr(
            operatorToken:
              SyntaxFactory.makeUnspacedBinaryOperator("...")),
          end
        ])
      let newExpPat = SyntaxFactory.makeExpressionPattern(
        expression: SyntaxFactory.makeSequenceExpr(elements: newExpList))
      newCaseItems.append(
        SyntaxFactory.makeCaseItem(pattern: newExpPat, whereClause: nil, trailingComma: nil))
    } else {
      // Add each case item separated by a comma
      for num in caseNums {
        let newExpPat = SyntaxFactory.makeExpressionPattern(
          expression: SyntaxFactory.makeIntegerLiteralExpr(
            digits: SyntaxFactory.makeIntegerLiteral("\(num)")))
        let trailingComma = SyntaxFactory.makeCommaToken(trailingTrivia: .spaces(1))
        let newCaseItem = SyntaxFactory.makeCaseItem(
          pattern: newExpPat,
          whereClause: nil,
          trailingComma: num == last ? nil : trailingComma
        )
        newCaseItems.append(newCaseItem)
      }
    }
    let caseItemList = SyntaxFactory.makeCaseItemList(newCaseItems)
    return validCase.withLabel(validCaseLabel.withCaseItems(caseItemList))
  }

  // Gets integer value from case label, if possible
  func retrieveNumericCaseValue(caseLabel: SwitchCaseLabelSyntax) -> Int? {
    if let firstTok = caseLabel.caseItems.firstToken, let num = Int(firstTok.text) {
      return num
    }
    return nil
  }

  // Puts all given cases on one line separated by commas
  func collapseNonIntegerCases(
    violations: [SwitchCaseLabelSyntax],
    validCaseLabel: SwitchCaseLabelSyntax, validCase: SwitchCaseSyntax
  ) -> SwitchCaseSyntax {
    var newCaseItems: [CaseItemSyntax] = []
    for violation in violations {
      for item in violation.caseItems {
        let newCaseItem = item.withTrailingComma(
          SyntaxFactory.makeCommaToken(trailingTrivia: .spaces(1)))
        newCaseItems.append(newCaseItem)
      }
    }
    for item in validCaseLabel.caseItems {
      newCaseItems.append(item)
    }
    let caseItemList = SyntaxFactory.makeCaseItemList(newCaseItems)
    return validCase.withLabel(validCaseLabel.withCaseItems(caseItemList))
  }
}

extension Diagnostic.Message {
  static func collapseCase(name: String) -> Diagnostic.Message {
    return .init(
      .warning,
      "\(name) only contains 'fallthrough' and can be combined with a following case")
  }
}
