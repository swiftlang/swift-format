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

import SwiftFormatCore
import SwiftSyntax

/// All values should be written in lower camel-case (`lowerCamelCase`).
/// Underscores (except at the beginning of an identifier) are disallowed.
///
/// Lint: If an identifier contains underscores or begins with a capital letter, a lint error is
///       raised.
public final class AlwaysUseLowerCamelCase: SyntaxLintRule {
  /// Stores function decls that are test cases.
  private var testCaseFuncs = Set<FunctionDeclSyntax>()

  public override func visit(_ node: SourceFileSyntax) -> SyntaxVisitorContinueKind {
    // Tracks whether "XCTest" is imported in the source file before processing individual nodes.
    setImportsXCTest(context: context, sourceFile: node)
    return .visitChildren
  }

  public override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
    // Check if this class is an `XCTestCase`, otherwise it cannot contain any test cases.
    guard context.importsXCTest == .importsXCTest else { return .visitChildren }

    // Identify and store all of the function decls that are test cases.
    let testCases = node.members.members.compactMap {
      $0.decl.as(FunctionDeclSyntax.self)
    }.filter {
      // Filter out non-test methods using the same heuristics as XCTest to identify tests.
      // Test methods are methods that start with "test", have no arguments, and void return type.
      $0.identifier.text.starts(with: "test")
        && $0.signature.input.parameterList.isEmpty
        && $0.signature.output.map { $0.isVoid } ?? true
    }
    testCaseFuncs.formUnion(testCases)
    return .visitChildren
  }

  public override func visitPost(_ node: ClassDeclSyntax) {
    testCaseFuncs.removeAll()
  }

  public override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
    for binding in node.bindings {
      guard let pat = binding.pattern.as(IdentifierPatternSyntax.self) else {
        continue
      }
      diagnoseLowerCamelCaseViolations(pat.identifier, allowUnderscores: false)
    }
    return .skipChildren
  }

  public override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
    // We allow underscores in test names, because there's an existing convention of using
    // underscores to separate phrases in very detailed test names.
    let allowUnderscores = testCaseFuncs.contains(node)
    diagnoseLowerCamelCaseViolations(node.identifier, allowUnderscores: allowUnderscores)
    return .skipChildren
  }

  public override func visit(_ node: EnumCaseElementSyntax) -> SyntaxVisitorContinueKind {
    diagnoseLowerCamelCaseViolations(node.identifier, allowUnderscores: false)
    return .skipChildren
  }

  private func diagnoseLowerCamelCaseViolations(_ identifier: TokenSyntax, allowUnderscores: Bool) {
    guard case .identifier(let text) = identifier.tokenKind else { return }
    if text.isEmpty { return }
    if (text.dropFirst().contains("_") && !allowUnderscores) || ("A"..."Z").contains(text.first!) {
      diagnose(.variableNameMustBeLowerCamelCase(text), on: identifier) {
        $0.highlight(identifier.sourceRange(converter: self.context.sourceLocationConverter))
      }
    }
  }
}

extension ReturnClauseSyntax {
  /// Whether this return clause specifies an explicit `Void` return type.
  fileprivate var isVoid: Bool {
    if let returnTypeIdentifier = returnType.as(SimpleTypeIdentifierSyntax.self) {
      return returnTypeIdentifier.name.text == "Void"
    }
    if let returnTypeTuple = returnType.as(TupleTypeSyntax.self) {
      return returnTypeTuple.elements.isEmpty
    }
    return false
  }
}

extension Diagnostic.Message {
  public static func variableNameMustBeLowerCamelCase(_ name: String) -> Diagnostic.Message {
    return .init(.warning, "rename variable '\(name)' using lower-camel-case")
  }
}
