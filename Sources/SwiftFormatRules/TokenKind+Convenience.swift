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

import SwiftSyntax

extension TokenKind {
  /// Whether this token is the 'left' token of a pair of balanced
  /// delimiters (paren, angle bracket, square bracket.)
  var isLeftBalancedDelimiter: Bool {
    switch self {
    case .leftParen, .leftSquareBracket, .leftAngle:
      return true
    default:
      return false
    }
  }

  /// Whether this token is the 'right' token of a pair of balanced
  /// delimiters (paren, angle bracket, square bracket.)
  var isRightBalancedDelimiter: Bool {
    switch self {
    case .rightParen, .rightSquareBracket, .rightAngle:
      return true
    default:
      return false
    }
  }
}
