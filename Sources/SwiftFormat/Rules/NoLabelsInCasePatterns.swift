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
import SwiftSyntax

/// Redundant labels are forbidden in case patterns.
///
/// In practice, *all* case pattern labels should be redundant.
///
/// Lint: Using a label in a case statement yields a lint error unless the label does not match the
///       binding identifier.
///
/// Format: Redundant labels in case patterns are removed.
@_spi(Rules)
public final class NoLabelsInCasePatterns: SyntaxFormatRule {
  public override func visit(_ node: SwitchCaseLabelSyntax) -> SwitchCaseLabelSyntax {
    var newCaseItems: [SwitchCaseItemSyntax] = []

    for item in node.caseItems {
      guard
        var exprPattern = item.pattern.as(ExpressionPatternSyntax.self),
        var funcCall = exprPattern.expression.as(FunctionCallExprSyntax.self)
      else {
        newCaseItems.append(item)
        continue
      }

      // Search function call argument list for violations
      var newArguments = LabeledExprListSyntax()
      for argument in funcCall.arguments {
        guard
          let label = argument.label,
          let unresolvedPat = argument.expression.as(PatternExprSyntax.self),
          let valueBinding = unresolvedPat.pattern.as(ValueBindingPatternSyntax.self)
        else {
          newArguments.append(argument)
          continue
        }

        // Remove label if it's the same as the value identifier
        let name = valueBinding.pattern.trimmedDescription
        guard name == label.text else {
          newArguments.append(argument)
          continue
        }
        diagnose(.removeRedundantLabel(name: name), on: label)

        var newArgument = argument
        newArgument.label = nil
        newArgument.colon = nil
        newArguments.append(newArgument)
      }

      var newItem = item
      funcCall.arguments = newArguments
      exprPattern.expression = ExprSyntax(funcCall)
      newItem.pattern = PatternSyntax(exprPattern)
      newCaseItems.append(newItem)
    }

    var result = node
    result.caseItems = SwitchCaseItemListSyntax(newCaseItems)
    return result
  }
}

extension Finding.Message {
  @_spi(Rules)
  public static func removeRedundantLabel(name: String) -> Finding.Message {
    "remove the label '\(name)' from this 'case' pattern"
  }
}
