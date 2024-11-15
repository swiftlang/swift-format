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
final class RuleCollector {
  /// Information about a detected rule.
  struct DetectedRule: Hashable {
    /// The type name of the rule.
    let typeName: String

    /// The description of the rule, extracted from the rule class or struct DocC comment
    /// with `DocumentationCommentText(extractedFrom:)`
    let description: String?

    /// The syntax node types visited by the rule type.
    let visitedNodes: [String]

    /// Indicates whether the rule can format code (all rules can lint).
    let canFormat: Bool

    /// Indicates whether the rule is disabled by default, i.e. requires opting in to use it.
    let isOptIn: Bool
  }

  /// A list of all rules that can lint (thus also including format rules) found in the code base.
  var allLinters = Set<DetectedRule>()

  /// A list of all the format-only rules found in the code base.
  var allFormatters = Set<DetectedRule>()

  /// A dictionary mapping syntax node types to the lint/format rules that visit them.
  var syntaxNodeLinters = [String: [String]]()

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
        guard let detectedRule = self.detectedRule(at: statement) else { continue }

        if detectedRule.canFormat {
          // Format rules just get added to their own list; we run them each over the entire tree in
          // succession.
          allFormatters.insert(detectedRule)
        }

        // Lint rules (this includes format rules, which can also lint) get added to a mapping over
        // the names of the types they touch so that they can be interleaved into one pass over the
        // tree.
        allLinters.insert(detectedRule)
        for visitedNode in detectedRule.visitedNodes {
          syntaxNodeLinters[visitedNode, default: []].append(detectedRule.typeName)
        }
      }
    }
  }

  /// Determine the rule kind for the declaration in the given statement, if any.
  private func detectedRule(at statement: CodeBlockItemSyntax) -> DetectedRule? {
    let typeName: String
    let members: MemberBlockItemListSyntax
    let maybeInheritanceClause: InheritanceClauseSyntax?
    let description = DocumentationCommentText(extractedFrom: statement.item.leadingTrivia)

    if let classDecl = statement.item.as(ClassDeclSyntax.self) {
      typeName = classDecl.name.text
      members = classDecl.memberBlock.members
      maybeInheritanceClause = classDecl.inheritanceClause
    } else if let structDecl = statement.item.as(StructDeclSyntax.self) {
      typeName = structDecl.name.text
      members = structDecl.memberBlock.members
      maybeInheritanceClause = structDecl.inheritanceClause
    } else {
      return nil
    }

    // Make sure it has an inheritance clause.
    guard let inheritanceClause = maybeInheritanceClause else {
      return nil
    }

    // Scan through the inheritance clause to find one of the protocols/types we're interested in.
    for inheritance in inheritanceClause.inheritedTypes {
      guard let identifier = inheritance.type.as(IdentifierTypeSyntax.self) else {
        continue
      }

      let canFormat: Bool
      switch identifier.name.text {
      case "SyntaxLintRule":
        canFormat = false
      case "SyntaxFormatRule":
        canFormat = true
      default:
        // Keep looking at the other inheritances.
        continue
      }

      // Now that we know it's a format or lint rule, collect the `visit` methods.
      var visitedNodes = [String]()
      for member in members {
        guard let function = member.decl.as(FunctionDeclSyntax.self) else { continue }
        guard function.name.text == "visit" else { continue }
        let params = function.signature.parameterClause.parameters
        guard let firstType = params.firstAndOnly?.type.as(IdentifierTypeSyntax.self) else {
          continue
        }
        visitedNodes.append(firstType.name.text)
      }

      /// Ignore it if it doesn't have any; there's no point in putting no-op rules in the pipeline.
      /// Otherwise, return it (we don't need to look at the rest of the inheritances).
      guard !visitedNodes.isEmpty else { return nil }
      guard let ruleType = _typeByName("SwiftFormat.\(typeName)") as? Rule.Type else {
        preconditionFailure("Failed to find type for rule named \(typeName)")
      }
      return DetectedRule(
        typeName: typeName,
        description: description?.text,
        visitedNodes: visitedNodes,
        canFormat: canFormat,
        isOptIn: ruleType.isOptIn
      )
    }

    return nil
  }
}
