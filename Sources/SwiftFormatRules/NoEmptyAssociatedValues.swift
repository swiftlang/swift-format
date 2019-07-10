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

/// Enum cases should not have an empty set of parentheses if they have no associated values.
///
/// Lint: If an enum case has an empty set of parentheses, declaring no associated values, a lint
///       error is raised.
///
/// Format: Enum cases with empty parentheses will have their parentheses removed.
///
/// - SeeAlso: https://google.github.io/swift#enum-cases
public final class NoEmptyAssociatedValues: SyntaxFormatRule {
  public override func visit(_ node: EnumCaseDeclSyntax) -> DeclSyntax {
    for element in node.elements {
      guard let associatedValue = element.associatedValue else { continue }
      if associatedValue.parameterList.count == 0 {
        diagnose(.removeEmptyParentheses(name: element.identifier.text), on: element)
        let newDecl = node.withElements(
          node.elements.replacing(
            childAt: element.indexInParent, with: element.withAssociatedValue(nil)))
        return newDecl
      }
    }
    return node
  }
}

extension Diagnostic.Message {
  static func removeEmptyParentheses(name: String) -> Diagnostic.Message {
    return .init(.warning, "Remove '()' after \(name)")
  }
}
