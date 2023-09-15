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

/// Playground literals (e.g. `#colorLiteral`) are forbidden.
///
/// For the case of `#colorLiteral`, if `import AppKit` is present, `NSColor` will be used.
/// If `import UIKit` is present, `UIColor` will be used.
/// If neither `import` is present, `resolveAmbiguousColor` will be used to determine behavior.
///
/// Lint: Using a playground literal will yield a lint error.
///
/// Format: The playground literal will be replaced with the matching class; e.g.
///         `#colorLiteral(...)` becomes `UIColor(...)`
///
/// Configuration: resolveAmbiguousColor
public final class NoPlaygroundLiterals: SyntaxFormatRule {

}
