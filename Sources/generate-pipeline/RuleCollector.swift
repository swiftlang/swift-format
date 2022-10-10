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
import SwiftSyntax
import SwiftParser

/// Collects information about rules in the formatter code base.
final class RuleCollector {
  enum Error: Swift.Error, CustomStringConvertible {
    /// Indicates that an `isOptIn` property was found when scanning a rule, but the property was
    /// not defined correctly.
    case invalidOptIn(ruleName: String)

    var description: String {
      switch self {
      case .invalidOptIn(let ruleName):
        return """
          The 'isOptIn' property on the rule '\(ruleName)' was defined incorrectly. It must be a \
          computed static or class property with a single statement or expression that returns \
          'true' or 'false'.
          """
      }
    }
  }

  /// Information about a detected rule.
  struct DetectedRule: Hashable {
    /// The type name of the rule.
    let typeName: String

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
      let sourceFile = try Parser.parse(source: fileInput)

      for statement in sourceFile.statements {
        guard let detectedRule = try self.detectedRule(at: statement) else { continue }

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
  private func detectedRule(at statement: CodeBlockItemSyntax) throws -> DetectedRule? {
    let typeName: String
    let members: MemberDeclListSyntax
    let maybeInheritanceClause: TypeInheritanceClauseSyntax?

    if let classDecl = statement.item.as(ClassDeclSyntax.self) {
      typeName = classDecl.identifier.text
      members = classDecl.members.members
      maybeInheritanceClause = classDecl.inheritanceClause
    } else if let structDecl = statement.item.as(StructDeclSyntax.self) {
      typeName = structDecl.identifier.text
      members = structDecl.members.members
      maybeInheritanceClause = structDecl.inheritanceClause
    } else {
      return nil
    }

    // Make sure it has an inheritance clause.
    guard let inheritanceClause = maybeInheritanceClause else {
      return nil
    }

    // Scan through the inheritance clause to find one of the protocols/types we're interested in.
    for inheritance in inheritanceClause.inheritedTypeCollection {
      guard let identifier = inheritance.typeName.as(SimpleTypeIdentifierSyntax.self) else {
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
        guard function.identifier.text == "visit" else { continue }
        let params = function.signature.input.parameterList
        guard let firstType = params.firstAndOnly?.type?.as(SimpleTypeIdentifierSyntax.self) else {
          continue
        }
        visitedNodes.append(firstType.name.text)
      }

      // Ignore it if it doesn't have any; there's no point in putting no-op rules in the pipeline.
      // Otherwise, return it (we don't need to look at the rest of the inheritances).
      guard !visitedNodes.isEmpty else { return nil }

      // Determine if the rule is opt-in. The `isOptIn` property must be a computed property with a
      // simple statement returning `true` or `false`.
      guard let isOptIn = isRuleOptIn(members: members) else {
        throw Error.invalidOptIn(ruleName: typeName)
      }
      return DetectedRule(
        typeName: typeName, visitedNodes: visitedNodes, canFormat: canFormat,
        isOptIn: isOptIn)
    }

    return nil
  }

  /// Searches for a static/class property named `isOptIn` and returns its simple Boolean return
  /// value, if possible.
  ///
  /// Returns `false` if no `isOptIn` property was found, or `nil` if a property was found but we
  /// were unable to determine its simple Boolean return value.
  private func isRuleOptIn(members: MemberDeclListSyntax) -> Bool? {
    for member in members {
      guard let varDecl = member.decl.as(VariableDeclSyntax.self) else { continue }
      for binding in varDecl.bindings {
        guard
          let identifier = binding.pattern.as(IdentifierPatternSyntax.self),
          identifier.identifier.text == "isOptIn"
        else {
          continue
        }

        // Make sure that we've found a static/class property with a getter that returns a Boolean
        // literal. Otherwise, return nil to indicate that the property found was invalid (and thus
        // likely a programmer error).
        guard
          varDecl.modifiers?.contains(where: isStaticOrClassModifier) == true,
          let getterBlock = computedGetter(for: binding),
          let returnValue = booleanReturnValue(for: getterBlock)
        else {
          return nil
        }

        return returnValue
      }
    }

    // If we didn't find an `isOptIn` property, return the default (false).
    return false
  }

  /// Returns the computed property getter for the given pattern binding, or `nil` if no getter was
  /// found.
  private func computedGetter(for binding: PatternBindingSyntax) -> CodeBlockSyntax? {
    guard let accessor = binding.accessor else { return nil }

    if let implicitGetBlock = accessor.as(CodeBlockSyntax.self) {
      // If the accessor was just a code block, then it's the implicit getter.
      return implicitGetBlock
    }

    if let accessorBlock = accessor.as(AccessorBlockSyntax.self) {
      // If we have a list of accessors, find the getter by searching the list.
      for childAccessor in accessorBlock.accessors {
        if childAccessor.accessorKind.tokenKind == .contextualKeyword("get"),
          let getBlock = childAccessor.body
        {
          return getBlock
        }
      }
      return nil
    }

    return nil
  }

  /// Returns the simple Boolean literal return value of the given code block, or `nil` if it was
  /// not possible to determine (for example, the code block had multiple statements or returned
  /// something other than a Boolean literal).
  private func booleanReturnValue(for codeBlock: CodeBlockSyntax) -> Bool? {
    guard let statement = codeBlock.statements.firstAndOnly else { return nil }

    if let returnStatement = statement.item.as(ReturnStmtSyntax.self) {
      // If it's a `return` statement, check for a Boolean literal value.
      if let booleanExpr = returnStatement.expression?.as(BooleanLiteralExprSyntax.self) {
        return booleanExpr.booleanLiteral.tokenKind == .trueKeyword
      }

      return nil
    }

    if let booleanExpr = statement.item.as(BooleanLiteralExprSyntax.self) {
      // It's a Boolean literal expression with implicit return.
      return booleanExpr.booleanLiteral.tokenKind == .trueKeyword
    }

    return nil
  }

  /// Returns a value indicating whether the given modifier is the `static` or `class` keyword.
  private func isStaticOrClassModifier(_ modifier: DeclModifierSyntax) -> Bool {
    let kind = modifier.name.tokenKind
    return kind == .staticKeyword || kind == .classKeyword
  }
}
