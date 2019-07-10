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

/// Parameterized attributes must be written on individual lines, ordered lexicographically.
///
/// Lint: Parameterized attributes not on an individual line will yield a lint error.
///       Parameterized attributes not in lexicographic order will yield a lint error.
///
/// Format: Parameterized attributes will be placed on individual lines in lexicographic order.
///
/// - SeeAlso: https://google.github.io/swift#attributes
public final class ParameterizedAttributesOnNewLines: SyntaxFormatRule {

}
