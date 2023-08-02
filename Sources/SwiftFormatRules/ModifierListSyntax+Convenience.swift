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
    let newModifiers = filter { $0.name.text != name }
    return DeclModifierListSyntax(newModifiers)
  }

  /// Returns a formatted declaration modifier token with the given name.
  func createModifierToken(name: String) -> DeclModifierSyntax {
    let id = TokenSyntax.identifier(name, trailingTrivia: .spaces(1))
    let newModifier = DeclModifierSyntax(name: id, detail: nil)
    return newModifier
  }

  /// Returns modifiers with the given modifier inserted at the given index.
  /// Preserves existing trivia and formats new trivia, given true for 'formatTrivia.'
  func insert(
    modifier: DeclModifierSyntax, at index: Int,
    formatTrivia: Bool = true
  ) -> DeclModifierListSyntax {
    guard index >= 0, index <= count else { return self }

    var newModifiers: [DeclModifierSyntax] = []
    newModifiers.append(contentsOf: self)

    let modifier = formatTrivia
      ? replaceTrivia(
        on: modifier,
        token: modifier.name,
        trailingTrivia: .spaces(1)) : modifier

    if index == 0 {
      guard formatTrivia else {
        newModifiers.insert(modifier, at: index)
        return DeclModifierListSyntax(newModifiers)
      }
      guard let firstMod = first, let firstTok = firstMod.firstToken(viewMode: .sourceAccurate) else {
        newModifiers.insert(modifier, at: index)
        return DeclModifierListSyntax(newModifiers)
      }
      let formattedMod = replaceTrivia(
        on: modifier,
        token: modifier.firstToken(viewMode: .sourceAccurate),
        leadingTrivia: firstTok.leadingTrivia)
      newModifiers[0] = replaceTrivia(
        on: firstMod,
        token: firstTok,
        leadingTrivia: [],
        trailingTrivia: .spaces(1))
      newModifiers.insert(formattedMod, at: 0)
      return DeclModifierListSyntax(newModifiers)
    } else {
      newModifiers.insert(modifier, at: index)
      return DeclModifierListSyntax(newModifiers)
    }
  }

  /// Returns modifier list with the given modifier at the end.
  /// Trivia manipulation optional by 'formatTrivia'
  func append(modifier: DeclModifierSyntax, formatTrivia: Bool = true) -> DeclModifierListSyntax {
    return insert(modifier: modifier, at: count, formatTrivia: formatTrivia)
  }

  /// Returns modifier list with the given modifier at the beginning.
  /// Trivia manipulation optional by 'formatTrivia'
  func prepend(modifier: DeclModifierSyntax, formatTrivia: Bool = true) -> DeclModifierListSyntax {
    return insert(modifier: modifier, at: 0, formatTrivia: formatTrivia)
  }
}
