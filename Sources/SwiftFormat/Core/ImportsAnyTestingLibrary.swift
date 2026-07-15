//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import SwiftSyntax

@_spi(Testing)
public let supportedTestLibraryModuleNames = [
  "XCTest",
  "Testing",
]

/// Sets the appropriate value of the `importsAnyTestLibrary` field in the context, which
/// approximates whether the file contains test code or not.
///
/// This setter will only run the visitor if another rule hasn't already called this function to
/// determine if the source file imports a supported test library.
///
/// - Parameters:
///   - context: The context information of the target source file.
///   - sourceFile: The file to be visited.
@_spi(Testing)
public func setImportsAnyTestLibrary(context: Context, sourceFile: SourceFileSyntax) {
  if statementsImportAnyTestLibrary(sourceFile.statements) {
    context.importsAnyTestLibrary = .importsATestLirary
  } else {
    context.importsAnyTestLibrary = .doesNotImportATestLibrary
  }
}

@_spi(Testing)
public func statementsImportAnyTestLibrary(_ statements: CodeBlockItemListSyntax) -> Bool {
  for codeBlockItem in statements {
    switch codeBlockItem.item {
    case .decl(let decl):
      switch Syntax(decl).as(SyntaxEnum.self) {
      case .importDecl(let importDecl):
        if supportedTestLibraryModuleNames.contains(where: { importDecl.path.first!.name.tokenKind == .identifier($0) })
        {
          return true
        }
      case .ifConfigDecl(let ifConfigDecl):
        for clause in ifConfigDecl.clauses {
          guard let nestedStatements = clause.elements?.as(CodeBlockItemListSyntax.self) else {
            continue
          }
          if statementsImportAnyTestLibrary(nestedStatements) {
            return true
          }
        }
      default:
        break
      }
    default:
      break
    }
  }
  return false
}

@_spi(Testing)
@available(*, deprecated, message: "use `setImportsAnyTestLibrary(context:sourceFile:)` instead")
public func setImportsXCTest(context: Context, sourceFile: SourceFileSyntax) {
  return setImportsAnyTestLibrary(context: context, sourceFile: sourceFile)
}
