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

/// All identifiers must be ASCII.
///
/// Lint: If an identifier contains non-ASCII characters, a lint error is raised.
@_spi(Rules)
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

extension Finding.Message {
  fileprivate static func nonASCIICharsNotAllowed(
    _ invalidCharacters: [String],
    _ identifierName: String
  ) -> Finding.Message {
    """
    remove non-ASCII characters from '\(identifierName)': \
    \(invalidCharacters.joined(separator: ", "))
    """
  }
}
