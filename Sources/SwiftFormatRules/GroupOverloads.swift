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

import Foundation
import SwiftFormatCore
import SwiftSyntax

/// Overloads, subscripts, and initializers should be grouped if they appear in the same scope.
///
/// Lint: If an overload appears ungrouped with another member of the overload set, a lint error
///       will be raised.
///
/// Format: Overloaded declarations will be grouped together.
///
/// - SeeAlso: https://google.github.io/swift#overloaded-declarations
public final class GroupOverloads: SyntaxFormatRule {

}
