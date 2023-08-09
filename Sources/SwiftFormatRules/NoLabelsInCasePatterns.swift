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

/// Redundant labels are forbidden in case patterns.
///
/// In practice, *all* case pattern labels should be redundant.
///
/// Lint: Using a label in a case statement yields a lint error unless the label does not match the
///       binding identifier.
///
/// Format: Redundant labels in case patterns are removed.
public final class NoLabelsInCasePatterns: SyntaxFormatRule {
  public override func visit(_ node: SwitchCaseLabelSyntax) -> SwitchCaseLabelSyntax {
    var newCaseItems: [SwitchCaseItemSyntax] = []
    for item in node.caseItems {
      guard let expPat = item.pattern.as(ExpressionPatternSyntax.self) else {
        newCaseItems.append(item)
        continue
      }
      guard let funcCall = expPat.expression.as(FunctionCallExprSyntax.self) else {
        newCaseItems.append(item)
        continue
      }

      // Search function call argument list for violations
      var newArgs: [LabeledExprSyntax] = []
      for argument in funcCall.arguments {
        guard let label = argument.label else {
          newArgs.append(argument)
          continue
        }
        guard let unresolvedPat = argument.expression.as(PatternExprSyntax.self),
          let valueBinding = unresolvedPat.pattern.as(ValueBindingPatternSyntax.self)
        else {
          newArgs.append(argument)
          continue
        }

        // Remove label if it's the same as the value identifier
        let name = valueBinding.pattern.with(\.leadingTrivia, []).with(\.trailingTrivia, []).description
        guard name == label.text else {
          newArgs.append(argument)
          continue
        }
        diagnose(.removeRedundantLabel(name: name), on: label)
        newArgs.append(argument.with(\.label, nil).with(\.colon, nil))
      }

      let newArgList = LabeledExprListSyntax(newArgs)
      let newFuncCall = funcCall.with(\.arguments, newArgList)
      let newExpPat = expPat.with(\.expression, ExprSyntax(newFuncCall))
      let newItem = item.with(\.pattern, PatternSyntax(newExpPat))
      newCaseItems.append(newItem)
    }
    let newCaseItemList = SwitchCaseItemListSyntax(newCaseItems)
    return node.with(\.caseItems, newCaseItemList)
  }
}

extension Finding.Message {
  public static func removeRedundantLabel(name: String) -> Finding.Message {
    "remove the label '\(name)' from this 'case' pattern"
  }
}
