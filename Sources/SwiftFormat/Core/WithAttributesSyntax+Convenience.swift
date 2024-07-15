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
    /// Indicates whether the node has attribute with the given `name`.
    ///
    /// - Parameter name: The name of the attribute to lookup.
    /// - Returns: True if the node has an attribute with the given `name`, otherwise false.
    func hasAttribute(_ name: String) -> Bool {
        attributes.contains { attribute in
            let attributeName = attribute.as(AttributeSyntax.self)?.attributeName
            return attributeName?.as(IdentifierTypeSyntax.self)?.name.text == name
            // support @Module.Attribute syntax as well
            || attributeName?.as(MemberTypeSyntax.self)?.name.text == name
        }
    }
}
