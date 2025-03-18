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

/// Generates the rule registry file used to populate the default configuration.
final class RuleRegistryGenerator: FileGenerator {

  /// The rules collected by scanning the formatter source code.
  let ruleCollector: RuleCollector

  /// The pretty-printing categories collected by scanning the formatter source code.
  let prettyPrintCollector: PrettyPrintCollector

  /// Creates a new rule registry generator.
  init(ruleCollector: RuleCollector, prettyPrintCollector: PrettyPrintCollector) {
    self.ruleCollector = ruleCollector
    self.prettyPrintCollector = prettyPrintCollector
  }

  func write(into handle: FileHandle) throws {
    handle.write(
      """
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

      // This file is automatically generated with generate-swift-format. Do not edit!

      @_spi(Internal) public enum RuleRegistry {
        public static let rules: [String: Bool] = [

      """
    )

    for detectedRule in ruleCollector.allLinters.sorted(by: { $0.typeName < $1.typeName }) {
      handle.write("    \"\(detectedRule.typeName)\": \(!detectedRule.isOptIn),\n")
    }

    for ppCategory in prettyPrintCollector.allPrettyPrinterCategories.sorted(by: { $0 < $1 }) {
      handle.write("    \"\(ppCategory)\": true,\n")
    }
    handle.write("  ]\n}\n")
  }
}
