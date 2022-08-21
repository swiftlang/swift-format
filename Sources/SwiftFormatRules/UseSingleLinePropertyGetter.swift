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

/// Read-only computed properties must use implicit `get` blocks.
///
/// Lint: Read-only computed properties with explicit `get` blocks yield a lint error.
///
/// Format: Explicit `get` blocks are rendered implicit by removing the `get`.
public final class UseSingleLinePropertyGetter: SyntaxFormatRule {

  public override func visit(_ node: PatternBindingSyntax) -> Syntax {
    guard
      let accessorBlock = node.accessor?.as(AccessorBlockSyntax.self),
      let acc = accessorBlock.accessors.first,
      let body = acc.body,
      accessorBlock.accessors.count == 1,
      acc.accessorKind.tokenKind == .contextualKeyword("get"),
      acc.attributes == nil,
      acc.modifier == nil,
      acc.asyncKeyword == nil,
      acc.throwsKeyword == nil
    else { return Syntax(node) }

    diagnose(.removeExtraneousGetBlock, on: acc)

    let newBlock = CodeBlockSyntax(
      leftBrace: accessorBlock.leftBrace, statements: body.statements,
      rightBrace: accessorBlock.rightBrace)
    return Syntax(node.withAccessor(Syntax(newBlock)))
  }
}

extension Finding.Message {
  public static let removeExtraneousGetBlock: Finding.Message =
    "remove extraneous 'get {}' block"
}
