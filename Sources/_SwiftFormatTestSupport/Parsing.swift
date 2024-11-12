//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2024 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

@_spi(ExperimentalLanguageFeatures) import SwiftParser
import SwiftSyntax
import XCTest

extension Parser {
  /// Parses the given source string and returns the corresponding `SourceFileSyntax` node.
  ///
  /// - Parameters:
  ///   - source: The source text to parse.
  ///   - experimentalFeatures: The set of experimental features that should be enabled in the
  ///     parser.
  @_spi(Testing)
  public static func parse(
    source: String,
    experimentalFeatures: Parser.ExperimentalFeatures
  ) -> SourceFileSyntax {
    var source = source
    return source.withUTF8 { sourceBytes in
      parse(
        source: sourceBytes,
        experimentalFeatures: experimentalFeatures
      )
    }
  }
}
