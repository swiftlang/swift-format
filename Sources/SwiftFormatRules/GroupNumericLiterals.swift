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

import SwiftFormatCore
import SwiftSyntax

/// Numeric literals should be grouped with `_`s to delimit common separators.
///
/// Specifically, decimal numeric literals should be grouped every 3 numbers, hexadecimal every 4,
/// and binary every 8.
///
/// Lint: If a numeric literal is too long and should be grouped, a lint error is raised.
///
/// Format: All numeric literals that should be grouped will have `_`s inserted where appropriate.
///
/// TODO: Minimum numeric literal length bounds and numeric groupings have been selected arbitrarily;
/// these could be reevaluated.
/// TODO: Handle floating point literals.
public final class GroupNumericLiterals: SyntaxFormatRule {
  public override func visit(_ node: IntegerLiteralExprSyntax) -> ExprSyntax {
    var originalDigits = node.digits.text
    guard !originalDigits.contains("_") else { return ExprSyntax(node) }

    let isNegative = originalDigits.first == "-"
    originalDigits = isNegative ? String(originalDigits.dropFirst()) : originalDigits

    var newDigits = ""

    switch originalDigits.prefix(2) {
    case "0x":
      // Hexadecimal
      let digitsNoPrefix = String(originalDigits.dropFirst(2))
      guard digitsNoPrefix.count >= 8 else { return ExprSyntax(node) }
      diagnose(.groupNumericLiteral(every: 4), on: node)
      newDigits = "0x" + digits(digitsNoPrefix, groupedEvery: 4)
    case "0b":
      // Binary
      let digitsNoPrefix = String(originalDigits.dropFirst(2))
      guard digitsNoPrefix.count >= 10 else { return ExprSyntax(node) }
      diagnose(.groupNumericLiteral(every: 8), on: node)
      newDigits = "0b" + digits(digitsNoPrefix, groupedEvery: 8)
    case "0o":
      // Octal
      return ExprSyntax(node)
    default:
      // Decimal
      guard originalDigits.count >= 7 else { return ExprSyntax(node) }
      diagnose(.groupNumericLiteral(every: 3), on: node)
      newDigits = digits(originalDigits, groupedEvery: 3)
    }

    newDigits = isNegative ? "-" + newDigits : newDigits
    let result = node.withDigits(
      TokenSyntax.integerLiteral(
        newDigits,
        leadingTrivia: node.digits.leadingTrivia,
        trailingTrivia: node.digits.trailingTrivia))
    return ExprSyntax(result)
  }

  /// Returns a copy of the given string with an underscore (`_`) inserted between every group of
  /// `stride` digits, counting from the right.
  ///
  /// Precondition: `digits` does not already contain underscores.
  private func digits(_ digits: String, groupedEvery stride: Int) -> String {
    var newGrouping = Array(digits)
    var i = 1
    while i * stride < digits.count {
      newGrouping.insert("_", at: digits.count - i * stride)
      i += 1
    }
    return String(newGrouping)
  }
}

extension Finding.Message {
  public static func groupNumericLiteral(every stride: Int) -> Finding.Message {
    let ending = stride == 3 ? "rd" : "th"
    return "group numeric literal using '_' every \(stride)\(ending) number"
  }
}
