//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2023 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import SwiftFormat

extension Configuration {
  /// The default configuration to be used during unit tests.
  ///
  /// This configuration is separate from `Configuration.init()` so that that configuration can be
  /// replaced without breaking tests that implicitly rely on it. Unfortunately, since this is in a
  /// different module than where `Configuration` is defined, we can't make this an initializer that
  /// would enforce that every field of `Configuration` is initialized here (we're forced to
  /// delegate to another initializer first, which defeats the purpose). So, users adding new
  /// configuration settings should be sure to supply a default here for testing, otherwise they
  /// will be implicitly relying on the real default.
  public static var forTesting: Configuration {
    var config = Configuration()
    config.rules = Configuration.defaultRuleEnablements
    config.maximumBlankLines = 1
    config.lineLength = 100
    config.tabWidth = 8
    config.indentation = .spaces(2)
    config.respectsExistingLineBreaks = true
    config.lineBreakBeforeControlFlowKeywords = false
    config.lineBreakBeforeEachArgument = false
    config.lineBreakBeforeEachGenericRequirement = false
    config.prioritizeKeepingFunctionOutputTogether = false
    config.indentConditionalCompilationBlocks = true
    config.lineBreakAroundMultilineExpressionChainComponents = false
    config.fileScopedDeclarationPrivacy = FileScopedDeclarationPrivacyConfiguration()
    config.indentSwitchCaseLabels = false
    config.spacesAroundRangeFormationOperators = false
    config.noAssignmentInExpressions = NoAssignmentInExpressionsConfiguration()
    config.multiElementCollectionTrailingCommas = true
    config.indentBlankLines = false
    return config
  }
}
