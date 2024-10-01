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
protocol WithSemicolonSyntax: SyntaxProtocol {
  var semicolon: TokenSyntax? { get set }
}

extension MemberBlockItemSyntax: WithSemicolonSyntax {}
extension CodeBlockItemSyntax: WithSemicolonSyntax {}

extension SyntaxProtocol {
  func asProtocol(_: WithSemicolonSyntax.Protocol) -> WithSemicolonSyntax? {
    return Syntax(self).asProtocol(SyntaxProtocol.self) as? WithSemicolonSyntax
  }

  func isProtocol(_: WithSemicolonSyntax.Protocol) -> Bool {
    return self.asProtocol(WithSemicolonSyntax.self) != nil
  }
}
