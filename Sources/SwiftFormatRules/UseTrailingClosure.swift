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

/// Trailing closures are preferred wherever possible, except if a function has multiple closure
/// arguments.
///
/// Lint: TODO(abl): Figure out a consistent set of linting rules for this. The problem is it's not
///                  always safe to recommend foo({ $0 }) -> foo { $0 }, in the case where foo has
///                  default arguments after the closure parameter.
///
/// Format: TODO(abl): Figure out a consistent set of linting rules for formatting (see above)
///
/// - SeeAlso: https://google.github.io/swift#trailing-closures
public final class UseTrailingClosure: SyntaxFormatRule {

}
