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

/// Protocol that declares support for accessing and modifying a token that represents a semicolon.
protocol SemicolonSyntaxProtocol: SyntaxProtocol {
  var semicolon: TokenSyntax? { get }
  func withSemicolon(_ newSemicolon: TokenSyntax?) -> Self
}

extension MemberDeclListItemSyntax: SemicolonSyntaxProtocol {}
extension CodeBlockItemSyntax: SemicolonSyntaxProtocol {}

extension Syntax {
  func asProtocol(_: SemicolonSyntaxProtocol.Protocol) -> SemicolonSyntaxProtocol? {
    return self.asProtocol(SyntaxProtocol.self) as? SemicolonSyntaxProtocol
  }

  func isProtocol(_: SemicolonSyntaxProtocol.Protocol) -> Bool {
    return self.asProtocol(SemicolonSyntaxProtocol.self) != nil
  }
}
