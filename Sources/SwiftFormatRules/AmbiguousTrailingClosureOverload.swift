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

/// Overloads with only a closure argument should not be disambiguated by parameter labels.
///
/// Lint: If two overloaded functions with one closure parameter appear in the same scope, a lint
///       error is raised.
public final class AmbiguousTrailingClosureOverload: SyntaxLintRule {

  private func diagnoseBadOverloads(_ overloads: [String: [FunctionDeclSyntax]]) {
    for (_, decls) in overloads where decls.count > 1 {
      let decl = decls[0]
      diagnose(
        .ambiguousTrailingClosureOverload(decl.fullDeclName),
        on: decl.identifier,
        notes: decls.dropFirst().map { decl in
          Finding.Note(
            message: .otherAmbiguousOverloadHere(decl.fullDeclName),
            location: Finding.Location(
              decl.identifier.startLocation(converter: self.context.sourceLocationConverter))
          )
        })
    }
  }

  private func discoverAndDiagnoseOverloads(_ functions: [FunctionDeclSyntax]) {
    var overloads = [String: [FunctionDeclSyntax]]()
    var staticOverloads = [String: [FunctionDeclSyntax]]()
    for fn in functions {
      let params = fn.signature.input.parameterList
      guard let firstParam = params.firstAndOnly else { continue }
      guard let type = firstParam.type, type.is(FunctionTypeSyntax.self) else { continue }
      if let mods = fn.modifiers, mods.has(modifier: "static") || mods.has(modifier: "class") {
        staticOverloads[fn.identifier.text, default: []].append(fn)
      } else {
        overloads[fn.identifier.text, default: []].append(fn)
      }
    }

    diagnoseBadOverloads(overloads)
    diagnoseBadOverloads(staticOverloads)
  }

  public override func visit(_ node: SourceFileSyntax) -> SyntaxVisitorContinueKind {
    let functions = node.statements.compactMap { $0.item.as(FunctionDeclSyntax.self) }
    discoverAndDiagnoseOverloads(functions)
    return .visitChildren
  }

  public override func visit(_ node: CodeBlockSyntax) -> SyntaxVisitorContinueKind {
    let functions = node.statements.compactMap { $0.item.as(FunctionDeclSyntax.self) }
    discoverAndDiagnoseOverloads(functions)
    return .visitChildren
  }

  public override func visit(_ decls: MemberDeclBlockSyntax) -> SyntaxVisitorContinueKind {
    let functions = decls.members.compactMap { $0.decl.as(FunctionDeclSyntax.self) }
    discoverAndDiagnoseOverloads(functions)
    return .visitChildren
  }
}

extension Finding.Message {
  public static func ambiguousTrailingClosureOverload(_ decl: String) -> Finding.Message {
    "rename '\(decl)' so it is no longer ambiguous with a trailing closure"
  }

  public static func otherAmbiguousOverloadHere(_ decl: String) -> Finding.Message {
    "ambiguous overload '\(decl)' is here"
  }
}
