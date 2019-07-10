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

/// Numeric literals should be grouped with `_`s to delimit common separators.
/// Specifically, decimal numeric literals should be grouped every 3 numbers, hexadecimal every 4,
/// and binary every 8.
///
/// Lint: If a numeric literal is too long and should be grouped, a lint error is raised.
///
/// Format: All numeric literals that should be grouped will have `_`s inserted where appropriate.
///
/// TODO: Minimum numeric literal length bounds and numeric groupings selected arbitrarily, could
///       be  reevaluated.
///
/// TODO: Handle floating point literals
///
/// - SeeAlso: https://google.github.io/swift#numeric-literals
public final class GroupNumericLiterals: SyntaxFormatRule {
  public override func visit(_ node: IntegerLiteralExprSyntax) -> ExprSyntax {

    var digits = node.digits.text
    guard !digits.contains("_") else { return node }

    let isNegative = digits.first == "-"
    digits = isNegative ? String(digits.dropFirst()) : digits

    var newDigits = ""

    switch digits.prefix(2) {
    case "0x":
      // Hexadecimal
      let digitsNoPrefix = String(digits.dropFirst(2))
      guard let intDigits = Int(digitsNoPrefix, radix: 16) else { return node }
      guard intDigits >= 0x1000_0000 else { return node }
      diagnose(.groupNumericLiteral(byStride: 4), on: node)
      newDigits = "0x" + groupDigitsByStride(digits: digitsNoPrefix, stride: 4)
    case "0b":
      // Binary
      let digitsNoPrefix = String(digits.dropFirst(2))
      guard let intDigits = Int(digitsNoPrefix, radix: 2) else { return node }
      guard intDigits >= 0b1_000000000 else { return node }
      diagnose(.groupNumericLiteral(byStride: 8), on: node)
      newDigits = "0b" + groupDigitsByStride(digits: digitsNoPrefix, stride: 8)
    case "0o":
      // Octal
      return node
    default:
      // Decimal
      guard let intDigits = Int(digits) else { return node }
      guard intDigits >= 1_000_000 else { return node }
      diagnose(.groupNumericLiteral(byStride: 3), on: node)
      newDigits = groupDigitsByStride(digits: digits, stride: 3)
    }

    newDigits = isNegative ? "-" + newDigits : newDigits
    return node.withDigits(SyntaxFactory.makeIdentifier(newDigits))
  }

  func groupDigitsByStride(digits: String, stride: Int) -> String {
    var newGrouping = Array(digits)
    var i = 1
    while i * stride < digits.count {
      newGrouping.insert("_", at: digits.count - i * stride)
      i += 1
    }
    return String(newGrouping)
  }
}

extension Diagnostic.Message {
  static func groupNumericLiteral(byStride: Int) -> Diagnostic.Message {
    let ending = byStride == 3 ? "rd" : "th"
    return .init(.warning, "group numeric literal using '_' every \(byStride)\(ending) number")
  }
}
