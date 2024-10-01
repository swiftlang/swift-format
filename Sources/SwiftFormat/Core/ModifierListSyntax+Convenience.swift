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
  /// Returns the declaration's access level modifier, if present.
  var accessLevelModifier: DeclModifierSyntax? {
    for modifier in self {
      switch modifier.name.tokenKind {
      case .keyword(.public), .keyword(.private), .keyword(.fileprivate), .keyword(.internal),
        .keyword(.package):
        return modifier
      default:
        continue
      }
    }
    return nil
  }

  /// Returns true if the modifier list contains any of the keywords in the given set.
  func contains(anyOf keywords: Set<Keyword>) -> Bool {
    return contains {
      switch $0.name.tokenKind {
      case .keyword(let keyword): return keywords.contains(keyword)
      default: return false
      }
    }
  }

  /// Removes any of the modifiers in the given set from the modifier list, mutating it in-place.
  mutating func remove(anyOf keywords: Set<Keyword>) {
    self = filter {
      switch $0.name.tokenKind {
      case .keyword(let keyword): return !keywords.contains(keyword)
      default: return true
      }
    }
  }

  /// Returns a copy of the modifier list with any of the modifiers in the given set removed.
  func removing(anyOf keywords: Set<Keyword>) -> DeclModifierListSyntax {
    return filter {
      switch $0.name.tokenKind {
      case .keyword(let keyword): return !keywords.contains(keyword)
      default: return true
      }
    }
  }
}
