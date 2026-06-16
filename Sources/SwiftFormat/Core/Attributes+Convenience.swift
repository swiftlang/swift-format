//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import SwiftSyntax

extension WithAttributesSyntax {
  /// Indicates whether the node has attribute with the given `name` and `module`.
  /// The `module` is only considered if the attribute is written as `@Module.Attribute`.
  ///
  /// - Parameter name: The name of the attribute to lookup.
  /// - Parameter module: The module name to lookup the attribute in.
  /// - Returns: True if the node has an attribute with the given `name`, otherwise false.
  func hasAttribute(_ name: String, inModule module: String) -> Bool {
    attributes.contains { attribute in
      guard let attributeSyntax = attribute.as(AttributeSyntax.self) else { return false }
      return attributeSyntax.isAttribute(named: name, inModule: module)
    }
  }
}

extension AttributeSyntax {
  /// Returns true if the attribute has the given name and module.
  /// The `module` is only considered if the attribute is written as `@Module.Attribute`.
  func isAttribute(named name: String, inModule module: String) -> Bool {
    let attributeName = self.attributeName
    if let identifier = attributeName.as(IdentifierTypeSyntax.self) {
      return identifier.name.text == name
    }
    if let memberType = attributeName.as(MemberTypeSyntax.self) {
      return memberType.name.text == name
        && memberType.baseType.as(IdentifierTypeSyntax.self)?.name.text == module
    }
    return false
  }

  /// Returns true if the attribute has no arguments or empty arguments list.
  var isEmpty: Bool {
    guard let arguments = self.arguments else {
      return true
    }
    switch arguments {
    case .argumentList(let list):
      return list.isEmpty
    default:
      return false
    }
  }
}
