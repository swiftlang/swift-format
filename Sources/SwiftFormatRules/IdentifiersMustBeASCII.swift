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

/// All identifiers must be ASCII.
///
/// Lint: If an identifier contains non-ASCII characters, a lint error is raised.
///
/// - SeeAlso: https://google.github.io/swift#identifiers
public final class IdentifiersMustBeASCII: SyntaxLintRule {

  public override func visit(_ node: IdentifierPatternSyntax) -> SyntaxVisitorContinueKind {
    let identifier = node.identifier.text
    let invalidCharacters = identifier.unicodeScalars.filter { !$0.isASCII }.map { $0.description }

    if !invalidCharacters.isEmpty {
      diagnose(.nonASCIICharsNotAllowed(invalidCharacters, identifier), on: node)
    }

    return .skipChildren
  }
}

extension Diagnostic.Message {
  static func nonASCIICharsNotAllowed(_ invalidCharacters: [String], _ identifierName: String)
    -> Diagnostic.Message
  {
    return .init(
      .warning,
      "The identifier '\(identifierName)' contains the following non-ASCII characters: \(invalidCharacters.joined(separator: ", "))"
    )
  }
}
