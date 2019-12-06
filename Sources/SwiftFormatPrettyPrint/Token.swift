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

import SwiftFormatConfiguration
import SwiftFormatCore
import SwiftSyntax

enum GroupBreakStyle {
  /// A consistent break indicates that the break will always be finalized as a newline
  /// if wrapping occurs.
  case consistent

  /// Inconsistent breaks will only be expressed as a newline if they're required to be wrapped as
  /// their addition to the line would go past the line length limit.
  case inconsistent
}

enum OpenBreakKind: Equatable {
  /// An open break that applies a block indent to its scope and is allowed to apply a continuation
  /// indent if and only if the line on which the open break occurs is a continuation line.
  case block

  /// An open break that always applies up to one continuation indent to its scope. A continuation
  /// indent is applied if either the line on which this break is encountered is a continuation or
  /// if this break fires. A continuation open break never applies a block indent to its scope.
  case continuation
}

enum BreakKind: Equatable {
  /// If line wrapping occurs at an `open` break, then the base indentation level increases by one
  /// indentation unit until the corresponding `close` break is encountered.
  case open(kind: OpenBreakKind)

  /// If line wrapping occurs at a `close` break, then the base indentation level returns to the
  /// value it had before the corresponding `open` break.
  ///
  /// If `mustBreak` is true, then this break will always produce a line break when it occurs on a
  /// different line than its corresponding `open` break. This is the behavior one typically wants
  /// when laying out curly-brace delimited blocks or array/dictionary literals. If `mustBreak` is
  /// false, then this break will only produce a line break when absolutely necessary (i.e., if the
  /// rest of the line's length required it). This behavior is desirable for the parentheses around
  /// function calls, where there is not typically a need for a line break before the closing
  /// parenthesis.
  ///
  /// In either case above, the base indentation level of subsequent tokens is still adjusted.
  case close(mustBreak: Bool)

  /// If line wrapping occurs at a `continue` break, then the following line will be treated as a
  /// continuation line (indented one unit further than the base level) without changing the base
  /// level.
  ///
  /// An example use of a `continue` break is when an expression is split across multiple lines;
  /// the break before each operator is a continuation:
  ///
  /// ```swift
  /// let someLongVariable = someLongExpression
  ///   + anotherLongExpression - aThirdLongExpression
  ///   + somethingElse
  /// ```
  case `continue`

  /// If line wrapping occurs at a `same` break, then the following line will be indented at the
  /// base indentation level instead of an increased continuation level.
  ///
  /// An example use of a `same` break is to align the first element on each line in a
  /// comma-delimited list:
  ///
  /// ```swift
  /// let array = [
  ///   1, 2, 3,
  ///   4, 5, 6,
  ///   7, 8, 9,
  /// ]
  /// ```
  case same

  /// A `reset` break that occurs on a continuation line forces a line break that ends the
  /// continuation and causes the tokens on the next line to be indented at the base indentation
  /// level.
  ///
  /// These breaks are used, for example, to force an open curly brace onto a new line if it would
  /// otherwise fit on a continuation line, so that the body of the braced block can be
  /// distinguished from the continuation line(s) above it:
  ///
  /// ```swift
  /// func foo(_ x: Int) {
  ///   // This is allowed because the line above is not a continuation.
  /// }
  ///
  /// func foo(
  ///   _ x: Int
  /// ) {
  ///   // This is also allowed, for the same reason.
  /// }
  ///
  /// func foo(_ x: Int)
  ///   throws -> Int
  /// {
  ///   // Here we must force the brace down or the block contents would
  ///   // collide with the "throws" line.
  /// }
  /// ```
  case reset

  /// A `close` break that defaults to forced breaking behavior.
  static let close = BreakKind.close(mustBreak: true)

  /// An `open` break that defaults to applying a block indent to its scope.
  static let open = BreakKind.open(kind: .block)
}

enum NewlineKind {
  /// A newline that has been inserted by the formatter independent of the source code given by the
  /// user (for example, between the getter and setter blocks of a computed property).
  ///
  /// Flexible newlines are only printed if a discretionary or mandatory newline has not yet been
  /// printed at the same location, and only up to the maximum allowed by the formatter
  /// configuration.
  case flexible

  /// A newline that was present in the source code given by the user (that is, at the user's
  /// discretion).
  ///
  /// Discretionary newlines are printed after excluding any other consecutive newlines printed thus
  /// far at the same location, and only up to the maximum allowed by the formatter configuration.
  case discretionary

  /// A mandatory newline that must always be printed (for example, in a multiline string literal).
  ///
  /// Mandatory newlines are never omitted by the pretty printer, even if it would result in a
  /// number of consecutive newlines that exceeds that allowed by the formatter configuration.
  case mandatory
}

/// Kinds of printer control tokens that can be used to customize the pretty printer's behavior in
/// a subsection of a token stream.
enum PrinterControlKind {
  /// A signal that break tokens shouldn't be allowed to fire until a corresponding enable breaking
  /// control token is encountered.
  ///
  /// It's valid to nest `disableBreaking` and `enableBreaking` tokens. Breaks will be suppressed
  /// long as there is at least 1 unmatched disable token.
  case disableBreaking

  /// A signal that break tokens should be allowed to fire following this token, as long as there
  /// are no other unmatched disable tokens.
  case enableBreaking
}

enum Token {
  case syntax(String)
  case open(GroupBreakStyle)
  case close
  case `break`(BreakKind, size: Int, ignoresDiscretionary: Bool)
  case space(size: Int, flexible: Bool)
  case newlines(Int, kind: NewlineKind)
  case comment(Comment, wasEndOfLine: Bool)
  case verbatim(Verbatim)
  case printerControl(kind: PrinterControlKind)

  // Convenience overloads for the enum types
  static let open = Token.open(.inconsistent, 0)

  static func open(_ breakStyle: GroupBreakStyle, _ offset: Int) -> Token {
    return Token.open(breakStyle)
  }

  /// A single, flexible newline.
  static let newline = Token.newlines(1, kind: .flexible)

  /// Returns a single newline with the given kind.
  static func newline(kind: NewlineKind) -> Token {
    return Token.newlines(1, kind: kind)
  }

  static let space = Token.space(size: 1, flexible: false)

  static func space(size: Int) -> Token {
    return .space(size: size, flexible: false)
  }

  static let `break` = Token.break(.continue, size: 1, ignoresDiscretionary: false)

  static func `break`(_ kind: BreakKind, size: Int = 1) -> Token {
    return .break(kind, size: size, ignoresDiscretionary: false)
  }

  static func verbatim(text: String) -> Token {
    return Token.verbatim(Verbatim(text: text))
  }
}
