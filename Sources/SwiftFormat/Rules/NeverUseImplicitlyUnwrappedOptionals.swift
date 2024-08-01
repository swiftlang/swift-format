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

import SwiftSyntax

/// Implicitly unwrapped optionals (e.g. `var s: String!`) are forbidden.
///
/// Certain properties (e.g. `@IBOutlet`) tied to the UI lifecycle are ignored.
///
/// This rule does not apply to test code, defined as code which:
///   * Contains the line `import XCTest`
///   * The function is marked with `@Test` attribute
///
/// TODO: Create exceptions for other UI elements (ex: viewDidLoad)
///
/// Lint: Declaring a property with an implicitly unwrapped type yields a lint error.
@_spi(Rules)
public final class NeverUseImplicitlyUnwrappedOptionals: SyntaxLintRule {

  /// Identifies this rule as being opt-in. While accessing implicitly unwrapped optionals is an
  /// unsafe pattern (i.e. it can crash), there are valid contexts for using implicitly unwrapped
  /// optionals where it won't crash. This rule can't evaluate the context around the usage to make
  /// that determination.
  public override class var isOptIn: Bool { return true }

  // Checks if "XCTest" is an import statement
  public override func visit(_ node: SourceFileSyntax) -> SyntaxVisitorContinueKind {
    setImportsXCTest(context: context, sourceFile: node)
    return .visitChildren
  }

  public override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
    guard context.importsXCTest == .doesNotImportXCTest else { return .skipChildren }
    // Allow implicitly unwrapping if it is in a function marked with @Test attribute.
    if node.hasTestAncestor { return .skipChildren }
    // Ignores IBOutlet variables
    for attribute in node.attributes {
      if (attribute.as(AttributeSyntax.self))?.attributeName.as(IdentifierTypeSyntax.self)?.name.text == "IBOutlet" {
        return .skipChildren
      }
    }
    // Finds type annotation for variable(s)
    for binding in node.bindings {
      guard let nodeTypeAnnotation = binding.typeAnnotation else { continue }
      diagnoseImplicitWrapViolation(nodeTypeAnnotation.type)
    }
    return .skipChildren
  }

  private func diagnoseImplicitWrapViolation(_ type: TypeSyntax) {
    guard let violation = type.as(ImplicitlyUnwrappedOptionalTypeSyntax.self) else { return }
    diagnose(
      .doNotUseImplicitUnwrapping(identifier: violation.wrappedType.trimmedDescription), on: type)
  }
}

extension Finding.Message {
  fileprivate static func doNotUseImplicitUnwrapping(identifier: String) -> Finding.Message {
    "use '\(identifier)' or '\(identifier)?' instead of '\(identifier)!'"
  }
}
