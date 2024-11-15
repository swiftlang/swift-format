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

extension WithAttributesSyntax {
  /// Indicates whether the node has attribute with the given `name` and `module`.
  /// The `module` is only considered if the attribute is written as `@Module.Attribute`.
  ///
  /// - Parameter name: The name of the attribute to lookup.
  /// - Parameter module: The module name to lookup the attribute in.
  /// - Returns: True if the node has an attribute with the given `name`, otherwise false.
  func hasAttribute(_ name: String, inModule module: String) -> Bool {
    attributes.contains { attribute in
      let attributeName = attribute.as(AttributeSyntax.self)?.attributeName
      if let identifier = attributeName?.as(IdentifierTypeSyntax.self) {
        // @Attribute syntax
        return identifier.name.text == name
      }
      if let memberType = attributeName?.as(MemberTypeSyntax.self) {
        // @Module.Attribute syntax
        return memberType.name.text == name
          && memberType.baseType.as(IdentifierTypeSyntax.self)?.name.text == module
      }
      return false
    }
  }
}
