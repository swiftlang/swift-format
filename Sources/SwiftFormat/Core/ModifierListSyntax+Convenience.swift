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

extension DeclModifierListSyntax {

  func has(modifier: String) -> Bool {
    return contains { $0.name.text == modifier }
  }

  func has(modifier: TokenKind) -> Bool {
    return contains { $0.name.tokenKind == modifier }
  }

  /// Returns the declaration's access level modifier, if present.
  var accessLevelModifier: DeclModifierSyntax? {
    for modifier in self {
      switch modifier.name.tokenKind {
      case .keyword(.public), .keyword(.private), .keyword(.fileprivate), .keyword(.internal):
        return modifier
      default:
        continue
      }
    }
    return nil
  }

  /// Returns modifier list without the given modifier.
  func remove(name: String) -> DeclModifierListSyntax {
    return filter { $0.name.text != name }
  }

  /// Returns a formatted declaration modifier token with the given name.
  func createModifierToken(name: String) -> DeclModifierSyntax {
    let id = TokenSyntax.identifier(name, trailingTrivia: .spaces(1))
    let newModifier = DeclModifierSyntax(name: id, detail: nil)
    return newModifier
  }

  /// Inserts the given modifier into the list at a specific index.
  ///
  /// If the modifier is being inserted at the front of the list, the current front element's
  /// leading trivia will be moved to the new element to preserve any leading comments and newlines.
  mutating func triviaPreservingInsert(
    _ modifier: DeclModifierSyntax, at index: SyntaxChildrenIndex
  ) {
    var modifier = modifier
    modifier.trailingTrivia = [.spaces(1)]

    guard index == self.startIndex else {
      self.insert(modifier, at: index)
      return
    }
    guard var firstMod = first, let firstTok = firstMod.firstToken(viewMode: .sourceAccurate) else {
      self.insert(modifier, at: index)
      return
    }

    modifier.leadingTrivia = firstTok.leadingTrivia
    firstMod.leadingTrivia = []
    firstMod.trailingTrivia = [.spaces(1)]
    self[self.startIndex] = firstMod
    self.insert(modifier, at: self.startIndex)
  }
}
