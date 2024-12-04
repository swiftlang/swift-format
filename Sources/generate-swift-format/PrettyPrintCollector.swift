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
@_spi(Rules) import SwiftFormat
import SwiftParser
import SwiftSyntax

/// Collects information about rules in the formatter code base.
final class PrettyPrintCollector {

  /// A list of all the format-only pretty-print categories found in the code base.
  var allPrettyPrinterCategories = Set<String>()

  /// Populates the internal collections with rules in the given directory.
  ///
  /// - Parameter url: The file system URL that should be scanned for rules.
  func collect(from url: URL) throws {
    // For each file in the Rules directory, find types that either conform to SyntaxLintRule or
    // inherit from SyntaxFormatRule.
    let fm = FileManager.default
    guard let rulesEnumerator = fm.enumerator(atPath: url.path) else {
      fatalError("Could not list the directory \(url.path)")
    }

    for baseName in rulesEnumerator {
      // Ignore files that aren't Swift source files.
      guard let baseName = baseName as? String, baseName.hasSuffix(".swift") else { continue }

      let fileURL = url.appendingPathComponent(baseName)
      let fileInput = try String(contentsOf: fileURL)
      let sourceFile = Parser.parse(source: fileInput)

      for statement in sourceFile.statements {
        let pp = self.detectPrettyPrintCategories(at: statement)
          allPrettyPrinterCategories.formUnion(pp)
      }
    }
  }

  private func detectPrettyPrintCategories(at statement: CodeBlockItemSyntax) -> [String] {
    guard let enumDecl = statement.item.as(EnumDeclSyntax.self) else {
      return []
    }

    if enumDecl.name.text == "PrettyPrintFindingCategory" {
      print("HIT")
    }

    // Make sure it has an inheritance clause.
    guard let inheritanceClause = enumDecl.inheritanceClause else {
      return []
    }

    // Scan through the inheritance clause to find one of the protocols/types we're interested in.
    for inheritance in inheritanceClause.inheritedTypes {
      guard let identifier = inheritance.type.as(IdentifierTypeSyntax.self) else {
        continue
      }

      if identifier.name.text != "FindingCategorizing" {
        // Keep looking at the other inheritances.
        continue
      }

      // Now that we know it's a pretty printing category, collect the `description` method and extract the name.
      for member in enumDecl.memberBlock.members {
        guard let varDecl = member.decl.as(VariableDeclSyntax.self) else { continue }
        guard let descriptionDecl = varDecl.bindings
          .first(where: {
            $0.pattern.as(IdentifierPatternSyntax.self)?.identifier.text == "description"
          }) else { continue }
        let pp = PrettyPrintCategoryVisitor(viewMode: .sourceAccurate)
        _ = pp.walk(descriptionDecl)
        return pp.prettyPrintCategories
      }
    }

    return []
  }
}

final class PrettyPrintCategoryVisitor: SyntaxVisitor {

  var prettyPrintCategories: [String] = []

  override func visit(_ node: StringSegmentSyntax) -> SyntaxVisitorContinueKind {
    prettyPrintCategories.append(node.content.text)
    return .skipChildren
  }
}
