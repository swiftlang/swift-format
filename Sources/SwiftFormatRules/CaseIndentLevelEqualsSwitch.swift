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

/// Each `case` of a `switch` statement must be indented the same as the `switch` keyword.
///
/// Lint: If a case's indentation is over- or under-indented relative to the `switch` keyword, a
///       lint error is raised.
///
/// - SeeAlso: https://google.github.io/swift#switch-statements
public struct CaseIndentLevelEqualsSwitch: SyntaxLintRule {

  public let context: Context

  public init(context: Context) {
    self.context = context
  }

  public func visit(_ node: SwitchStmtSyntax) -> SyntaxVisitorContinueKind {
    guard let switchIndentation = node.leadingTrivia?.numberOfSpaces else {
      return .visitChildren
    }

    // Ensure the number of spaces in the indentation of each case is the same as that of the
    // switch statement.
    for caseStatement in node.cases {
      guard let caseTrivia = caseStatement.leadingTrivia else { continue }

      if caseTrivia.numberOfSpaces != switchIndentation {
        let difference = switchIndentation - caseTrivia.numberOfSpaces
        diagnose(.adjustCaseIndentation(by: difference), on: node)
      }
    }

    return .visitChildren
  }
}

extension Diagnostic.Message {

  static func adjustCaseIndentation(by count: Int) -> Diagnostic.Message {
    let ending = abs(count) == 1 ? "" : "s"
    if count < 0 {
      return Diagnostic.Message(
        .warning,
        "remove \(abs(count)) space\(ending) from the indentation of this case"
      )
    } else {
      return Diagnostic.Message(
        .warning,
        "add \(abs(count)) space\(ending) to the indentation of this case"
      )
    }
  }
}
